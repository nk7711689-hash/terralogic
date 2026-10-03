import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/language_controller.dart';
import 'core/notification_service.dart';
import 'main.dart';
import 'signup_screen.dart';

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
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
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
  final _identifierController = TextEditingController(); // البريد الإلكتروني أو اسم المستخدم
  final _passwordController = TextEditingController();
  final _farmCodeController = TextEditingController(); // كود المزرعة
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _farmCodeController.dispose();
    super.dispose();
  }

  // تسجيل الدخول بالبريد الإلكتروني أو اسم المستخدم
  Future<void> _login(bool isArabic) async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    final farmCodeInput = _farmCodeController.text.trim().toUpperCase();

    if (identifier.isEmpty || password.isEmpty || farmCodeInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'الرجاء إدخال اسم المستخدم/البريد وكلمة المرور وكود المزرعة' : 'Please enter your email/username, password and Farm Code',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String resolvedEmail = identifier;

      // فحص المدخل: إذا كان لا يحتوي على @ نعامله كاسم مستخدم
      if (!identifier.contains('@')) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: identifier.toLowerCase())
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          resolvedEmail = query.docs.first.data()['email'] ?? identifier;
        } else {
          // اسم المستخدم غير موجود
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'اسم المستخدم غير مسجل في النظام',
          );
        }
      }

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final uData = userDoc.data() as Map<String, dynamic>;
          final name = uData['name'] ?? 'مستخدم';
          final role = uData['role'] ?? 'worker';
          final farmCode = uData['farm_code'] ?? '';

          // التحقق من تطابق كود المزرعة
          if (farmCode.isNotEmpty && farmCode.toUpperCase() != farmCodeInput) {
            // تسجيل الخروج وإبلاغ المستخدم بخطأ الكود
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isArabic
                        ? 'كود المزرعة غير صحيح! تأكد من الكود الموجود لديك وحاول مجدداً'
                        : 'Invalid Farm Code! Please check the code provided by your farm owner and try again.',
                  ),
                  backgroundColor: Colors.red.shade700,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          if (farmCode.isNotEmpty) {
            FarmNotificationService.notifyUserLogin(name, role, farmCode);
          }
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = isArabic ? 'فشل تسجيل الدخول: ${e.message}' : 'Login failed: ${e.message}';
      if (e.code == 'user-not-found') {
        message = isArabic ? 'الحساب غير موجود، تأكد من اسم المستخدم أو البريد الإلكتروني' : 'User not found';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = isArabic ? 'كلمة المرور أو البريد غير صحيح' : 'Wrong password or identifier';
      } else if (e.code == 'invalid-email') {
        message = isArabic ? 'صيغة البريد الإلكتروني غير صحيحة' : 'Invalid email format';
      } else if (e.code == 'network-request-failed') {
        message = isArabic ? 'تأكد من الاتصال بالإنترنت' : 'Check your internet connection';
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
          SnackBar(content: Text(isArabic ? 'حدث خطأ غير متوقع: $e' : 'Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // استعادة كلمة المرور
  void _showForgotPasswordDialog(bool isArabic) {
    final identifierCtrl = TextEditingController(text: _identifierController.text);
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.lock_reset_rounded, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Text(isArabic ? 'استعادة كلمة المرور' : 'Reset Password', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'أدخل اسم المستخدم، البريد الإلكتروني، أو رقم الهاتف لإرسال رابط إعادة تعيين كلمة المرور:'
                      : 'Enter your username, email, or phone to receive reset instructions:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: identifierCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'اسم المستخدم / البريد / الهاتف' : 'Username / Email / Phone',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32), size: 20),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isResetting ? null : () => Navigator.pop(ctx),
                child: Text(isArabic ? 'إلغاء' : 'Cancel', style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                onPressed: isResetting ? null : () async {
                  final input = identifierCtrl.text.trim();
                  if (input.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isArabic ? 'الرجاء إدخال بيانات صالحة' : 'Please enter valid data'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  
                  setDialogState(() => isResetting = true);
                  
                  try {
                    String targetEmail = input;

                    // إذا لم يكن بريداً إلكترونياً، ابحث في Firestore عن اسم المستخدم أو رقم الهاتف
                    if (!input.contains('@')) {
                      final usersRef = FirebaseFirestore.instance.collection('users');
                      
                      // بحث باسم المستخدم
                      var query = await usersRef.where('username', isEqualTo: input.toLowerCase()).limit(1).get();
                      
                      // إذا لم يتم العثور عليه، جرب البحث برقم الهاتف
                      if (query.docs.isEmpty) {
                        query = await usersRef.where('phone', isEqualTo: input).limit(1).get();
                      }

                      if (query.docs.isNotEmpty) {
                        targetEmail = query.docs.first.data()['email'] ?? '';
                        if (targetEmail.isEmpty) {
                           throw Exception(isArabic ? 'لا يوجد بريد إلكتروني مرتبط بهذا الحساب' : 'No email associated with this account');
                        }
                      } else {
                        throw Exception(isArabic ? 'الحساب غير موجود' : 'Account not found');
                      }
                    }

                    await FirebaseAuth.instance.sendPasswordResetEmail(email: targetEmail);
                    
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isArabic ? 'تم إرسال رابط إعادة التعيين بنجاح ✅ يرجى تفقد صندوق الوارد والرسائل غير المرغوب فيها (Spam)' : 'Password reset link sent ✅ Please check your inbox and spam folders'),
                          backgroundColor: const Color(0xFF2E7D32),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    String message = e.message ?? 'Error';
                    if (e.code == 'user-not-found') {
                      message = isArabic ? 'الحساب غير موجود' : 'User not found';
                    } else if (e.code == 'invalid-email') {
                      message = isArabic ? 'صيغة البريد الإلكتروني غير صحيحة' : 'Invalid email format';
                    } else if (e.code == 'network-request-failed') {
                      message = isArabic ? 'تأكد من الاتصال بالإنترنت' : 'Check your internet connection';
                    }
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message), backgroundColor: Colors.red),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (ctx.mounted) {
                      setDialogState(() => isResetting = false);
                    }
                  }
                },
                child: isResetting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isArabic ? 'إرسال الرابط' : 'Send Link', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F9F7),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: LanguageToggleButton(),
                ),
              ],
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // الشعار والعنوان
                    Center(
                      child: Column(
                        children: [
                          Image.asset('assets/images/logo.jpg', width: 80, height: 80),
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
                            isArabic ? 'بوابتك الذكية لإدارة المزرعة وتشخيص المحاصيل' : 'Smart Farm Management & Plant Diagnosis',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            ),
                            const SizedBox(height: 16),

                            // حقل البريد أو اسم المستخدم
                            TextField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'البريد الإلكتروني أو اسم المستخدم' : 'Email or Username',
                                hintText: isArabic ? 'user@farm.com أو اسم_المستخدم' : 'user@farm.com or username',
                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2E7D32), size: 20),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // حقل كلمة المرور
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'كلمة المرور' : 'Password',
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32), size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // حقل كود المزرعة
                            TextField(
                              controller: _farmCodeController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'كود المزرعة *' : 'Farm Code *',
                                hintText: 'FARM-XXXX',
                                prefixIcon: const Icon(Icons.gite_outlined, color: Color(0xFF2E7D32), size: 20),
                                helperText: isArabic ? 'الكود الموجود لديك من مالك المزرعة' : 'Provided by your farm owner',
                              ),
                            ),
                            const SizedBox(height: 8),

                            // زر نسيت كلمة المرور
                            Align(
                              alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showForgotPasswordDialog(isArabic),
                                child: Text(
                                  isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                                  style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // زر تسجيل الدخول
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _login(isArabic),
                                child: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(
                                        isArabic ? 'دخول إلى المزرعة' : 'Login to Farm',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                        side: BorderSide(color: const Color(0xFF2E7D32).withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_business_rounded, color: Color(0xFF2E7D32), size: 20),
                      label: Text(
                        isArabic ? 'تأسيس مزرعة جديدة أو انضمام بكود' : 'Register New Farm or Join with Code',
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // الدخول كزائر
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                          );
                        },
                        icon: const Icon(Icons.explore_outlined, color: Colors.grey, size: 18),
                        label: Text(
                          isArabic ? 'الدخول السريع كزائر / تجربة' : 'Explore as Guest / Demo Mode',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
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