import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/core/language_controller.dart';
import 'package:terralogic/core/notification_service.dart';
import 'package:terralogic/core/terra_theme.dart';
import 'package:terralogic/features/ai_plant_doctor/presentation/screens/plant_doctor_screen.dart';
import 'package:terralogic/features/management/presentation/screens/notifications_screen.dart';
import 'package:terralogic/shared/widgets/terra_drawer.dart';
import 'package:terralogic/auth_screens.dart';
import 'package:terralogic/signup_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final bool isArabic;
  final Function(int) onNavigateTab;
  final bool isGuest;

  const HomeDashboardScreen({
    super.key,
    required this.isArabic,
    required this.onNavigateTab,
    this.isGuest = false,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _tasksCollection = FirebaseFirestore.instance.collection('farm_tasks');

  String get _farmCode => FarmSessionService.currentFarmCode;
  bool get _canManageTasks => FarmSessionService.isManager;

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: FarmSessionService.currentUserProfile,
        builder: (context, profile, __) => Scaffold(
          drawer: widget.isGuest
              ? null
              : TerraDrawer(
                  isArabic: isAr,
                  onNavigateTab: widget.onNavigateTab,
                ),
          backgroundColor: TerraTheme.mist,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            titleSpacing: 8,
            automaticallyImplyLeading: false,
            leadingWidth: widget.isGuest && isAr ? 118 : null,
            leading: widget.isGuest
                ? (isAr ? _buildGuestLoginButton(context, isAr) : null)
                : (isAr ? _buildAvatarButton(profile, isAr) : null),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 34,
                    height: 34,
                  ),
                ),
                const SizedBox(width: 9),
                const Text('TerraLogic'),
              ],
            ),
            actions: [
              if (widget.isGuest) ...[
                IconButton(
                  icon: const Icon(Icons.language_rounded),
                  tooltip: isAr ? 'English' : 'العربية',
                  onPressed: AppLanguage.toggleLanguage,
                ),
                if (!isAr) _buildGuestLoginButton(context, isAr),
              ] else if (!widget.isGuest) ...[
                StreamBuilder<int>(
                  stream: FarmNotificationService.getUnreadCountStream(
                    _farmCode,
                  ),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded),
                          tooltip: isAr ? 'الإشعارات' : 'Notifications',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NotificationsScreen(isArabic: isAr),
                            ),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count > 9 ? '9+' : '$count',
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
                if (!isAr) _buildAvatarButton(profile, isAr),
                const SizedBox(width: 8),
              ],
            ],
          ),
          body: widget.isGuest || _farmCode.isEmpty
              ? _buildGuestHome(isAr)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                  children: [
                    const SizedBox(height: 12),
                    _buildOverviewCards(isAr),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(
                          isAr ? 'قائمة المهام والأوامر' : 'Tasks & Orders',
                          Icons.view_stream_rounded,
                        ),
                        if (_canManageTasks)
                          OutlinedButton.icon(
                            onPressed: () => _showTaskEditor(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(isAr ? 'إضافة' : 'Add'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              foregroundColor: TerraTheme.forest,
                              side: BorderSide(
                                color: TerraTheme.forest.withValues(alpha: .45),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTaskFeed(isAr),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAvatarButton(Map<String, dynamic>? profile, bool isAr) {
    return Builder(
      builder: (context) {
        final photoUrl = profile?['photo_url']?.toString();
        final name = FarmSessionService.currentUserName.trim();
        return IconButton(
          tooltip: isAr ? 'الحساب والقائمة' : 'Account and menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: CircleAvatar(
            radius: 17,
            backgroundColor: TerraTheme.sage.withValues(alpha: .4),
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? Text(
                    name.isEmpty ? 'T' : name[0].toUpperCase(),
                    style: const TextStyle(
                      color: TerraTheme.forest,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildGuestLoginButton(BuildContext context, bool isAr) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
      child: FilledButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        icon: const Icon(Icons.login_rounded, size: 16),
        label: Text(isAr ? 'تسجيل الدخول' : 'Log in'),
        style: FilledButton.styleFrom(
          backgroundColor: TerraTheme.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestHome(bool isAr) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
      children: [
        _buildOverviewCards(isAr),
        const SizedBox(height: 18),
        _buildHeroBanner(isAr),
        const SizedBox(height: 18),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateFarmScreen()),
            ),
            icon: const Icon(Icons.add_business_rounded),
            label: Text(isAr ? 'إنشاء مزرعة' : 'Create a farm'),
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
      ],
    );
  }

  Widget _buildHeroBanner(bool isAr) {
    return Material(
      color: TerraTheme.paper,
      elevation: 1,
      shadowColor: TerraTheme.ink.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PlantDoctorScreen(isArabic: isAr, openDiagnosisOnStart: true),
          ),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 194,
          decoration: BoxDecoration(
            color: TerraTheme.paper,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: TerraTheme.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                const PositionedDirectional(
                  end: -30,
                  top: -35,
                  child: SizedBox(
                    width: 170,
                    height: 170,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE8F2E9),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 32,
                  bottom: 20,
                  child: Icon(
                    Icons.eco_rounded,
                    size: 92,
                    color: TerraTheme.forest.withValues(alpha: .08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isAr
                                  ? 'TerraLogic: مستقبلك الزراعي بين يديك'
                                  : 'TerraLogic: Your agricultural future',
                              style: const TextStyle(
                                color: TerraTheme.ink,
                                fontSize: 18,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              isAr
                                  ? 'أداتك الشاملة لتشخيص النباتات، إدارة المحاصيل، ومراقبة مواردك البشرية بذكاء.'
                                  : 'Your complete tool for plant diagnosis, crop management, and smart workforce monitoring.',
                              style: TextStyle(
                                color: Colors.blueGrey.shade700,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: TerraTheme.forest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isAr ? 'ابدأ التشخيص الآن' : 'Start diagnosis',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 76,
                        height: 96,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.psychology_rounded,
                              color: TerraTheme.forest,
                              size: 72,
                            ),
                            Positioned(
                              bottom: 4,
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: TerraTheme.paper,
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(
                                      BorderSide(
                                        color: TerraTheme.sage,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.eco_rounded,
                                    color: TerraTheme.forest,
                                    size: 21,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 3,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: TerraTheme.olive,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: TerraTheme.forest, size: 19),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            color: TerraTheme.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards(bool isAr) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(
                Icons.camera_alt_rounded,
                color: TerraTheme.forest,
                size: 27,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isAr ? 'شخّص نبتتك بسهولة' : 'Diagnose your plant easily',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: TerraTheme.ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isAr
                  ? 'التقط صورة للنبات واحصل على التشخيص والعلاج'
                  : 'Take a photo to get a diagnosis and treatment',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlantDoctorScreen(
                      isArabic: isAr,
                      openDiagnosisOnStart: true,
                    ),
                  ),
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 17),
                label: Text(
                  isAr
                      ? 'صور نبتتك وابدأ التشخيص'
                      : 'Take a photo and diagnose',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TerraTheme.forest,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskFeed(bool isAr) {
    if (_farmCode.isEmpty) {
      return _buildEmptyFeed(isAr);
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _tasksCollection
          .where('farm_code', isEqualTo: _farmCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildFeedMessage(
            isAr ? 'تعذر تحميل المهام' : 'Unable to load tasks',
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = [...snapshot.data!.docs];
        docs.sort((a, b) {
          final aDate = _taskDate(a);
          final bDate = _taskDate(b);
          return bDate.compareTo(aDate);
        });
        if (docs.isEmpty) return _buildEmptyFeed(isAr);
        return Column(
          children: docs.map((doc) => _buildTaskCard(doc, isAr)).toList(),
        );
      },
    );
  }

  DateTime _taskDate(QueryDocumentSnapshot doc) {
    final value = (doc.data() as Map<String, dynamic>)['created_at'];
    return value is Timestamp ? value.toDate() : DateTime(1970);
  }

  Widget _buildEmptyFeed(bool isAr) {
    return _buildFeedMessage(
      isAr ? 'لا توجد مهام حتى الآن' : 'No tasks yet',
      subtitle: _canManageTasks
          ? (isAr ? 'أضف أول مهمة للفريق' : 'Add the first task for your team')
          : (isAr ? 'ستظهر مهام الفريق هنا' : 'Team tasks will appear here'),
    );
  }

  Widget _buildFeedMessage(String title, {String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: TerraTheme.paper.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TerraTheme.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.task_alt_rounded, color: TerraTheme.sage, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: TerraTheme.ink,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCard(QueryDocumentSnapshot doc, bool isAr) {
    final data = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? const []);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final liked = uid != null && likes.contains(uid);
    final date = _taskDate(doc);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: .06),
      color: TerraTheme.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: TerraTheme.line.withValues(alpha: .8)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: TerraTheme.sage.withValues(alpha: .45),
                  child: Text(
                    (data['author_name']?.toString().trim().isNotEmpty ?? false)
                        ? data['author_name'].toString().trim()[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      color: TerraTheme.forest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['author_name']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatDate(date, isAr),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canManageTasks)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, size: 22),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showTaskEditor(doc: doc);
                      } else {
                        _deleteTask(doc.id, isAr);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(isAr ? 'تعديل' : 'Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(isAr ? 'حذف' : 'Delete'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              data['text']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: TerraTheme.ink,
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _toggleLike(doc.id, liked),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: liked
                            ? Colors.redAccent.withValues(alpha: .08)
                            : TerraTheme.mist,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: liked ? Colors.redAccent : Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${likes.length}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _showComments(doc, isAr),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: TerraTheme.mist,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.mode_comment_outlined,
                            size: 18,
                            color: TerraTheme.blue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isAr ? 'تعليقات' : 'Comments',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  String _formatDate(DateTime date, bool isAr) {
    if (date.year == 1970) return isAr ? 'الآن' : 'Now';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  }

  Future<void> _toggleLike(String taskId, bool liked) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _tasksCollection.doc(taskId).update({
      'likes': liked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> _deleteTask(String taskId, bool isAr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? 'حذف المهمة؟' : 'Delete task?'),
        content: Text(
          isAr
              ? 'سيتم حذف المهمة نهائياً.'
              : 'This task will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _tasksCollection.doc(taskId).delete();
  }

  Future<void> _showTaskEditor({QueryDocumentSnapshot? doc}) async {
    await showDialog(
      context: context,
      builder: (_) => TaskEditorDialog(
        isArabic: widget.isArabic,
        farmCode: _farmCode,
        task: doc,
      ),
    );
  }

  Future<void> _showComments(QueryDocumentSnapshot task, bool isAr) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TerraTheme.paper,
      builder: (_) => TaskCommentsSheet(isArabic: isAr, taskId: task.id),
    );
  }
}

class TaskEditorDialog extends StatefulWidget {
  final bool isArabic;
  final String farmCode;
  final QueryDocumentSnapshot? task;

  const TaskEditorDialog({
    super.key,
    required this.isArabic,
    required this.farmCode,
    this.task,
  });

  @override
  State<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<TaskEditorDialog> {
  late final TextEditingController _textController;
  bool _saving = false;

  Map<String, dynamic> get _data =>
      widget.task?.data() as Map<String, dynamic>? ?? <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: _data['text']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final payload = <String, dynamic>{
        'farm_code': widget.farmCode,
        'text': text,
        'author_id': user?.uid,
        'author_name': FarmSessionService.currentUserName,
        'likes': _data['likes'] ?? <String>[],
        'updated_at': FieldValue.serverTimestamp(),
      };
      final collection = FirebaseFirestore.instance.collection('farm_tasks');
      if (widget.task == null) {
        payload['created_at'] = FieldValue.serverTimestamp();
        await collection.add(payload);
      } else {
        await collection.doc(widget.task!.id).update(payload);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showMessage(
          '${_label('تعذر حفظ المهمة', 'Could not save task')}: $error',
        );
      }
    }
  }

  String _label(String ar, String en) => widget.isArabic ? ar : en;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _label(
                        widget.task == null
                            ? 'إضافة مهمة جديدة'
                            : 'تعديل المهمة',
                        widget.task == null ? 'Add new task' : 'Edit task',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: 4,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: _label(
                            'اكتب تفاصيل المهمة...',
                            'Describe the task...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(_label('إلغاء', 'Cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_label('حفظ', 'Save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskCommentsSheet extends StatefulWidget {
  final bool isArabic;
  final String taskId;

  const TaskCommentsSheet({
    super.key,
    required this.isArabic,
    required this.taskId,
  });

  @override
  State<TaskCommentsSheet> createState() => _TaskCommentsSheetState();
}

class _TaskCommentsSheetState extends State<TaskCommentsSheet> {
  late final TextEditingController _controller;
  late final CollectionReference<Map<String, dynamic>> _comments;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _comments = FirebaseFirestore.instance
        .collection('farm_tasks')
        .doc(widget.taskId)
        .collection('comments');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (text.isEmpty || user == null || _sending) return;
    setState(() => _sending = true);
    try {
      await _comments.add({
        'text': text,
        'author_id': user.uid,
        'author_name': FarmSessionService.currentUserName,
        'created_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _controller.clear();
        setState(() => _sending = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.isArabic ? 'تعذر إضافة التعليق' : 'Could not add comment'}: $error',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'التعليقات' : 'Comments',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _comments.orderBy('created_at').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        isAr
                            ? 'تعذر تحميل التعليقات'
                            : 'Unable to load comments',
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(isAr ? 'لا توجد تعليقات' : 'No comments'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final item = docs[index].data();
                      final author = item['author_name']?.toString() ?? 'T';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: TerraTheme.sage,
                          child: Text(author.isEmpty ? 'T' : author[0]),
                        ),
                        title: Text(author),
                        subtitle: Text(item['text']?.toString() ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'اكتب تعليقاً...'
                            : 'Write a comment...',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: TerraTheme.forest,
                    ),
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
