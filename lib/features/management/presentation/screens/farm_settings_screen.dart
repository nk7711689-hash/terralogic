import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terralogic/core/language_controller.dart';
import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/auth_screens.dart';

class FarmSettingsScreen extends StatefulWidget {
  final bool isArabic;
  const FarmSettingsScreen({super.key, this.isArabic = true});

  @override
  State<FarmSettingsScreen> createState() => _FarmSettingsScreenState();
}

class _FarmSettingsScreenState extends State<FarmSettingsScreen> {
  // صلاحيات العمال
  bool _allowFinancials = false;
  bool _allowCropEdit = true;
  bool _allowDelete = false;
  bool _allowDiagnosis = true;
  bool _autoApprove = true;

  // تفضيلات الإشعارات
  bool _notifyFrost = true;
  bool _notifySecurity = true;
  bool _notifyTeam = true;
  bool _notifyHarvest = true;

  // تفضيلات النظام
  String _tempUnit = 'C';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _allowFinancials = FarmSessionService.allowWorkerFinancials.value;
    _allowCropEdit = FarmSessionService.allowWorkerCropEdit.value;
    _allowDelete = FarmSessionService.allowWorkerDelete.value;
    _allowDiagnosis = FarmSessionService.allowWorkerDiagnosis.value;
    _autoApprove = FarmSessionService.autoApproveWorkers.value;

    _notifyFrost = FarmSessionService.notifyFrost.value;
    _notifySecurity = FarmSessionService.notifySecurityLogin.value;
    _notifyTeam = FarmSessionService.notifyTeamActivity.value;
    _notifyHarvest = FarmSessionService.notifyHarvestReminder.value;

