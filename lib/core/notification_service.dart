import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'farm_session_service.dart';

enum NotificationType {
  frostAlert,
  weatherAlert,
  securityLogin,
  memberJoined,
  plantDiagnosis,
  harvestReminder,
  generalAlert,
}

class FarmNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إرسال إشعار جديد إلى مزرعة معينة
  static Future<void> sendNotification({
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
    required NotificationType type,
    String? farmCode,
    Map<String, dynamic>? metadata,
    List<String>? recipientUids,
  }) async {
    final targetFarm = farmCode ?? FarmSessionService.currentFarmCode;
    if (targetFarm.isEmpty) return;

    String typeStr = 'general';
    switch (type) {
      case NotificationType.frostAlert:
        typeStr = 'frost';
        break;
      case NotificationType.weatherAlert:
        typeStr = 'weather';
        break;
      case NotificationType.securityLogin:
        typeStr = 'security';
        break;
      case NotificationType.memberJoined:
        typeStr = 'member';
        break;
      case NotificationType.plantDiagnosis:
        typeStr = 'diagnosis';
        break;
      case NotificationType.harvestReminder:
        typeStr = 'harvest';
        break;
      case NotificationType.generalAlert:
        typeStr = 'general';
        break;
    }

    final recipients = recipientUids ?? await _recipientsFor(targetFarm, type);
    if (recipients.isEmpty) return;

    final batch = _firestore.batch();
    for (final uid in recipients.toSet()) {
      final reference = _firestore.collection('notifications').doc();
      batch.set(reference, {
        'farm_code': targetFarm,
        'recipient_uid': uid,
        'title_ar': titleAr,
        'title_en': titleEn,
        'body_ar': bodyAr,
        'body_en': bodyEn,
        'type': typeStr,
        'is_read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });
    }
    await batch.commit();
  }

  static Future<List<String>> _recipientsFor(
    String farmCode,
    NotificationType type,
  ) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final managerOnly =
        type == NotificationType.securityLogin ||
        type == NotificationType.memberJoined;
    if (currentUid != null && !FarmSessionService.isManager && !managerOnly) {
      return [currentUid];
    }

    final members = await _firestore
        .collection('farm_members')
        .where('farm_code', isEqualTo: farmCode)
        .get();
    return members.docs
        .where((doc) {
          final role = doc.data()['role']?.toString().toLowerCase();
          return !managerOnly ||
              role == 'owner' ||
              role == 'manager' ||
              role == 'admin';
        })
        .map((doc) => doc.data()['user_uid']?.toString() ?? '')
        .where((uid) => uid.isNotEmpty)
        .toList();
  }

  /// إرسال إشعار تسجيل دخول فوري للتدقيق الأمني
  static Future<void> notifyUserLogin(
    String userName,
    String role,
    String farmCode,
  ) async {
    final roleAr = (role == 'owner' || role == 'manager') ? 'مدير' : 'عامل';
    final roleEn = (role == 'owner' || role == 'manager')
        ? 'Manager'
        : 'Worker';

    await sendNotification(
      farmCode: farmCode,
      titleAr: '🛡️ تسجيل دخول أمني',
      titleEn: '🛡️ Security Login Recorded',
      bodyAr: 'تم تسجيل الدخول بواسطة $userName بصلاحية ($roleAr).',
      bodyEn: 'Login recorded for $userName with ($roleEn) role.',
      type: NotificationType.securityLogin,
    );
  }

  /// فحص تلقائي لدرجات الحرارة وإرسال إشعار الصقيع إن لزم
  static Future<void> checkWeatherFrostRisk(
    double currentTemp,
    String cityName,
    String farmCode,
  ) async {
    if (currentTemp <= 3.0) {
      await sendNotification(
        farmCode: farmCode,
        titleAr: '❄️ تحذير صقيع وشيك!',
        titleEn: '❄️ Frost Warning Alert!',
        bodyAr:
            'انخفضت الحرارة في $cityName إلى ${currentTemp.toStringAsFixed(1)}°م. يُنصح بتشغيل الري بالرذاذ وتدفئة البيوت المحمية فوراً.',
        bodyEn:
            'Temperature in $cityName dropped to ${currentTemp.toStringAsFixed(1)}°C. Recommend activating overhead misting or greenhouse heating.',
        type: NotificationType.frostAlert,
      );
    }
  }

  /// إرسال إشعار عند فحص وتشخيص نبات مصاب
  static Future<void> notifyDiseaseDetected(
    String cropName,
    String diseaseAr,
    String diseaseEn,
    String farmCode,
  ) async {
    await sendNotification(
      farmCode: farmCode,
      titleAr: '🌿 تشخيص مرض نباتي جديد',
      titleEn: '🌿 Plant Disease Detected',
      bodyAr:
          'تم تسجيل إصابة في محصول $cropName بمرض ($diseaseAr). يرجى مراجعة خطة التسميد والمكافحة.',
      bodyEn:
          'Disease ($diseaseEn) diagnosed on $cropName. Please review fertilizer and treatment guidelines.',
      type: NotificationType.plantDiagnosis,
    );
  }

  /// تيار عدد الإشعارات غير المقروءة لمزرعة معينة
  static Stream<int> getUnreadCountStream(String farmCode) {
    if (farmCode.isEmpty) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('farm_code', isEqualTo: farmCode)
        .where(
          'recipient_uid',
          isEqualTo: FirebaseAuth.instance.currentUser?.uid,
        )
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Future<void> markAllAsRead(String farmCode) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || farmCode.isEmpty) return;
    final snapshot = await _firestore
        .collection('notifications')
        .where('farm_code', isEqualTo: farmCode)
        .where('recipient_uid', isEqualTo: uid)
        .where('is_read', isEqualTo: false)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'is_read': true,
        'read_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static Future<void> markAsRead(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('notifications').doc(id).update({
      'is_read': true,
      'read_at': FieldValue.serverTimestamp(),
    });
  }

  /// مسح إشعار محدد
  static Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }
}
