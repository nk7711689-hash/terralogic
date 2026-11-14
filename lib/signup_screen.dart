import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terralogic/core/notification_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _authEmail(String contact) {
    if (contact.contains('@')) return contact;
    final digits = contact.replaceAll(RegExp(r'[^0-9]'), '');
    return 'phone_$digits@terralogic.app';
  }

  Future<void> _createAccount(bool isAr) async {
    final name = _name.text.trim();
    final contact = _contact.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;

    if (name.isEmpty || contact.isEmpty || password.isEmpty || confirm.isEmpty) {
      _message(isAr ? 'أكمل جميع الحقول المطلوبة' : 'Complete all required fields');
      return;
    }
    if (password != confirm) {
      _message(isAr ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match');
      return;
    }

    setState(() => _loading = true);
    try {
      final email = _authEmail(contact);
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) throw StateError('Account creation returned no user.');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'phone': contact.contains('@') ? '' : contact,
        'email': email,
        'role': 'worker',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'تم إنشاء الحساب بنجاح' : 'Account created successfully')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (error) {
      _message(error.message ?? (isAr ? 'تعذر إنشاء الحساب' : 'Could not create account'));
    } catch (error) {
      _message(isAr ? 'حدث خطأ: $error' : 'Error: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء حساب')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(_name, 'الاسم', Icons.person_outline),
            const SizedBox(height: 12),
            _field(_contact, 'رقم الهاتف أو البريد الإلكتروني', Icons.phone_outlined),
            const SizedBox(height: 12),
            _field(_password, 'كلمة المرور', Icons.lock_outline, obscure: _obscure),
            const SizedBox(height: 12),
            _field(_confirm, 'تأكيد كلمة المرور', Icons.lock_reset_outlined, obscure: _obscure),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () => _createAccount(true),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إنشاء الحساب'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: label.contains('الهاتف') ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: '$label *',
        prefixIcon: Icon(icon),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}

class CreateFarmScreen extends StatefulWidget {
  const CreateFarmScreen({super.key});

  @override
  State<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen> {
  final _farmName = TextEditingController();
  final _contact = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _farmName.dispose();
    _contact.dispose();
    _password.dispose();
    super.dispose();
  }

  String _code(String prefix) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return '$prefix-${List.generate(4, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  String _authEmail(String contact) {
    if (contact.contains('@')) return contact;
    final digits = contact.replaceAll(RegExp(r'[^0-9]'), '');
    return 'phone_$digits@terralogic.app';
  }

  Future<void> _resetPassword() async {
    final contact = _contact.text.trim();
    if (contact.isEmpty) {
      _show('أدخل رقم الهاتف أو البريد الإلكتروني أولاً');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _authEmail(contact),
      );
      _show('تم إرسال رابط إعادة تعيين كلمة المرور');
    } on FirebaseAuthException catch (error) {
      _show(error.message ?? 'تعذر إرسال رابط إعادة التعيين');
    } catch (error) {
      _show('تعذر إرسال رابط إعادة التعيين: $error');
    }
  }

  Future<void> _createFarm() async {
    final farmName = _farmName.text.trim();
    final contact = _contact.text.trim();
    final password = _password.text;
    if (farmName.isEmpty || contact.isEmpty || password.isEmpty) {
      _show('أكمل جميع الحقول المطلوبة');
      return;
    }

    setState(() => _loading = true);
    try {
      final accountEmail = _authEmail(contact);
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: accountEmail,
              password: password,
            );
        user = credential.user;
      } else {
        final currentEmail = user.email?.toLowerCase();
        if (currentEmail != accountEmail.toLowerCase()) {
          throw FirebaseAuthException(
            code: 'account-mismatch',
            message: 'رقم الهاتف أو البريد لا يطابق الحساب الحالي',
          );
        }
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: accountEmail, password: password),
        );
      }
      if (user == null) throw StateError('تعذر تحديد حساب المالك');

      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final ownerName = profile.data()?['name']?.toString() ?? 'مالك المزرعة';
      final farmCode = _code('FARM');
      final adminCode = _code('ADM');
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.set(firestore.collection('farms').doc(farmCode), {
        'farm_code': farmCode,
        'farm_name': farmName,
        'admin_key': adminCode,
        'manager_code': adminCode,
        'worker_code': farmCode,
        'owner_uid': user.uid,
        'owner_name': ownerName,
        'allow_worker_diagnosis': true,
        'allow_worker_crop_edit': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(firestore.collection('users').doc(user.uid), {
        'farm_code': farmCode,
        'farm_name': farmName,
        'role': 'owner',
        'phone': contact,
      }, SetOptions(merge: true));
      batch.set(
        firestore.collection('farm_members').doc('${farmCode}_${user.uid}'),
        {
        'farm_code': farmCode,
        'user_uid': user.uid,
        'role': 'owner',
        'createdAt': FieldValue.serverTimestamp(),
        },
      );
      batch.set(
        firestore.collection('workers').doc('${farmCode}_${user.uid}'),
        {
        'uid': user.uid,
        'name': ownerName,
        'phone': contact,
        'role': 'owner',
        'salary': 0,
        'farm_code': farmCode,
        'createdAt': FieldValue.serverTimestamp(),
        },
      );
      await batch.commit();
      await FarmNotificationService.sendNotification(
        farmCode: farmCode,
        titleAr: 'تم إنشاء المزرعة',
        titleEn: 'Farm created',
        bodyAr: 'تم إنشاء مزرعة $farmName',
        bodyEn: 'Farm $farmName was created',
        type: NotificationType.generalAlert,
      );
      if (mounted) _showCodes(farmCode, adminCode);
    } catch (error) {
      _show('تعذر إنشاء المزرعة: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showCodes(String farmCode, String adminCode) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تم إنشاء المزرعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _codeRow('كود المزرعة / العمال', farmCode),
            const SizedBox(height: 10),
            _codeRow('كود المدراء', adminCode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  Widget _codeRow(String label, String code) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(code, style: const TextStyle(letterSpacing: 1.2)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'نسخ',
          icon: const Icon(Icons.copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            _show('تم النسخ');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء مزرعة')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _farmName,
              decoration: const InputDecoration(
                labelText: 'اسم المزرعة *',
                prefixIcon: Icon(Icons.agriculture),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف أو البريد الإلكتروني *',
                prefixIcon: Icon(Icons.contact_phone),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور *',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _createFarm,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إنشاء مزرعة'),
              ),
            ),
            TextButton(
              onPressed: _loading ? null : _resetPassword,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: Colors.grey.shade700,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('نسيت كلمة المرور؟'),
            ),
          ],
        ),
      ),
    );
  }
}
