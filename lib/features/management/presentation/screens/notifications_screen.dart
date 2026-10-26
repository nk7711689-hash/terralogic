import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/core/notification_service.dart';
import 'package:terralogic/core/terra_theme.dart';

class NotificationsScreen extends StatelessWidget {
  final bool isArabic;
  const NotificationsScreen({super.key, this.isArabic = true});

  @override
  Widget build(BuildContext context) {
    final isAr = isArabic;
    final farmCode = FarmSessionService.currentFarmCode;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: TerraTheme.mist,
        appBar: AppBar(
          title: Text(
            isAr ? 'مركز إشعارات وتنبيهات المزرعة' : 'Farm Notifications & Alerts',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          actions: [
            if (farmCode.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF2E7D32)),
                label: Text(
                  isAr ? 'قراءة الكل' : 'Mark all read',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
                onPressed: () async {
                  try {
                    await FarmNotificationService.markAllAsRead(farmCode);
                  } on UnsupportedError {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr
                                ? 'حالة القراءة مشتركة حاليًا؛ يلزم دعم حالة قراءة مستقلة لكل عضو.'
                                : 'Read state is currently shared. Per-member read states are required.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
          ],
        ),
        body: farmCode.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        isAr ? 'سجّل الدخول بمزرعة لعرض الإشعارات' : 'Login with a farm to view alerts',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('farm_code', isEqualTo: farmCode)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        isAr ? 'حدث خطأ في تحميل الإشعارات' : 'Error loading notifications',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  var docs = snapshot.hasData ? snapshot.data!.docs : [];

                  // ترتيب الإشعارات زمنياً من الأحدث إلى الأقدم
                  docs.sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  });

                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_none_rounded, size: 48, color: Color(0xFF2E7D32)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isAr ? 'لا توجد تنبيهات جديدة حالياً' : 'No new notifications',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isAr
                                  ? 'ستظهر هنا تحذيرات الصقيع، سجلات الدخول، وتنبيهات فحص المحاصيل تلقائياً.'
                                  : 'Frost warnings, security logins, and crop diagnosis alerts will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final id = doc.id;

                      final titleAr = data['title_ar']?.toString() ?? 'إشعار';
                      final titleEn = data['title_en']?.toString() ?? 'Notification';
                      final bodyAr = data['body_ar']?.toString() ?? '';
                      final bodyEn = data['body_en']?.toString() ?? '';
                      final type = data['type']?.toString() ?? 'general';
                      final isRead = data['isRead'] as bool? ?? false;
                      final Timestamp? timestamp = data['createdAt'] as Timestamp?;

                      String timeString = '';
                      if (timestamp != null) {
                        final dt = timestamp.toDate();
                        timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}";
                      }

                      return _buildNotificationCard(
                        context: context,
                        id: id,
                        title: isAr ? titleAr : titleEn,
                        body: isAr ? bodyAr : bodyEn,
                        type: type,
                        isRead: isRead,
                        timeString: timeString,
                        isAr: isAr,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required String id,
    required String title,
    required String body,
    required String type,
    required bool isRead,
    required String timeString,
    required bool isAr,
  }) {
    IconData icon = Icons.notifications_rounded;
    Color iconColor = const Color(0xFF2E7D32);
    Color bgColor = Colors.white;

    if (type == 'frost') {
      icon = Icons.ac_unit_rounded;
      iconColor = Colors.lightBlue.shade700;
    } else if (type == 'security') {
      icon = Icons.security_rounded;
      iconColor = Colors.indigo.shade600;
    } else if (type == 'member') {
      icon = Icons.person_add_alt_1_rounded;
      iconColor = Colors.teal.shade700;
    } else if (type == 'diagnosis') {
      icon = Icons.healing_rounded;
      iconColor = Colors.green.shade800;
    } else if (type == 'harvest') {
      icon = Icons.agriculture_rounded;
      iconColor = Colors.amber.shade800;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRead ? Colors.grey.shade200 : const Color(0xFF2E7D32).withValues(alpha: 0.4),
          width: isRead ? 1 : 1.5,
        ),
      ),
      color: isRead ? bgColor : const Color(0xFFF4FAF4),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            color: isRead ? Colors.grey.shade900 : const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                      ),
                      InkWell(
                        onTap: () => FarmNotificationService.deleteNotification(id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                          child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey.shade400),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
