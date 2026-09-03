import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/core/notification_service.dart';
import 'package:terralogic/features/management/presentation/screens/farm_settings_screen.dart';
import 'package:terralogic/features/management/presentation/screens/notifications_screen.dart';

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
    final isManager = FarmSessionService.isManager;

    final userName = userProfile?['name'] ?? (isAr ? 'المزارع' : 'Farmer');
    final farmName = farmData?['farm_name'] ?? (isAr ? 'مزرعتي الذكية' : 'Smart Farm');
    final role = userProfile?['role'] ?? 'worker';

    String roleLabel = isAr ? 'عامل مزرعة' : 'Farm Worker';
    if (role == 'owner') roleLabel = isAr ? 'المالك والمؤسس' : 'Farm Owner';
    if (role == 'manager') roleLabel = isAr ? 'مدير العمليات' : 'Operations Manager';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9F7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Image.asset('assets/images/logo.png', width: 32, height: 32),
              const SizedBox(width: 8),
              const Text(
                'TerraLogic',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF1B5E20),
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
                      icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1B5E20), size: 24),
                      tooltip: isAr ? 'الإشعارات والتنبيهات' : 'Notifications',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NotificationsScreen(isArabic: isAr)),
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
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            // زر الإعدادات وإدارة الصلاحيات
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF1B5E20), size: 23),
              tooltip: isAr ? 'الإعدادات والصلاحيات' : 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FarmSettingsScreen(isArabic: isAr)),
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
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
                              isAr ? 'مرحباً بك، $userName' : 'Welcome back, $userName',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              farmName,
                              style: TextStyle(color: Colors.green.shade100, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'كود المزرعة:' : 'Farm Code:',
                          style: TextStyle(color: Colors.green.shade100, fontSize: 12),
                        ),
                        Text(
                          farmCode.isEmpty ? 'FARM-DEFAULT' : farmCode,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. بطاقة الوصول السريع لطبيب النبات الذكي
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.green.shade200),
              ),
              color: const Color(0xFFF1F8F1),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onNavigateTab(4), // الانتقال لتبويب طبيب النبات
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.spa_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'فحص وتشخيص النبات الفوري' : 'AI Plant Disease Scanner',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAr
                                  ? 'صوّر ورقة النبات للحصول على التشخيص وخطة التسميد فوراً'
                                  : 'Snap a leaf photo for instant AI diagnosis & care plan',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isAr ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. شبكة الوصول السريع للوحدات المتبقية
            Text(
              isAr ? 'الوحدات والأقسام الرئيسية' : 'Farm Core Modules',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildModuleTile(
                    title: isAr ? 'إدارة المزرعة' : 'Management',
                    subtitle: isAr ? 'المحاصيل والعمال' : 'Crops & Staff',
                    icon: Icons.agriculture_rounded,
                    color: const Color(0xFF2E7D32),
                    onTap: () => onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModuleTile(
                    title: isAr ? 'المالية والإنتاج' : 'Finance',
                    subtitle: isAr ? 'التكاليف والأرباح' : 'Yields & Profit',
                    icon: Icons.bar_chart_rounded,
                    color: Colors.amber.shade800,
                    onTap: () => onNavigateTab(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildModuleTile(
                    title: isAr ? 'الطقس والمناخ' : 'Weather',
                    subtitle: isAr ? 'توقعات وتنبيهات' : 'Forecasts & Frost',
                    icon: Icons.wb_sunny_rounded,
                    color: Colors.orange.shade700,
                    onTap: () => onNavigateTab(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModuleTile(
                    title: isAr ? 'سجل الفحوصات' : 'Scan Logs',
                    subtitle: isAr ? 'تاريخ تشخيصاتك' : 'Diagnosis Logs',
                    icon: Icons.history_rounded,
                    color: Colors.teal.shade700,
                    onTap: () => onNavigateTab(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. بطاقة ملخص المزرعة الحية
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
                        const Icon(Icons.analytics_outlined, color: Color(0xFF2E7D32), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'نظرة سريعة على المزرعة' : 'Farm Quick Overview',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('crops').snapshots(),
                      builder: (context, cropsSnap) {
                        final cropsCount = cropsSnap.hasData ? cropsSnap.data!.docs.length : 0;
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('workers').snapshots(),
                          builder: (context, workersSnap) {
                            final workersCount = workersSnap.hasData ? workersSnap.data!.docs.length : 0;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryMetric(isAr ? 'المحاصيل المسجلة' : 'Active Crops', '$cropsCount', Icons.eco_outlined, const Color(0xFF2E7D32)),
                                Container(width: 1, height: 30, color: Colors.grey.shade200),
                                _buildSummaryMetric(isAr ? 'كادر المزرعة' : 'Staff Members', '$workersCount', Icons.people_outline, Colors.teal),
                                Container(width: 1, height: 30, color: Colors.grey.shade200),
                                _buildSummaryMetric(isAr ? 'حالة النظام' : 'System Status', isAr ? 'متصل' : 'Online', Icons.wifi_rounded, Colors.green),
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

  Widget _buildModuleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}
