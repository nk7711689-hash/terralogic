import 'package:flutter/material.dart';
import 'package:terralogic/auth_screens.dart';
import 'package:terralogic/core/terra_theme.dart';
import 'package:terralogic/signup_screen.dart';

class FarmEmptyState extends StatelessWidget {
  final bool isArabic;

  const FarmEmptyState({super.key, this.isArabic = true});

  @override
  Widget build(BuildContext context) {
    final isAr = isArabic;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          color: TerraTheme.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: TerraTheme.sage.withValues(alpha: .45)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.agriculture_rounded,
                    size: 46,
                    color: TerraTheme.forest,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isAr
                      ? 'لم تقم بإنشاء أو الانضمام إلى أي مزرعة بعد'
                      : 'You have not created or joined a farm yet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TerraTheme.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isAr
                      ? 'أنشئ مزرعتك الخاصة أو انضم إلى مزرعة موجودة عبر الكود لتدير محاصيلك، تتابع عمالك، وتطلع على التقارير بكل سهولة'
                      : 'Create your own farm or join an existing one with an invitation code to manage crops, follow workers, and view reports with ease.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateFarmScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_business_rounded),
                    label: Text(
                      isAr ? 'إنشاء مزرعة جديدة' : 'Create a new farm',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: TerraTheme.forest,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    icon: const Icon(Icons.group_add_rounded),
                    label: Text(
                      isAr
                          ? 'الانضمام إلى مزرعة (برمز الدعوة)'
                          : 'Join a farm (with invitation code)',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TerraTheme.forest,
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(
                        color: TerraTheme.forest.withValues(alpha: .35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
