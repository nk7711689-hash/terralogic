import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:terralogic/core/farm_session_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  final bool isArabic;

  const AccountSettingsScreen({super.key, this.isArabic = true});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = FarmSessionService.currentUserProfile.value;
    final authUser = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(
      text: profile?['name']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: profile?['phone']?.toString() ?? '',
    );
    _email = authUser?.email ?? profile?['email']?.toString() ?? '';
    _emailController = TextEditingController(text: _email);
  }

  late final String _email;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (user == null || name.isEmpty || phone.isEmpty) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      _show(error.message ?? 'تعذر حفظ بيانات الحساب');
    } catch (error) {
      _show('تعذر حفظ بيانات الحساب: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      _show('لا يوجد بريد مرتبط بالحساب');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _show('تم إرسال رابط تغيير كلمة المرور');
    } on FirebaseException catch (error) {
      _show(error.message ?? 'تعذر إرسال رابط تغيير كلمة المرور');
    } catch (error) {
      _show('تعذر إرسال رابط تغيير كلمة المرور: $error');
    }
  }

  void _show(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'إعدادات الحساب' : 'Account settings'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isAr ? 'اسم المستخدم' : 'User name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              readOnly: true,
              controller: _emailController,
              decoration: InputDecoration(
                labelText: isAr ? 'البريد الإلكتروني' : 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: isAr ? 'رقم الهاتف' : 'Phone number',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              readOnly: true,
              obscureText: true,
              controller: TextEditingController(text: '********'),
              decoration: InputDecoration(
                labelText: isAr ? 'كلمة المرور' : 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isAr ? 'حفظ التغييرات' : 'Save changes'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _resetPassword,
              child: Text(isAr ? 'تغيير كلمة المرور' : 'Change password'),
            ),
          ],
        ),
      ),
    );
  }
}
