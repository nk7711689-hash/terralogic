import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/core/notification_service.dart';
import 'package:terralogic/core/terra_theme.dart';
import 'package:terralogic/features/management/presentation/screens/farm_settings_screen.dart';
import 'package:terralogic/features/management/presentation/screens/notifications_screen.dart';
import 'package:terralogic/shared/widgets/terra_drawer.dart';

class HomeDashboardScreen extends StatelessWidget {
  final bool isArabic;
  final Function(int) onNavigateTab;

  const HomeDashboardScreen({
    super.key,
    required this.isArabic,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = isArabic;
    final farmCode = FarmSessionService.currentFarmCode;
    final userProfile = FarmSessionService.currentUserProfile.value;
    final farmData = FarmSessionService.currentFarmData.value;
    final userName = userProfile?['name'] ?? (isAr ? 'المزارع' : 'Farmer');
    final farmName =
        farmData?['farm_name'] ?? (isAr ? 'مزرعتي الذكية' : 'Smart Farm');
    final role = userProfile?['role'] ?? 'worker';

    String roleLabel = isAr ? 'عامل مزرعة' : 'Farm Worker';
    if (role == 'owner') {
      roleLabel = isAr ? 'المالك والمؤسس' : 'Farm Owner';
    }
    if (role == 'manager') {
      roleLabel = isAr ? 'مدير العمليات' : 'Operations Manager';
    }

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        drawer: TerraDrawer(isArabic: isAr, onNavigateTab: onNavigateTab),
        backgroundColor: TerraTheme.mist,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Image.asset('assets/images/logo.jpg', width: 32, height: 32),
              const SizedBox(width: 8),
              const Text(
                'TerraLogic',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: TerraTheme.ink,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          actions: [
            // زر جرس الإشعارات مع شارة العدد الحي
            StreamBuilder<int>(
              stream: FarmNotificationService.getUnreadCountStream(farmCode),
              builder: (context, snap) {
                final unreadCount = snap.data ?? 0;
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: TerraTheme.ink,
                        size: 24,
                      ),
                      tooltip: isAr ? 'الإشعارات والتنبيهات' : 'Notifications',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NotificationsScreen(isArabic: isAr),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            // زر الإعدادات وإدارة الصلاحيات
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: TerraTheme.ink,
                size: 23,
              ),
              tooltip: isAr ? 'الإعدادات والصلاحيات' : 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmSettingsScreen(isArabic: isAr),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            // 1. بطاقة الترحيب العريضة الأنيقة
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [TerraTheme.forest, TerraTheme.ink],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: TerraTheme.blue.withValues(alpha: 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'مرحباً بك، $userName'
                                  : 'Welcome back, $userName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              farmName,
                              style: const TextStyle(
                                color: Color(0xFFD9EAD3),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'كود المزرعة:' : 'Farm Code:',
                          style: const TextStyle(
                            color: Color(0xFFD9EAD3),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          farmCode.isEmpty ? 'FARM-DEFAULT' : farmCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. بطاقة ملخص المزرعة الحية
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.analytics_outlined,
                          color: TerraTheme.forest,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAr
                              ? 'نظرة سريعة على المزرعة'
                              : 'Farm Quick Overview',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: TerraTheme.forest,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    StreamBuilder<QuerySnapshot>(
                      stream: farmCode.isEmpty
                          ? FirebaseFirestore.instance
                                .collection('crops')
                                .limit(0)
                                .snapshots()
                          : FirebaseFirestore.instance
                                .collection('crops')
                                .where('farm_code', isEqualTo: farmCode)
                                .snapshots(),
                      builder: (context, cropsSnap) {
                        final cropsCount = cropsSnap.hasData
                            ? cropsSnap.data!.docs.length
                            : 0;
                        return StreamBuilder<QuerySnapshot>(
                          stream: farmCode.isEmpty
                              ? FirebaseFirestore.instance
                                    .collection('workers')
                                    .limit(0)
                                    .snapshots()
                              : FirebaseFirestore.instance
                                    .collection('workers')
                                    .where('farm_code', isEqualTo: farmCode)
                                    .snapshots(),
                          builder: (context, workersSnap) {
                            final workersCount = workersSnap.hasData
                                ? workersSnap.data!.docs.length
                                : 0;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryMetric(
                                  isAr ? 'المحاصيل المسجلة' : 'Active Crops',
                                  '$cropsCount',
                                  Icons.eco_outlined,
                                  TerraTheme.forest,
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade200,
                                ),
                                _buildSummaryMetric(
                                  isAr ? 'كادر المزرعة' : 'Staff Members',
                                  '$workersCount',
                                  Icons.people_outline,
                                  Colors.teal,
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade200,
                                ),
                                _buildSummaryMetric(
                                  isAr ? 'حالة النظام' : 'System Status',
                                  isAr ? 'متصل' : 'Online',
                                  Icons.wifi_rounded,
                                  Colors.green,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
