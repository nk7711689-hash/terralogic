import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// إدارة جلسة وصلاحيات المزرعة والمستخدم الحالي بشكل تفاعلي مركزي
class FarmSessionService {
  static final FarmSessionService _instance = FarmSessionService._internal();
  factory FarmSessionService() => _instance;
  FarmSessionService._internal();

  // بيانات المستخدم الحالي
  static final ValueNotifier<Map<String, dynamic>?> currentUserProfile = ValueNotifier(null);
  
  // بيانات المزرعة الحالية
  static final ValueNotifier<Map<String, dynamic>?> currentFarmData = ValueNotifier(null);

  // حالة الصلاحيات التفاعلية
  static final ValueNotifier<bool> allowWorkerFinancials = ValueNotifier(false);
  static final ValueNotifier<bool> allowWorkerCropEdit = ValueNotifier(true);
  static final ValueNotifier<bool> allowWorkerDelete = ValueNotifier(false);
  static final ValueNotifier<bool> allowWorkerDiagnosis = ValueNotifier(true);
  static final ValueNotifier<bool> autoApproveWorkers = ValueNotifier(true);

  // تفضيلات الإشعارات
  static final ValueNotifier<bool> notifyFrost = ValueNotifier(true);
  static final ValueNotifier<bool> notifySecurityLogin = ValueNotifier(true);
  static final ValueNotifier<bool> notifyTeamActivity = ValueNotifier(true);
  static final ValueNotifier<bool> notifyHarvestReminder = ValueNotifier(true);

  // تفضيلات النظام
  static final ValueNotifier<String> tempUnit = ValueNotifier('C'); // 'C' or 'F'

  static StreamSubscription? _userSub;
  static StreamSubscription? _farmSub;

  /// تهيئة ومراقبة بيانات المستخدم والمزرعة الحالية
  static void initialize() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _userSub?.cancel();
      _farmSub?.cancel();

      if (user != null) {
        _userSub = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((userDoc) {
          if (userDoc.exists) {
            final uData = userDoc.data() as Map<String, dynamic>;
            currentUserProfile.value = uData;
            final farmCode = uData['farm_code']?.toString() ?? '';

            if (farmCode.isNotEmpty) {
              _listenToFarm(farmCode);
            }
          }
        });
      } else {
        currentUserProfile.value = null;
        currentFarmData.value = null;
      }
    });
  }

  static void _listenToFarm(String farmCode) {
    _farmSub?.cancel();
    _farmSub = FirebaseFirestore.instance.collection('farms').doc(farmCode).snapshots().listen((farmDoc) {
      if (farmDoc.exists) {
        final fData = farmDoc.data() as Map<String, dynamic>;
        currentFarmData.value = fData;
        
        // تحديث الصلاحيات
        allowWorkerFinancials.value = fData['allow_worker_financials'] ?? false;
        allowWorkerCropEdit.value = fData['allow_worker_crop_edit'] ?? true;
        allowWorkerDelete.value = fData['allow_worker_delete'] ?? false;
        allowWorkerDiagnosis.value = fData['allow_worker_diagnosis'] ?? true;
        autoApproveWorkers.value = fData['auto_approve_workers'] ?? true;

        // تفضيلات الإشعارات
        notifyFrost.value = fData['notify_frost'] ?? true;
        notifySecurityLogin.value = fData['notify_security_login'] ?? true;
        notifyTeamActivity.value = fData['notify_team_activity'] ?? true;
        notifyHarvestReminder.value = fData['notify_harvest_reminder'] ?? true;

        // تفضيلات النظام
        tempUnit.value = fData['temp_unit']?.toString() ?? 'C';
      }
    });
  }

  /// هل المستخدم الحالي مدير / مالك؟
  static bool get isManager {
    final role = currentUserProfile.value?['role']?.toString().toLowerCase();
    return role == 'owner' || role == 'manager' || role == 'admin';
  }

  /// هل يستطيع المستخدم الحالي رؤية المالية؟
  static bool get canViewFinancials {
    if (isManager) return true;
    return allowWorkerFinancials.value;
  }

  /// كود المزرعة الحالية
  static String get currentFarmCode {
    return currentUserProfile.value?['farm_code']?.toString() ?? '';
  }

  /// اسم المستخدم الحالي
  static String get currentUserName {
    return currentUserProfile.value?['name']?.toString() ?? 'المزارع';
  }

  /// تحديث صلاحيات المزرعة في Firestore
  static Future<void> updateFarmPermissions({
    required bool allowFinancials,
    required bool allowCropEdit,
    required bool allowDelete,
    required bool allowDiagnosis,
    required bool autoApprove,
  }) async {
    final farmCode = currentFarmCode;
    if (farmCode.isEmpty) return;

    await FirebaseFirestore.instance.collection('farms').doc(farmCode).set({
      'allow_worker_financials': allowFinancials,
      'allow_worker_crop_edit': allowCropEdit,
      'allow_worker_delete': allowDelete,
      'allow_worker_diagnosis': allowDiagnosis,
      'auto_approve_workers': autoApprove,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    allowWorkerFinancials.value = allowFinancials;
    allowWorkerCropEdit.value = allowCropEdit;
    allowWorkerDelete.value = allowDelete;
    allowWorkerDiagnosis.value = allowDiagnosis;
    autoApproveWorkers.value = autoApprove;
  }

  /// تحديث تفضيلات الإشعارات في Firestore
  static Future<void> updateNotificationPreferences({
    required bool frost,
    required bool security,
    required bool team,
    required bool harvest,
  }) async {
    final farmCode = currentFarmCode;
    if (farmCode.isEmpty) return;

    await FirebaseFirestore.instance.collection('farms').doc(farmCode).set({
      'notify_frost': frost,
      'notify_security_login': security,
      'notify_team_activity': team,
      'notify_harvest_reminder': harvest,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    notifyFrost.value = frost;
    notifySecurityLogin.value = security;
    notifyTeamActivity.value = team;
    notifyHarvestReminder.value = harvest;
  }

  /// تحديث تفضيلات النظام العامة
  static Future<void> updateFarmPreferences({
    required String unit,
  }) async {
    final farmCode = currentFarmCode;
    if (farmCode.isEmpty) return;

    await FirebaseFirestore.instance.collection('farms').doc(farmCode).set({
      'temp_unit': unit,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    tempUnit.value = unit;
  }
}
