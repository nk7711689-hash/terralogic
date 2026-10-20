import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/language_controller.dart';
import 'core/farm_session_service.dart';
import 'core/terra_theme.dart';
import 'auth_screens.dart';
import 'features/home/presentation/screens/home_dashboard_screen.dart';
import 'features/management/presentation/screens/data_management_screen.dart';
import 'features/weather_climate/presentation/screens/weather_climate_home_screen.dart';
import 'package:terralogic/features/analytics_finance/presentation/screens/analytics_finance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FarmSessionService.initialize();
  runApp(const TerraLogicApp());
}

class TerraLogicApp extends StatelessWidget {
  const TerraLogicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: TerraTheme.isDarkMode,
          builder: (context, isDark, _) {
            return MaterialApp(
              title: 'TerraLogic',
              debugShowCheckedModeBanner: false,
              theme: TerraTheme.light(),
              darkTheme: TerraTheme.dark(),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) {
        final canViewFinance = FarmSessionService.canViewFinancials;

        final List<Widget> screens = [
          HomeDashboardScreen(
            isArabic: isArabic,
            onNavigateTab: _navigateToTab,
          ),
          DataManagementScreen(isArabic: isArabic),
          canViewFinance
              ? AnalyticsFinanceScreen(isArabic: isArabic)
              : _buildRestrictedFinanceView(isArabic),
          WeatherClimateHomeScreen(isArabic: isArabic),
        ];

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            // لا يوجد AppBar هنا حتى لا يتكرر الشريط العلوي مع الشاشات الداخلية
            body: screens[_currentIndex.clamp(0, screens.length - 1)],
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: TerraTheme.paper,
                border: Border(top: BorderSide(color: TerraTheme.line)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        0,
                        Icons.home_rounded,
                        isArabic ? 'الرئيسية' : 'Home',
                        isArabic,
                      ),
                      _buildNavItem(
                        1,
                        Icons.agriculture_rounded,
                        isArabic ? 'الإدارة' : 'Management',
                        isArabic,
                      ),
                      _buildNavItem(
                        2,
                        Icons.bar_chart_rounded,
                        isArabic ? 'المالية' : 'Finance',
                        isArabic,
                      ),
                      _buildNavItem(
                        3,
                        Icons.wb_sunny_rounded,
                        isArabic ? 'الطقس' : 'Weather',
                        isArabic,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestrictedFinanceView(bool isAr) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: Text(
          isAr ? 'التحليل المالي' : 'Financial Analytics',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: 48,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'القسم المالي محجوب' : 'Financial Analytics Restricted',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'تم تقييد الوصول إلى البيانات والأرباح المالية للعمال من قبل مدير المزرعة. يمكنك طلب تفعيل الصلاحية من المدير.'
                    : 'Access to financial yields & profits is restricted for workers by the farm manager.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isArabic) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCEBDE) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? TerraTheme.forest : const Color(0xFF91A09A),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: TerraTheme.forest,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