    _tempUnit = FarmSessionService.tempUnit.value;
  }

  void _copyToClipboard(String text, String label, bool isAr) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تم نسخ $label إلى الحافظة بنجاح ✅' : '$label copied to clipboard ✅'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // حفظ الصلاحيات
  Future<void> _savePermissions(bool isAr) async {
    setState(() => _isSaving = true);
    try {
      await FarmSessionService.updateFarmPermissions(
        allowFinancials: _allowFinancials,
        allowCropEdit: _allowCropEdit,
        allowDelete: _allowDelete,
        allowDiagnosis: _allowDiagnosis,
        autoApprove: _autoApprove,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حفظ صلاحيات المزرعة بنجاح ✅' : 'Farm permissions saved successfully ✅'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'فشل حفظ الصلاحيات: $e' : 'Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // حفظ تفضيلات الإشعارات
  Future<void> _saveNotificationPrefs(bool isAr) async {
    setState(() => _isSaving = true);
    try {
      await FarmSessionService.updateNotificationPreferences(
        frost: _notifyFrost,
        security: _notifySecurity,
        team: _notifyTeam,
        harvest: _notifyHarvest,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حفظ تفضيلات الإشعارات ✅' : 'Notification preferences saved ✅'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // حفظ تفضيلات النظام
  Future<void> _saveSystemPrefs(bool isAr) async {
    try {
      await FarmSessionService.updateFarmPreferences(unit: _tempUnit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم تحديث التفضيلات ✅' : 'Preferences updated ✅'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // تعديل بيانات العامل
  void _showEditWorkerDialog(BuildContext context, bool isAr, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: data['phone']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: data['notes']?.toString() ?? '');
    String selectedRole = data['role']?.toString() ?? (isAr ? 'عامل قطاف' : 'Harvester');
    String selectedStatus = data['status']?.toString() ?? (isAr ? 'نشط' : 'Active');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.manage_accounts_rounded, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(isAr ? 'تعديل بيانات وصلاحيات العامل' : 'Edit Staff Details & Permissions', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'اسم الموظف' : 'Staff Name',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: isAr ? 'رقم الهاتف' : 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الدور / الصلاحية' : 'Role / Position',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  ),
                  items: (isAr 
                      ? ['عامل قطاف', 'مشرف ري', 'سائق تراكتور', 'مهندس زراعي', 'مدير ومسؤول عمليات', 'المدير العام المالك']
                      : ['Harvester', 'Irrigation Supervisor', 'Tractor Driver', 'Agronomist', 'Operations Manager', 'General Owner / Manager'])
                      .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    labelText: isAr ? 'حالة الحساب' : 'Account Status',
                    prefixIcon: const Icon(Icons.toggle_on_outlined, size: 20),
                  ),
                  items: [
                    DropdownMenuItem(value: isAr ? 'نشط' : 'Active', child: Text(isAr ? 'نشط (مفعل)' : 'Active (Enabled)', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: isAr ? 'غير نشط' : 'Inactive', child: Text(isAr ? 'غير نشط (معطل)' : 'Inactive (Disabled)', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  ],
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isAr ? 'ملاحظات' : 'Notes',
                    prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('workers').doc(doc.id).update({
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'role': selectedRole,
                    'status': selectedStatus,
                    'notes': notesCtrl.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isAr ? 'تم تحديث بيانات العامل بنجاح' : 'Staff details updated successfully'), backgroundColor: const Color(0xFF2E7D32)),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(isAr ? 'حفظ التعديل' : 'Save Changes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // إعادة تعيين كلمة المرور
  void _showPasswordResetDialog(bool isAr) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(isAr ? 'تغيير كلمة المرور' : 'Change Password', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          isAr
              ? 'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني:\r\n\r\n${user.email}'
              : 'A password reset link will be sent to your email:\r\n\r\n${user.email}',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
                if (mounted && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAr ? 'تم إرسال رابط إعادة التعيين بنجاح ✅' : 'Password reset link sent ✅'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                }
              } catch (e) {
                if (mounted && ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(isAr ? 'إرسال الرابط' : 'Send Link', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // تسجيل الخروج
  void _confirmLogout(BuildContext context, bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAr ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(isAr ? 'هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟' : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(isAr ? 'تأكيد الخروج' : 'Logout', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    final isManager = FarmSessionService.isManager;
    final canManageFarm = FarmSessionService.isOwner;
    final userProfile = FarmSessionService.currentUserProfile.value;
    final farmData = FarmSessionService.currentFarmData.value;

    final userName = userProfile?['name'] ?? (isAr ? 'مستخدم المزرعة' : 'Farm Member');
    final userEmail = userProfile?['email'] ?? '-';
    final userPhone = userProfile?['phone'] ?? '';
    final userRole = userProfile?['role'] ?? 'worker';
    final farmName = farmData?['farm_name'] ?? (isAr ? 'مزرعتي الذكية' : 'My Smart Farm');
    final farmCode = farmData?['farm_code'] ?? FarmSessionService.currentFarmCode;
    final managerCode = farmData?['manager_code'] ?? farmData?['admin_key'] ?? '-';
    final workerCode = farmData?['worker_code'] ?? '-';
    final createdAt = farmData?['createdAt'];

    String roleLabel = isAr ? 'عامل مزرعة' : 'Farm Worker';
    IconData roleIcon = Icons.person_rounded;
    if (userRole == 'owner') {
      roleLabel = isAr ? 'المالك والمؤسس' : 'Farm Owner';
      roleIcon = Icons.shield_rounded;
    }
    if (userRole == 'manager') {
      roleLabel = isAr ? 'مدير العمليات' : 'Operations Manager';
      roleIcon = Icons.admin_panel_settings_rounded;
    }

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9F7),
        appBar: AppBar(
          title: Text(
            isAr ? 'إعدادات وصلاحيات المزرعة' : 'Farm Settings & Permissions',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: LanguageToggleButton(),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            // ═══════════════════════════════════════════
            // 1. بطاقة ملف المستخدم الشخصي
            // ═══════════════════════════════════════════
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Icon(roleIcon, color: const Color(0xFF2E7D32), size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(userEmail, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          if (userPhone.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(userPhone, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isManager ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isManager ? const Color(0xFF2E7D32).withAlpha(60) : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isManager ? const Color(0xFF2E7D32) : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ═══════════════════════════════════════════
            // 2. أكواد ومعرّفات المزرعة
            // ═══════════════════════════════════════════
            _buildSectionCard(
              isAr: isAr,
              icon: Icons.gite_rounded,
              title: isAr ? 'أكواد وبيانات المزرعة' : 'Farm Identifiers & Codes',
              subtitle: isAr
                  ? 'شارك كود المزرعة والرمز المناسب مع أعضاء فريقك:'
                  : 'Share the farm code and appropriate passcode with your team:',
              children: [
                _buildCodeRow(
                  label: isAr ? 'اسم المزرعة' : 'Farm Name',
                  value: farmName,
                  color: const Color(0xFF1B5E20),
                  isAr: isAr,
                  showCopy: false,
                ),
                const SizedBox(height: 8),
                _buildCodeRow(
                  label: isAr ? 'كود المزرعة (Farm Code)' : 'Farm Code',
                  value: farmCode,
                  color: const Color(0xFF2E7D32),
                  isAr: isAr,
                ),
                const SizedBox(height: 8),
                if (canManageFarm) ...[
                  _buildCodeRow(
                    label: isAr ? 'رمز أمان المدير (Admin Key)' : 'Admin / Manager Key',
                    value: managerCode,
                    color: Colors.orange.shade800,
                    isAr: isAr,
                  ),
                  const SizedBox(height: 8),
                  _buildCodeRow(
                    label: isAr ? 'رمز دعوة العمال (Worker Invite)' : 'Worker Invite Code',
                    value: workerCode,
                    color: Colors.teal.shade800,
                    isAr: isAr,
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        isAr ? 'تأسيس المزرعة: ${_formatTimestamp(createdAt)}' : 'Created: ${_formatTimestamp(createdAt)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // ═══════════════════════════════════════════
            // 3. لوحة الصلاحيات الشاملة (مدير/مالك فقط)
            // ═══════════════════════════════════════════
            if (canManageFarm) ...[
              _buildSectionCard(
                isAr: isAr,
                icon: Icons.tune_rounded,
                title: isAr ? 'لوحة تحكم صلاحيات العمال' : 'Staff Permissions Control Panel',
                subtitle: isAr
                    ? 'تحكم بما يستطيع العمال رؤيته وتعديله داخل التطبيق:'
                    : 'Configure what workers can view and modify inside the app:',
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F0E7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isAr
                          ? 'العامل يستطيع إضافة المحاصيل وتعديل بياناتها غير المالية، ولا يستطيع حذفها أو تعديل تكاليفها ومبيعاتها. حماية هذه البيانات من الطلبات المباشرة تتطلب تحديث قواعد Firestore.'
                          : 'Workers may add crops and edit non-financial fields, but cannot delete crops or edit costs and sales. Enforcing this against direct requests requires Firestore Rules updates.',
                      style: const TextStyle(fontSize: 12, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPermissionSwitch(
                    isAr: isAr,
                    title: isAr ? 'إتاحة طبيب النبات AI' : 'AI Plant Doctor Access',
                    subtitle: isAr ? 'السماح للعمال باستخدام ماسح تشخيص الأمراض' : 'Allow workers to use the AI disease scanner',
                    icon: Icons.spa_rounded,
                    value: _allowDiagnosis,
                    onChanged: (val) => setState(() => _allowDiagnosis = val),
                  ),
                  const Divider(height: 20),
                  _buildPermissionSwitch(
                    isAr: isAr,
                    title: isAr ? 'موافقة تلقائية للعمال الجدد' : 'Auto-Approve New Workers',
                    subtitle: isAr ? 'العمال الجدد ينضمون مباشرة بدون موافقة يدوية' : 'New workers join instantly without manual approval',
                    icon: Icons.how_to_reg_rounded,
                    value: _autoApprove,
                    onChanged: (val) => setState(() => _autoApprove = val),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                      onPressed: _isSaving ? null : () => _savePermissions(isAr),
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        isAr ? 'حفظ الصلاحيات المحدثة' : 'Save Permission Changes',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ═══════════════════════════════════════════
              // 4. تفضيلات الإشعارات الذكية
              // ═══════════════════════════════════════════
              _buildSectionCard(
                isAr: isAr,
                icon: Icons.notifications_active_outlined,
                title: isAr ? 'تفضيلات الإشعارات والتنبيهات' : 'Notification & Alert Preferences',
                subtitle: isAr
                    ? 'اختر أنواع الإشعارات التي تريد تلقيها للمزرعة:'
                    : 'Select which notification types you want to receive:',
                children: [
                  _buildNotificationTile(
                    isAr: isAr,
                    title: isAr ? 'تنبيهات الصقيع والطقس' : 'Frost & Weather Alerts',
                    subtitle: isAr ? 'تنبيه فوري عند انخفاض الحرارة أو الطقس القاسي' : 'Alert when temperature drops critically or extreme weather',
                    icon: Icons.ac_unit_rounded,
                    color: Colors.blue.shade700,
                    value: _notifyFrost,
                    onChanged: (val) => setState(() => _notifyFrost = val),
                  ),
                  _buildNotificationTile(
                    isAr: isAr,
                    title: isAr ? 'إشعارات الأمان وتسجيل الدخول' : 'Security & Login Notifications',
                    subtitle: isAr ? 'تسجيل كل عملية دخول بواسطة أعضاء الفريق' : 'Record each team login for security audit',
                    icon: Icons.shield_outlined,
                    color: Colors.orange.shade700,
                    value: _notifySecurity,
                    onChanged: (val) => setState(() => _notifySecurity = val),
                  ),
                  _buildNotificationTile(
                    isAr: isAr,
                    title: isAr ? 'نشاط الفريق والانضمام' : 'Team Activity & Joins',
                    subtitle: isAr ? 'إشعار عند انضمام عامل جديد أو تغيير صلاحيات' : 'Notify on new member joins or permission changes',
                    icon: Icons.groups_outlined,
                    color: Colors.teal.shade700,
                    value: _notifyTeam,
                    onChanged: (val) => setState(() => _notifyTeam = val),
                  ),
                  _buildNotificationTile(
                    isAr: isAr,
                    title: isAr ? 'تذكيرات الحصاد والمواسم' : 'Harvest & Season Reminders',
                    subtitle: isAr ? 'تنبيهات مواعيد الحصاد والمراحل الزراعية' : 'Reminders for harvest dates and crop stages',
                    icon: Icons.event_available_rounded,
                    color: Colors.green.shade700,
                    value: _notifyHarvest,
                    onChanged: (val) => setState(() => _notifyHarvest = val),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : () => _saveNotificationPrefs(isAr),
                      icon: const Icon(Icons.save_alt_rounded, size: 18),
                      label: Text(
                        isAr ? 'حفظ تفضيلات الإشعارات' : 'Save Notification Preferences',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ═══════════════════════════════════════════
              // 5. إدارة كادر وعمال المزرعة
              // ═══════════════════════════════════════════
              _buildSectionCard(
                isAr: isAr,
                icon: Icons.people_alt_rounded,
                title: isAr ? 'إدارة كادر وعمال المزرعة' : 'Manage Staff & Roles',
                subtitle: isAr ? 'اضغط على أي عامل لتعديل بياناته وصلاحياته:' : 'Tap any staff member to edit their details and role:',
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('workers')
                        .where('farm_code', isEqualTo: farmCode)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Color(0xFF2E7D32))));
                      }
                      var workers = snapshot.hasData ? snapshot.data!.docs : [];
                      if (workers.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.person_off_outlined, size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  isAr ? 'لا يوجد عمال مسجلين في هذه المزرعة حالياً' : 'No staff registered for this farm yet',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: workers.map((wDoc) {
                          final wData = wDoc.data() as Map<String, dynamic>;
                          final wName = wData['name'] ?? 'عامل';
                          final wRole = wData['role'] ?? 'عامل قطاف';
                          final wPhone = wData['phone']?.toString() ?? '';
                          final wStatus = wData['status'] ?? 'نشط';
                          final isActive = wStatus == 'نشط' || wStatus == 'Active';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAF9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isActive ? Colors.grey.shade200 : Colors.red.shade100),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isActive ? const Color(0xFFE8F5E9) : Colors.red.shade50,
                                child: Icon(Icons.person_rounded, size: 20, color: isActive ? const Color(0xFF2E7D32) : Colors.red.shade400),
                              ),
                              title: Text(wName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(
                                "$wRole${wPhone.isNotEmpty ? ' · $wPhone' : ''} · ${isActive ? (isAr ? 'مفعل' : 'Active') : (isAr ? 'معطل' : 'Inactive')}",
                                style: TextStyle(fontSize: 11, color: isActive ? Colors.grey.shade600 : Colors.red.shade600),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2E7D32), size: 22),
                                tooltip: isAr ? 'تعديل' : 'Edit',
                                onPressed: () => _showEditWorkerDialog(context, isAr, wDoc),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // ═══════════════════════════════════════════
            // 6. تفضيلات اللغة والوحدات العامة
            // ═══════════════════════════════════════════
            _buildSectionCard(
              isAr: isAr,
              icon: Icons.language_rounded,
              title: isAr ? 'التفضيلات العامة' : 'General Preferences',
              subtitle: isAr ? 'اللغة والوحدات ومعلومات النظام:' : 'Language, units, and system information:',
              children: [
                // تبديل اللغة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.translate_rounded, size: 20, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 10),
                          Text(isAr ? 'لغة التطبيق' : 'App Language', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const LanguageToggleButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // وحدة الحرارة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.thermostat_outlined, size: 20, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 10),
                          Text(isAr ? 'وحدة الحرارة' : 'Temperature Unit', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'C', label: Text('°C', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          ButtonSegment(value: 'F', label: Text('°F', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                        selected: {_tempUnit},
                        onSelectionChanged: (selection) {
                          setState(() => _tempUnit = selection.first);
                          _saveSystemPrefs(isAr);
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.selected)) return const Color(0xFFE8F5E9);
                            return null;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.selected)) return const Color(0xFF2E7D32);
                            return Colors.grey.shade600;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // معلومات النظام والتشخيص
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E7D32).withAlpha(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(isAr ? 'معلومات النظام' : 'System Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(isAr ? 'إصدار التطبيق' : 'App Version', 'TerraLogic v1.0.0'),
                      _buildInfoRow(isAr ? 'حالة Firebase' : 'Firebase Status', isAr ? 'متصل ✅' : 'Connected ✅'),
                      _buildInfoRow(isAr ? 'المعرف' : 'User ID', FirebaseAuth.instance.currentUser?.uid.substring(0, 8) ?? '-'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ═══════════════════════════════════════════
            // 7. الأمان وتسجيل الخروج
            // ═══════════════════════════════════════════
            _buildSectionCard(
              isAr: isAr,
              icon: Icons.security_rounded,
              title: isAr ? 'الأمان والحساب' : 'Security & Account',
              subtitle: isAr ? 'إعدادات أمان الحساب والتحكم بالجلسة:' : 'Account security settings and session control:',
              children: [
                // زر تغيير كلمة المرور
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () => _showPasswordResetDialog(isAr),
                    icon: const Icon(Icons.lock_reset_rounded, size: 20),
                    label: Text(
                      isAr ? 'إعادة تعيين كلمة المرور' : 'Reset Password',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // زر تسجيل الخروج
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmLogout(context, isAr),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(
                      isAr ? 'تسجيل الخروج من المزرعة' : 'Logout from Farm',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Helper Widgets
  // ═══════════════════════════════════════════

  Widget _buildSectionCard({
    required bool isAr,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
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
                Icon(icon, color: const Color(0xFF2E7D32), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSwitch({
    required bool isAr,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: isDanger ? Colors.red.shade600 : const Color(0xFF2E7D32),
        secondary: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isDanger ? Colors.red : const Color(0xFF2E7D32)).withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: isDanger ? Colors.red.shade600 : const Color(0xFF2E7D32)),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNotificationTile({
    required bool isAr,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: color,
        secondary: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCodeRow({
    required String label,
    required String value,
    required Color color,
    required bool isAr,
    bool showCopy = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.8)),
              ],
            ),
          ),
          if (showCopy)
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 18, color: color),
              onPressed: () => _copyToClipboard(value, label, isAr),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    }
    return '-';
  }
}
