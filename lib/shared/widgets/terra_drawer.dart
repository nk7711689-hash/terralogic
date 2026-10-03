import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/core/language_controller.dart';
import 'package:terralogic/core/terra_theme.dart';
import 'package:terralogic/features/management/presentation/screens/farm_settings_screen.dart';

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
    final username = profile?['username']?.toString() ?? '';
    final photoUrl = profile?['photo_url']?.toString() ?? '';
    final isManager = FarmSessionService.isManager;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Drawer(
        backgroundColor: TerraTheme.paper,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              InkWell(
                onTap: () => _chooseProfileImage(isAr),
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
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: TerraTheme.sage,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : const AssetImage('assets/images/logo.jpg')
                                      as ImageProvider,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: TerraTheme.forest,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingImage
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        farmName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: TerraTheme.ink,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blueGrey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '@$username',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blueGrey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
              _sectionTitle(isAr ? 'الحساب' : 'Account'),
              _item(
                context,
                Icons.person_outline_rounded,
                isAr ? 'بيانات الحساب' : 'Account details',
                () => _open(context, FarmSettingsScreen(isArabic: isAr)),
              ),
              _item(
                context,
                Icons.lock_reset_outlined,
                isAr ? 'كلمة المرور والأمان' : 'Password & security',
                () => _open(context, FarmSettingsScreen(isArabic: isAr)),
              ),
              if (isManager) ...[
                _sectionTitle(isAr ? 'إعدادات المزرعة' : 'Farm settings'),
                _item(
                  context,
                  Icons.admin_panel_settings_outlined,
                  isAr ? 'المزرعة والصلاحيات' : 'Farm & permissions',
                  () => _open(context, FarmSettingsScreen(isArabic: isAr)),
                ),
              ],
              _sectionTitle(isAr ? 'المظهر واللغة' : 'Appearance & language'),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
              _sectionTitle(
                isAr ? 'المساعدة والمعلومات' : 'Help & information',
              ),
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
                isAr ? 'عن TerraLogic' : 'About TerraLogic',
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
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        color: TerraTheme.blue.withValues(alpha: 0.72),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    leading: Icon(icon, color: TerraTheme.forest),
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

  Future<void> _chooseProfileImage(bool isAr) async {
    if (_isUploadingImage) return;
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
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (picked == null || user == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final ref = FirebaseStorage.instance.ref(
        'profile_images/${user.uid}.jpg',
      );
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'photo_url': url},
      );
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
