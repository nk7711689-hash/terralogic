import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terralogic/core/language_controller.dart';
import 'package:terralogic/core/notification_service.dart';
import 'package:terralogic/core/terra_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // حقول إنشاء مزرعة جديدة
  final _createNameCtrl = TextEditingController();
  final _createUsernameCtrl = TextEditingController();
  final _createFarmNameCtrl = TextEditingController();
  final _createEmailCtrl = TextEditingController();
  final _createPhoneCtrl = TextEditingController();
  final _createPassCtrl = TextEditingController();

  // حقول الانضمام لمزرعة
  final _joinNameCtrl = TextEditingController();
  final _joinUsernameCtrl = TextEditingController();
  final _joinEmailCtrl = TextEditingController();
  final _joinPhoneCtrl = TextEditingController();
  final _joinPassCtrl = TextEditingController();
  final _joinFarmCodeCtrl = TextEditingController();
  final _joinAdminKeyCtrl = TextEditingController();
  final _joinWorkerInviteCtrl = TextEditingController();

  String _selectedJoinRole = 'worker'; // 'worker' or 'manager'
  bool _isLoading = false;
  bool _obscureCreatePass = true;
  bool _obscureJoinPass = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createNameCtrl.dispose();
    _createUsernameCtrl.dispose();
    _createFarmNameCtrl.dispose();
    _createEmailCtrl.dispose();
    _createPhoneCtrl.dispose();
    _createPassCtrl.dispose();
    _joinNameCtrl.dispose();
    _joinUsernameCtrl.dispose();
    _joinEmailCtrl.dispose();
    _joinPhoneCtrl.dispose();
    _joinPassCtrl.dispose();
    _joinFarmCodeCtrl.dispose();
    _joinAdminKeyCtrl.dispose();
    _joinWorkerInviteCtrl.dispose();
    super.dispose();
  }

  // توليد كود عشوائي فريد ومميز
  String _generateUniqueCode(String prefix) {
    final rand = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final randomStr = List.generate(4, (index) => chars[rand.nextInt(chars.length)]).join();
    return '$prefix-$randomStr';
  }

  void _copyToClipboard(String text, String label, bool isAr) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تم نسخ $label إلى الحافظة بنجاح ✅' : '$label copied to clipboard ✅'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 1. إنشاء مزرعة جديدة (مالك / مدير عام)
  // التحقق من صحة اسم المستخدم
  String? _validateUsername(String username, bool isAr) {
    if (username.isEmpty) {
      return isAr ? 'اسم المستخدم مطلوب' : 'Username is required';
    }
    if (username.length < 3) {
      return isAr ? 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل' : 'Username must be at least 3 characters';
    }
    if (username.length > 20) {
      return isAr ? 'اسم المستخدم يجب أن لا يتجاوز 20 حرفاً' : 'Username must not exceed 20 characters';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    if (!usernameRegex.hasMatch(username)) {
      return isAr
          ? 'اسم المستخدم يجب أن يبدأ بحرف إنجليزي ويحتوي على أحرف وأرقام وشرطة سفلية فقط'
          : 'Username must start with a letter and contain only letters, numbers, and underscores';
    }
    return null;
  }

  // فحص فرادة اسم المستخدم في Firestore
  Future<bool> _isUsernameAvailable(String username) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  Future<void> _handleCreateFarm(bool isAr) async {
    final name = _createNameCtrl.text.trim();
    final username = _createUsernameCtrl.text.trim().toLowerCase();
    final farmName = _createFarmNameCtrl.text.trim();
    final email = _createEmailCtrl.text.trim();
    final phone = _createPhoneCtrl.text.trim();
    final pass = _createPassCtrl.text.trim();

    // التحقق من الحقول الإجبارية
    if (name.isEmpty || email.isEmpty || pass.isEmpty || farmName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'الرجاء تعبئة جميع الحقول الإجبارية (*)' : 'Please fill all required fields (*)'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    // التحقق من صحة اسم المستخدم
    final usernameError = _validateUsername(username, isAr);
    if (usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(usernameError), backgroundColor: Colors.orange.shade800),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // فحص فرادة اسم المستخدم
      final available = await _isUsernameAvailable(username);
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr ? 'اسم المستخدم "$username" مستخدم بالفعل، الرجاء اختيار اسم آخر' : 'Username "$username" is already taken, please choose another'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return;
      }

      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      User? user = cred.user;
      if (user != null) {
        final farmCode = _generateUniqueCode('FARM');
        final adminKey = _generateUniqueCode('ADM');
        final workerInviteCode = _generateUniqueCode('WRK');
        final effectiveFarmName = farmName.isEmpty ? (isAr ? 'مزرعة $name' : '$name Farm') : farmName;
        final effectiveUsername = username.toLowerCase();

        // 1. حفظ المزرعة في Firestore
        await FirebaseFirestore.instance.collection('farms').doc(farmCode).set({
          'farm_code': farmCode,
          'farm_name': effectiveFarmName,
          'admin_key': adminKey,
          'manager_code': adminKey,
          'worker_code': workerInviteCode,
          'owner_uid': user.uid,
          'owner_name': name,
          'allow_worker_financials': false,
          'allow_worker_crop_edit': true,
          'allow_worker_delete': false,
          'allow_worker_diagnosis': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 2. حفظ ملف المستخدم
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'username': effectiveUsername,
          'email': email,
          'phone': phone,
          'role': 'owner',
          'farm_code': farmCode,
          'farm_name': effectiveFarmName,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. إضافة المالك كمدير عام في قائمة عمال المزرعة
        await FirebaseFirestore.instance.collection('workers').add({
          'name': name,
          'username': effectiveUsername,
          'phone': phone,
          'role': isAr ? 'المدير العام المالك' : 'General Owner / Manager',
          'status': isAr ? 'نشط' : 'Active',
          'salaryType': isAr ? 'شهري' : 'Monthly',
          'salary': 0.0,
          'notes': isAr ? 'مالك ومؤسس المزرعة' : 'Farm Owner & Creator',
          'farm_code': farmCode,
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. إرسال إشعار تأسيس المزرعة
        await FarmNotificationService.sendNotification(
          farmCode: farmCode,
          titleAr: '🎉 تأسيس المزرعة بنجاح',
          titleEn: '🎉 Farm Created Successfully',
          bodyAr: 'تم إنشاء مزرعة "$effectiveFarmName" بواسطة $name. كود المزرعة: $farmCode، رمز أمان المدير: $adminKey.',
          bodyEn: 'Farm "$effectiveFarmName" established by $name. Farm Code: $farmCode, Admin Key: $adminKey.',
          type: NotificationType.generalAlert,
        );

        if (mounted) {
          _showCreatedCodesDialog(context, isAr, effectiveFarmName, farmCode, adminKey, workerInviteCode);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'فشل إنشاء الحساب: $e' : 'Sign up failed: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. الانضمام لمزرعة موجودة (عامل أو مدير)
  Future<void> _handleJoinFarm(bool isAr) async {
    final name = _joinNameCtrl.text.trim();
    final username = _joinUsernameCtrl.text.trim().toLowerCase();
    final email = _joinEmailCtrl.text.trim();
    final phone = _joinPhoneCtrl.text.trim();
    final pass = _joinPassCtrl.text.trim();
    final farmCode = _joinFarmCodeCtrl.text.trim().toUpperCase();
    final adminKeyInput = _joinAdminKeyCtrl.text.trim().toUpperCase();
    // workerInviteCtrl preserved for future use (invite code validation)
    _joinWorkerInviteCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || farmCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'الرجاء تعبئة جميع الحقول المطلوبة وكود المزرعة' : 'Please fill all required fields and Farm Code'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    // التحقق من صحة اسم المستخدم
    final usernameError = _validateUsername(username, isAr);
    if (usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(usernameError), backgroundColor: Colors.orange.shade800),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // فحص فرادة اسم المستخدم
      final available = await _isUsernameAvailable(username);
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr ? 'اسم المستخدم "$username" مستخدم بالفعل، الرجاء اختيار اسم آخر' : 'Username "$username" is already taken, please choose another'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // فحص وجود المزرعة في قاعدة البيانات
      final farmDoc = await FirebaseFirestore.instance.collection('farms').doc(farmCode).get();
      if (!farmDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr ? 'كود المزرعة غير صحيح! يرجى التأكد من المالك.' : 'Farm Code not found! Please check with the owner.'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return;
      }

      final fData = farmDoc.data() as Map<String, dynamic>;
      final validAdminKey = (fData['admin_key'] ?? fData['manager_code'] ?? '').toString().toUpperCase();

      String assignedRole = 'worker';
      String roleTitleAr = 'عامل مزرعة';
      String roleTitleEn = 'Farm Worker';

      if (_selectedJoinRole == 'manager') {
        if (adminKeyInput.isEmpty || adminKeyInput != validAdminKey) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isAr ? 'رمز أمان المدير (Admin Key) غير صحيح!' : 'Invalid Admin Security Key!'),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
          return;
        }
        assignedRole = 'manager';
        roleTitleAr = 'مدير ومسؤول عمليات';
        roleTitleEn = 'Operations Manager';
      }

      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      User? user = cred.user;
      if (user != null) {
        final effectiveUsername = username.toLowerCase();

        // حفظ ملف المستخدم
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'username': effectiveUsername,
          'email': email,
          'phone': phone,
          'role': assignedRole,
          'farm_code': farmCode,
          'farm_name': fData['farm_name'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // إدراج المستخدم مباشرة في كادر وعمال المزرعة
        await FirebaseFirestore.instance.collection('workers').add({
          'name': name,
          'username': effectiveUsername,
          'phone': phone,
          'role': isAr ? roleTitleAr : roleTitleEn,
          'status': isAr ? 'نشط' : 'Active',
          'salaryType': isAr ? 'شهري' : 'Monthly',
          'salary': 0.0,
          'notes': isAr ? 'انضم للمزرعة ($assignedRole)' : 'Joined farm ($assignedRole)',
          'farm_code': farmCode,
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // إرسال إشعار انضمام
        await FarmNotificationService.sendNotification(
          farmCode: farmCode,
          titleAr: '👤 انضمام عضو جديد للمزرعة',
          titleEn: '👤 New Team Member Joined',
          bodyAr: 'انضم $name للمزرعة بصلاحية ($roleTitleAr).',
          bodyEn: '$name joined the farm as ($roleTitleEn).',
          type: NotificationType.memberJoined,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr ? 'تم الانضمام للمزرعة بنجاح بصلاحية: $roleTitleAr ✅' : 'Joined farm successfully as: $roleTitleEn ✅',
              ),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'حدث خطأ: $e' : 'Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreatedCodesDialog(
    BuildContext ctx,
    bool isAr,
    String farmName,
    String farmCode,
    String adminKey,
    String workerCode,
  ) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 28),
            const SizedBox(width: 8),
            Text(isAr ? 'تم إنشاء المزرعة بنجاح! 🌾' : 'Farm Created Successfully! 🌾', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAr ? 'احفظ وشارك أكواد المزرعة الرقمية مع فريقك:' : 'Save and share these digital farm keys:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 14),
            _buildCopyableCodeRow(isAr ? 'كود المزرعة الرئيسي (Farm Code)' : 'Farm Code', farmCode, const Color(0xFF2E7D32), isAr),
            const SizedBox(height: 8),
            _buildCopyableCodeRow(isAr ? 'رمز أمان المدير (Admin Key)' : 'Admin Key', adminKey, Colors.orange.shade800, isAr),
            const SizedBox(height: 8),
            _buildCopyableCodeRow(isAr ? 'كود دعوة العمال (Worker Invite)' : 'Worker Invite Code', workerCode, Colors.teal.shade800, isAr),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isAr
                    ? '💡 العمال يحتاجون فقط (كود المزرعة) للانضمام الفوري، بينما يحتاج أي مدير لـ (رمز أمان المدير).'
                    : '💡 Workers only need the Farm Code to join, while Managers require the Admin Security Key.',
                style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 11.5, height: 1.3),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(ctx);
            },
            child: Text(isAr ? 'المتابعة لتسجيل الدخول' : 'Continue to Login', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableCodeRow(String label, String code, Color color, bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(code, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 16, color: color),
            onPressed: () => _copyToClipboard(code, label, isAr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isAr, _) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: TerraTheme.mist,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(isAr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_ios_rounded, color: const Color(0xFF1B5E20), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'بوابة المزارع TerraLogic' : 'Join TerraLogic Farm System',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr ? 'اختر إنشاء مزرعة جديدة، أو الانضمام لمزرعتك بكود بسيط' : 'Create a new farm or join with your Farm Code',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),

                  // تبويب اختيار نوع التسجيل
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: const Color(0xFF2E7D32),
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: isAr ? '🌱 إنشاء مزرعة جديدة' : '🌱 Register New Farm'),
                        Tab(text: isAr ? '🤝 الانضمام لمزرعة' : '🤝 Join Existing Farm'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCreateFarmForm(isAr),
                        _buildJoinFarmForm(isAr),
                      ],
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAr ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          isAr ? 'تسجيل الدخول' : 'Login',
                          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // نموذج إنشاء مزرعة جديدة
  Widget _buildCreateFarmForm(bool isAr) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        TextField(
          controller: _createNameCtrl,
          decoration: InputDecoration(
            labelText: isAr ? 'اسم المدير / المالك *' : 'Owner / Manager Full Name *',
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2E7D32), size: 20),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _createUsernameCtrl,
          inputFormatters: [
            // حظر المسافات والأحرف الخاصة
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
          ],
          decoration: InputDecoration(
            labelText: isAr ? 'اسم المستخدم *' : 'Username *',
            hintText: isAr ? 'مثال: ahmed_farm (حروف، أرقام، _)' : 'e.g. john_farm (letters, numbers, _)',
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF2E7D32), size: 20),
            helperText: isAr ? 'يبدأ بحرف، 3-20 حرفاً، بدون مسافات' : 'Starts with letter, 3-20 chars, no spaces',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _createFarmNameCtrl,
          decoration: InputDecoration(
            labelText: isAr ? 'اسم المزرعة *' : 'Farm Name *',
            hintText: isAr ? 'مثال: مزارع الوادي الخضراء' : 'e.g. Green Valley Farm',
            prefixIcon: const Icon(Icons.agriculture_rounded, color: Color(0xFF2E7D32), size: 20),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _createEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: isAr ? 'البريد الإلكتروني *' : 'Email Address *',
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2E7D32), size: 20),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _createPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: isAr ? 'رقم الهاتف (اختياري لاستعادة الحساب)' : 'Phone Number (Optional for Recovery)',
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF2E7D32), size: 20),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _createPassCtrl,
          obscureText: _obscureCreatePass,
          decoration: InputDecoration(
            labelText: isAr ? 'كلمة المرور *' : 'Password *',
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32), size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscureCreatePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20),
              onPressed: () => setState(() => _obscureCreatePass = !_obscureCreatePass),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleCreateFarm(isAr),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    isAr ? 'تأسيس المزرعة وتوليد الأكواد' : 'Establish Farm & Generate Keys',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  // نموذج الانضمام لمزرعة قائمة
  Widget _buildJoinFarmForm(bool isAr) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        TextField(
          controller: _joinNameCtrl,
          decoration: InputDecoration(
            labelText: isAr ? 'الاسم الكامل *' : 'Full Name *',
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2E7D32), size: 20),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _joinUsernameCtrl,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
          ],
          decoration: InputDecoration(
            labelText: isAr ? 'اسم المستخدم *' : 'Username *',
            hintText: isAr ? 'مثال: worker_ali (حروف، أرقام، _)' : 'e.g. worker_ali (letters, numbers, _)',
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF2E7D32), size: 20),
            helperText: isAr ? 'يبدأ بحرف، 3-20 حرفاً، بدون مسافات' : 'Starts with letter, 3-20 chars, no spaces',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _joinEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: isAr ? 'البريد الإلكتروني *' : 'Email Address *',
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2E7D32), size: 20),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _joinPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: isAr ? 'رقم الهاتف (اختياري)' : 'Phone Number (Optional)',
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF2E7D32), size: 20),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _joinPassCtrl,
          obscureText: _obscureJoinPass,
          decoration: InputDecoration(
            labelText: isAr ? 'كلمة المرور *' : 'Password *',
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32), size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscureJoinPass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20),
              onPressed: () => setState(() => _obscureJoinPass = !_obscureJoinPass),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _joinFarmCodeCtrl,
          decoration: InputDecoration(
            labelText: isAr ? 'كود المزرعة الرئيسي *' : 'Farm Code *',
            hintText: 'FARM-XXXX',
            prefixIcon: const Icon(Icons.gite_outlined, color: Color(0xFF2E7D32), size: 20),
          ),
        ),
        const SizedBox(height: 10),

        // اختيار الدور (عامل أو مدير)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isAr ? 'نوع الانضمام:' : 'Join Role:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(isAr ? 'عامل مزرعة' : 'Worker'),
                    selected: _selectedJoinRole == 'worker',
                    selectedColor: const Color(0xFFE8F5E9),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedJoinRole = 'worker');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(isAr ? 'مدير عمليات' : 'Manager'),
                    selected: _selectedJoinRole == 'manager',
                    selectedColor: const Color(0xFFE8F5E9),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedJoinRole = 'manager');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (_selectedJoinRole == 'manager')
          TextField(
            controller: _joinAdminKeyCtrl,
            decoration: InputDecoration(
              labelText: isAr ? 'رمز أمان المدير (Admin Key) *' : 'Admin Security Key *',
              hintText: 'ADM-XXXX',
              prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.orange, size: 20),
            ),
          ),
        if (_selectedJoinRole == 'manager') const SizedBox(height: 10),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleJoinFarm(isAr),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    isAr ? 'الانضمام للمزرعة والبدء' : 'Join Farm & Get Started',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}
