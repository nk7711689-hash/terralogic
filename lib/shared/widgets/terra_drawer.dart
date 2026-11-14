import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/core/language_controller.dart';
import 'package:terralogic/core/terra_theme.dart';
import 'package:terralogic/account_settings_screen.dart';
import 'package:terralogic/my_farms_screen.dart';
import 'package:terralogic/features/management/presentation/screens/farm_settings_screen.dart';
import 'package:terralogic/features/management/presentation/screens/notifications_screen.dart';

class TerraDrawer extends StatefulWidget {
  final bool isArabic;
  final ValueChanged<int>? onNavigateTab;

  const TerraDrawer({super.key, required this.isArabic, this.onNavigateTab});

  @override
  State<TerraDrawer> createState() => _TerraDrawerState();
}

class _TerraDrawerState extends State<TerraDrawer> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    final profile = FarmSessionService.currentUserProfile.value;
    final farm = FarmSessionService.currentFarmData.value;
    final farmName =
        farm?['farm_name']?.toString() ??
        (isAr ? 'مزرعتي الذكية' : 'Smart Farm');
    final name =
        profile?['name']?.toString() ??
        (isAr ? 'مستخدم TerraLogic' : 'TerraLogic user');
    final photoUrl = profile?['photo_url']?.toString() ?? '';
    final isManager = FarmSessionService.isManager;
    final isSignedIn = FirebaseAuth.instance.currentUser != null;
    final phone = profile?['phone']?.toString().trim().isNotEmpty == true
        ? profile!['phone'].toString()
        : FirebaseAuth.instance.currentUser?.phoneNumber ??
              FirebaseAuth.instance.currentUser?.email ??
              '';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Drawer(
        backgroundColor: TerraTheme.paper,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    InkWell(
                      onTap: () => _runAuthenticated(
                        isAr,
                        () => _chooseProfileImage(isAr),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE5F0E5), Color(0xFFF4F8F1)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: TerraTheme.sage,
                                      child: ClipOval(
                                        child: photoUrl.isEmpty
                                            ? const SizedBox(
                                                width: 64,
                                                height: 64,
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  size: 34,
                                                  color: TerraTheme.forest,
                                                ),
                                              )
                                            : Image.network(
                                                photoUrl,
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                                loadingBuilder:
                                                    (context, child, progress) {
                                                      if (progress == null) {
                                                        return child;
                                                      }
                                                      return const SizedBox(
                                                        width: 64,
                                                        height: 64,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color:
                                                                    TerraTheme
                                                                        .forest,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stack,
                                                    ) => const SizedBox(
                                                      width: 64,
                                                      height: 64,
                                                      child: Icon(
                                                        Icons.person_rounded,
                                                        size: 34,
                                                        color:
                                                            TerraTheme.forest,
                                                      ),
                                                    ),
                                              ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: TerraTheme.forest,
                                        shape: BoxShape.circle,
                                      ),
                                      child: _isUploadingImage
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        name,
                                        textAlign: TextAlign.right,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: TerraTheme.ink,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (phone.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          phone,
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.blueGrey.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 7),
                                      Align(
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        child: _roleBadge(isAr),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                farmName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: TerraTheme.ink,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'اضغط على الصورة لتغييرها'
                                  : 'Tap the photo to change it',
                              style: TextStyle(
                                color: Colors.blueGrey.shade500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _item(
                      context,
                      Icons.person_outline_rounded,
                      isAr
                          ? 'بيانات الحساب الشخصي'
                          : 'Personal account details',
                      () => _runAuthenticated(
                        isAr,
                        () => _open(
                          context,
                          AccountSettingsScreen(isArabic: isAr),
                        ),
                      ),
                    ),
                    _item(
                      context,
                      Icons.agriculture_outlined,
                      isAr ? 'المزارع المنضم إليها' : 'Joined farms',
                      () => _runAuthenticated(
                        isAr,
                        () => _open(context, MyFarmsScreen(isArabic: isAr)),
                      ),
                    ),
                    if (isManager && isSignedIn) ...[
                      _item(
                        context,
                        Icons.admin_panel_settings_outlined,
                        isAr
                            ? 'إعدادات المزرعة والصلاحيات'
                            : 'Permissions & farm management',
                        () {
                          if (!isSignedIn) {
                            _showLoginRequired(context, isAr);
                            return;
                          }
                          _open(context, FarmSettingsScreen(isArabic: isAr));
                        },
                      ),
                    ],
                    _item(
                      context,
                      Icons.notifications_none_rounded,
                      isAr ? 'الإشعارات' : 'Notifications',
                      () => _runAuthenticated(
                        isAr,
                        () =>
                            _open(context, NotificationsScreen(isArabic: isAr)),
                      ),
                    ),
                    _buildGeneralSettings(isAr, isSignedIn),
                    _item(
                      context,
                      Icons.help_outline_rounded,
                      isAr ? 'الدعم والمساعدة' : 'Support',
                      () => _showSupport(context, isAr),
                    ),
                    _item(
                      context,
                      Icons.privacy_tip_outlined,
                      isAr ? 'سياسة الخصوصية' : 'Privacy policy',
                      () => _showInfo(context, isAr, true),
                    ),
                    _item(
                      context,
                      Icons.info_outline_rounded,
                      isAr ? 'عن التطبيق' : 'About the app',
                      () => _showInfo(context, isAr, false),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      child: Text(
                        'TerraLogic  •  1.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueGrey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(bool isAr, bool isSignedIn) {
    final hasFarm = FarmSessionService.currentFarmCode.trim().isNotEmpty;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 24),
      childrenPadding: const EdgeInsets.only(bottom: 6),
      leading: const Icon(Icons.settings_outlined, color: TerraTheme.forest),
      title: Text(
        isAr ? 'الإعدادات العامة' : 'General settings',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: TerraTheme.ink,
        ),
      ),
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsetsDirectional.only(start: 52, end: 24),
          secondary: const Icon(
            Icons.dark_mode_outlined,
            color: TerraTheme.forest,
          ),
          title: Text(isAr ? 'المظهر الداكن' : 'Dark appearance'),
          value: TerraTheme.isDarkMode.value,
          onChanged: (value) => TerraTheme.isDarkMode.value = value,
        ),
        _item(
          context,
          Icons.translate_rounded,
          isAr ? 'تبديل اللغة' : 'Switch language',
          () {
            AppLanguage.toggleLanguage();
            Navigator.pop(context);
          },
        ),
        if (isSignedIn && hasFarm)
          _item(
            context,
            Icons.logout_outlined,
            isAr ? 'مغادرة المزرعة الحالية' : 'Leave current farm',
            () => _confirmLeaveFarm(context, isAr),
            color: Colors.orange.shade800,
          ),
        if (isSignedIn)
          _item(
            context,
            Icons.logout_rounded,
            isAr ? 'تسجيل الخروج من الحساب' : 'Log out of account',
            () => _confirmLogout(context, isAr),
            color: Colors.red.shade700,
          ),
      ],
    );
  }

  Widget _roleBadge(bool isAr) {
    final role = FarmSessionService.currentUserProfile.value?['role']
        ?.toString()
        .toLowerCase();
    final label = role == 'owner'
        ? (isAr ? 'مالك المزرعة' : 'Farm owner')
        : role == 'manager' || role == 'admin'
        ? (isAr ? 'مدير المزرعة' : 'Farm manager')
        : (isAr ? 'عضو مزرعة' : 'Farm member');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TerraTheme.sage.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: TerraTheme.forest,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    leading: Icon(icon, color: color ?? TerraTheme.forest),
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: TerraTheme.ink,
      ),
    ),
    onTap: onTap,
  );

  void _open(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _runAuthenticated(bool isAr, VoidCallback action) {
    if (FirebaseAuth.instance.currentUser == null) {
      _showLoginRequired(context, isAr);
      return;
    }
    action();
  }

  void _showLoginRequired(BuildContext context, bool isAr) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAr ? 'تسجيل الدخول مطلوب' : 'Login required'),
        content: Text(isAr ? 'سجل الدخول للمتابعة' : 'Log in to continue'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isAr ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, bool isAr) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAr ? 'تسجيل الخروج' : 'Log out'),
        content: Text(
          isAr
              ? 'هل تريد تسجيل الخروج والعودة لوضع الزائر؟'
              : 'Log out and return to guest mode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Text(isAr ? 'تسجيل الخروج' : 'Log out'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveFarm(BuildContext context, bool isAr) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAr ? 'مغادرة المزرعة الحالية' : 'Leave current farm'),
        content: Text(
          isAr
              ? 'ستتم إزالة ارتباطك بهذه المزرعة مع الاحتفاظ بحسابك الشخصي.'
              : 'You will leave this farm while keeping your personal account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final farmCode = FarmSessionService.currentFarmCode.trim();
              if (user == null || farmCode.isEmpty) return;
              try {
                final firestore = FirebaseFirestore.instance;
                final batch = firestore.batch();
                batch.delete(
                  firestore
                      .collection('farm_members')
                      .doc('${farmCode}_${user.uid}'),
                );
                batch.delete(
                  firestore
                      .collection('workers')
                      .doc('${farmCode}_${user.uid}'),
                );
                batch.update(firestore.collection('users').doc(user.uid), {
                  'farm_code': FieldValue.delete(),
                  'farm_name': FieldValue.delete(),
                  'role': 'worker',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                await batch.commit();
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              } on FirebaseException catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error.message ??
                          (isAr
                              ? 'تعذر مغادرة المزرعة'
                              : 'Could not leave the farm'),
                    ),
                  ),
                );
              }
            },
            child: Text(isAr ? 'مغادرة المزرعة' : 'Leave farm'),
          ),
        ],
      ),
    );
  }

  String _profileImagePath(User user) => 'profile_images/${user.uid}.jpg';

  Future<void> _chooseProfileImage(bool isAr) async {
    if (_isUploadingImage) return;
    final hasPhoto =
        (FarmSessionService.currentUserProfile.value?['photo_url']
                ?.toString()
                .trim()
                .isNotEmpty ??
            false) &&
        FirebaseAuth.instance.currentUser != null;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(isAr ? 'التقاط صورة' : 'Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(isAr ? 'اختيار من المعرض' : 'Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            if (hasPhoto)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade700,
                ),
                title: Text(
                  isAr ? 'حذف الصورة الشخصية' : 'Remove profile picture',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeProfileImage(isAr);
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;
    XFile? picked;
    try {
      picked = await _imagePicker.pickImage(source: source, imageQuality: 85);
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تعذر فتح معرض الصور: ${error.message ?? error.code}'
                  : 'Could not open the image picker: ${error.message ?? error.code}',
            ),
          ),
        );
      }
      return;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تعذر اختيار الصورة: $error'
                  : 'Could not choose image: $error',
            ),
          ),
        );
      }
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (picked == null || user == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final ref = FirebaseStorage.instance.ref().child(_profileImagePath(user));
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photo_url': url,
      }, SetOptions(merge: true));
      final updated = Map<String, dynamic>.from(
        FarmSessionService.currentUserProfile.value ?? <String, dynamic>{},
      );
      updated['photo_url'] = url;
      FarmSessionService.currentUserProfile.value = updated;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تعذر تحديث الصورة: $e'
                  : 'Could not update profile photo: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _removeProfileImage(bool isAr) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isUploadingImage) return;

    setState(() => _isUploadingImage = true);
    try {
      final ref = FirebaseStorage.instance.ref().child(_profileImagePath(user));
      try {
        await ref.delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photo_url': FieldValue.delete(),
      }, SetOptions(merge: true));
      final updated = Map<String, dynamic>.from(
        FarmSessionService.currentUserProfile.value ?? <String, dynamic>{},
      )..remove('photo_url');
      FarmSessionService.currentUserProfile.value = updated;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'تم حذف الصورة الشخصية' : 'Profile picture removed',
            ),
          ),
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تعذر حذف الصورة: ${error.message ?? error.code}'
                  : 'Could not remove the profile picture: ${error.message ?? error.code}',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تعذر حذف الصورة: $error'
                  : 'Could not remove the profile picture: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showSupport(BuildContext context, bool isAr) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(isAr ? 'الدعم والمساعدة' : 'Support'),
      content: Text(
        isAr
            ? 'للمساعدة، تواصل مع مدير المزرعة أو فريق TerraLogic.'
            : 'Please contact your farm manager or the TerraLogic team.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(isAr ? 'إغلاق' : 'Close'),
        ),
      ],
    ),
  );

  void _showInfo(
    BuildContext context,
    bool isAr,
    bool privacy,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        privacy
            ? (isAr ? 'سياسة الخصوصية' : 'Privacy policy')
            : (isAr ? 'عن TerraLogic' : 'About TerraLogic'),
      ),
      content: Text(
        privacy
            ? (isAr
                  ? 'نستخدم بيانات المزرعة لتقديم خدمات الإدارة والتحليل والتشخيص داخل حسابك فقط.'
                  : 'Farm data is used only to provide management, analytics, and diagnosis services in your account.')
            : (isAr
                  ? 'TerraLogic منصة ذكية لإدارة المزارع وتحليل المحاصيل ومتابعة الطقس والتشخيص الزراعي.'
                  : 'TerraLogic is a smart platform for farm management, crop analytics, weather, and plant diagnosis.'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(isAr ? 'إغلاق' : 'Close'),
        ),
      ],
    ),
  );
}
