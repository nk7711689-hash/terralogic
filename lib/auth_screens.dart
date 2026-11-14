import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/language_controller.dart';
import 'core/notification_service.dart';
import 'core/terra_theme.dart';
import 'main.dart';
import 'signup_screen.dart';
import 'features/ai_plant_doctor/presentation/screens/plant_doctor_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      if (Firebase.apps.isEmpty) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PlantDoctorScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TerraTheme.mist,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.jpg', width: 110, height: 110),
            const SizedBox(height: 20),
            const Text(
              'TerraLogic',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'منظومة إدارة وتشخيص المزارع الذكية',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _farmCodeController = TextEditingController(); // كود المدير أو العامل
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _farmCodeController.dispose();
    super.dispose();
  }

  // تسجيل الدخول برقم الهاتف
  Future<void> _login(bool isArabic) async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    final farmCodeInput = _farmCodeController.text.trim().toUpperCase();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'الرجاء إدخال رقم الهاتف أو البريد وكلمة المرور'
                : 'Please enter your phone or email and password',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var resolvedEmail = identifier;
      if (!identifier.contains('@')) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: identifier)
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Phone number is not registered.',
          );
        }
        resolvedEmail = query.docs.first.data()['email']?.toString() ?? '';
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: resolvedEmail, password: password);

      final user = userCredential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          throw FirebaseAuthException(
            code: 'profile-not-found',
            message: 'User profile was not found.',
          );
        }

        final uData = userDoc.data() ?? <String, dynamic>{};
        DocumentSnapshot<Map<String, dynamic>>? selectedFarm;
        var selectedRole = 'manager';

        if (farmCodeInput.isNotEmpty) {
          final farmQuery = await FirebaseFirestore.instance
              .collection('farms')
              .where('admin_key', isEqualTo: farmCodeInput)
              .limit(1)
              .get();
          if (farmQuery.docs.isNotEmpty) {
            selectedFarm = farmQuery.docs.first;
          } else {
            final workerQuery = await FirebaseFirestore.instance
                .collection('farms')
                .where('worker_code', isEqualTo: farmCodeInput)
                .limit(1)
                .get();
            if (workerQuery.docs.isNotEmpty) {
              selectedFarm = workerQuery.docs.first;
              selectedRole = 'worker';
            } else {
              final farmById = await FirebaseFirestore.instance
                  .collection('farms')
                  .doc(farmCodeInput)
                  .get();
              if (farmById.exists) {
                selectedFarm = farmById;
                selectedRole = 'worker';
              }
            }
          }

          if (selectedFarm == null) {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isArabic
                        ? 'الكود غير صحيح. استخدم كود المدراء أو كود المزرعة/العمال.'
                        : 'Invalid code. Use the admin or farm/worker code.',
                  ),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
            return;
          }

          final farmCode = selectedFarm.id;
          final farmData = selectedFarm.data() ?? <String, dynamic>{};
          final name = uData['name'] ?? 'مستخدم';
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'farm_code': farmCode,
                'farm_name': farmData['farm_name'] ?? '',
                'role': selectedRole,
              }, SetOptions(merge: true));
          await FirebaseFirestore.instance
              .collection('farm_members')
              .doc('${farmCode}_${user.uid}')
              .set({
                'farm_code': farmCode,
                'user_uid': user.uid,
                'role': selectedRole,
                'last_used_at': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
          if (selectedRole == 'worker') {
            await FirebaseFirestore.instance
                .collection('workers')
                .doc('${farmCode}_${user.uid}')
                .set({
                  'uid': user.uid,
                  'name': name,
                  'phone': uData['phone'] ?? '',
                  'role': 'worker',
                  'salary': 0,
                  'farm_code': farmCode,
                  'status': 'Active',
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
          }
          FarmNotificationService.notifyUserLogin(name, selectedRole, farmCode);
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'farm_code': FieldValue.delete(),
                'farm_name': FieldValue.delete(),
                'role': 'worker',
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = isArabic
          ? 'فشل تسجيل الدخول: ${e.message}'
          : 'Login failed: ${e.message}';
      if (e.code == 'user-not-found') {
        message = isArabic
            ? 'الحساب غير موجود، تأكد من رقم الهاتف'
            : 'User not found';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = isArabic
            ? 'كلمة المرور أو رقم الهاتف غير صحيح'
            : 'Wrong password or phone number';
      } else if (e.code == 'invalid-email') {
        message = isArabic
            ? 'صيغة البريد الإلكتروني غير صحيحة'
            : 'Invalid email format';
      } else if (e.code == 'network-request-failed') {
        message = isArabic
            ? 'تأكد من الاتصال بالإنترنت'
            : 'Check your internet connection';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'حدث خطأ غير متوقع: $e' : 'Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: TerraTheme.mist,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: isArabic ? 'رجوع' : 'Back',
                onPressed: () => Navigator.pop(context),
              ),
              actions: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: LanguageToggleButton(),
                ),
              ],
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // الشعار والعنوان
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/logo.jpg',
                            width: 80,
                            height: 80,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'TerraLogic',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'بوابتك الذكية لإدارة المزرعة وتشخيص المحاصيل'
                                : 'Smart Farm Management & Plant Diagnosis',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // بطاقة تسجيل الدخول
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isArabic ? 'تسجيل الدخول' : 'Sign In',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // حقل رقم الهاتف أو البريد الإلكتروني
                            TextField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: isArabic
                                    ? 'رقم الهاتف أو البريد الإلكتروني *'
                                    : 'Phone or email *',
                                hintText: '05xxxxxxxx أو name@example.com',
                                prefixIcon: const Icon(
                                  Icons.contact_phone_outlined,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // حقل كلمة المرور
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: isArabic
                                    ? 'كلمة المرور'
                                    : 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // كود المدير أو العامل
                            TextField(
                              controller: _farmCodeController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: isArabic
                                    ? 'كود المزرعة (اختياري)'
                                    : 'Farm code (optional)',
                                hintText: 'ADM-XXXX / FARM-XXXX',
                                prefixIcon: const Icon(
                                  Icons.vpn_key_outlined,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                ),
                                helperText: isArabic
                                    ? 'اتركه فارغاً للدخول إلى حسابك فقط'
                                    : 'Leave empty to sign in to your account only',
                              ),
                            ),
                            const SizedBox(height: 8),

                            // زر تسجيل الدخول
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _login(isArabic),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isArabic ? 'تسجيل الدخول' : 'Log in',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // خيارات إنشاء حساب جديد
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.add_business_rounded,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                      label: Text(
                        isArabic
                            ? 'ليس لديك حساب؟ إنشاء حساب'
                            : "Don't have an account? Create account",
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
