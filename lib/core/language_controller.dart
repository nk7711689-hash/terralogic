import 'package:flutter/material.dart';

/// وحدة التحكم المركزية بحالة اللغة في كامل التطبيق
class AppLanguage {
  /// قيمة تفاعلية تشير إلى ما إذا كانت اللغة الحالية هي العربية (true) أم الإنجليزية (false)
  static final ValueNotifier<bool> isArabic = ValueNotifier<bool>(true);

  /// تبديل اللغة الحالية
  static void toggleLanguage() {
    isArabic.value = !isArabic.value;
  }

  /// تعيين لغة محددة
  static void setLanguage(bool arabic) {
    isArabic.value = arabic;
  }
}

/// زر أنيق وموحد لتبديل اللغة يمكن وضعه في شريط الـ AppBar في أي شاشة
class LanguageToggleButton extends StatelessWidget {
  final Color? color;
  const LanguageToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, child) {
        return TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(Icons.language_rounded, size: 18, color: color ?? const Color(0xFF2E7D32)),
          label: Text(
            isArabic ? 'English' : 'العربية',
            style: TextStyle(
              color: color ?? const Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          onPressed: () => AppLanguage.toggleLanguage(),
        );
      },
    );
  }
}
