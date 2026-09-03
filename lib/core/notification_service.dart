import 'package:cloud_firestore/cloud_firestore.dart';
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

    try {
      await _firestore.collection('notifications').add({
        'farm_code': targetFarm,
        'title_ar': titleAr,
        'title_en': titleEn,
        'body_ar': bodyAr,
        'body_en': bodyEn,
        'type': typeStr,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });
    } catch (e) {
      // Ignored silently in offline or restricted environments
    }
  }

  /// إرسال إشعار تسجيل دخول فوري للتدقيق الأمني
  static Future<void> notifyUserLogin(String userName, String role, String farmCode) async {
    final roleAr = (role == 'owner' || role == 'manager') ? 'مدير' : 'عامل';
    final roleEn = (role == 'owner' || role == 'manager') ? 'Manager' : 'Worker';

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
  static Future<void> checkWeatherFrostRisk(double currentTemp, String cityName, String farmCode) async {
    if (currentTemp <= 3.0) {
      await sendNotification(
        farmCode: farmCode,
        titleAr: '❄️ تحذير صقيع وشيك!',
        titleEn: '❄️ Frost Warning Alert!',
        bodyAr: 'انخفضت الحرارة في $cityName إلى ${currentTemp.toStringAsFixed(1)}°م. يُنصح بتشغيل الري بالرذاذ وتدفئة البيوت المحمية فوراً.',
        bodyEn: 'Temperature in $cityName dropped to ${currentTemp.toStringAsFixed(1)}°C. Recommend activating overhead misting or greenhouse heating.',
        type: NotificationType.frostAlert,
      );
    }
  }

  /// إرسال إشعار عند فحص وتشخيص نبات مصاب
  static Future<void> notifyDiseaseDetected(String cropName, String diseaseAr, String diseaseEn, String farmCode) async {
    await sendNotification(
      farmCode: farmCode,
      titleAr: '🌿 تشخيص مرض نباتي جديد',
      titleEn: '🌿 Plant Disease Detected',
      bodyAr: 'تم تسجيل إصابة في محصول $cropName بمرض ($diseaseAr). يرجى مراجعة خطة التسميد والمكافحة.',
      bodyEn: 'Disease ($diseaseEn) diagnosed on $cropName. Please review fertilizer and treatment guidelines.',
      type: NotificationType.plantDiagnosis,
    );
  }

  /// تيار عدد الإشعارات غير المقروءة لمزرعة معينة
  static Stream<int> getUnreadCountStream(String farmCode) {
    if (farmCode.isEmpty) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('farm_code', isEqualTo: farmCode)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// تحديد جميع إشعارات المزرعة كمقروءة
  static Future<void> markAllAsRead(String farmCode) async {
    if (farmCode.isEmpty) return;

    final unread = await _firestore
        .collection('notifications')
        .where('farm_code', isEqualTo: farmCode)
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// مسح إشعار محدد
  static Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }
}
