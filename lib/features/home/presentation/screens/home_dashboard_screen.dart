import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/core/notification_service.dart';
import 'package:terralogic/core/terra_theme.dart';
import 'package:terralogic/features/ai_plant_doctor/presentation/screens/plant_doctor_screen.dart';
import 'package:terralogic/features/management/presentation/screens/notifications_screen.dart';
import 'package:terralogic/shared/widgets/terra_drawer.dart';

class HomeDashboardScreen extends StatefulWidget {
  final bool isArabic;
  final Function(int) onNavigateTab;

  const HomeDashboardScreen({
    super.key,
    required this.isArabic,
    required this.onNavigateTab,
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
    final profile = FarmSessionService.currentUserProfile.value;
    final farm = FarmSessionService.currentFarmData.value;
    final userName =
        profile?['name']?.toString() ?? (isAr ? 'المزارع' : 'Farmer');
    final farmName =
        farm?['farm_name']?.toString() ??
        (isAr ? 'مزرعتي الذكية' : 'Smart Farm');
    final role = profile?['role']?.toString().toLowerCase();
    final roleLabel = role == 'owner'
        ? (isAr ? 'المالك والمؤسس' : 'Farm Owner')
        : role == 'manager'
        ? (isAr ? 'مدير العمليات' : 'Operations Manager')
        : (isAr ? 'عضو فريق' : 'Team Member');

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        drawer: TerraDrawer(
          isArabic: isAr,
          onNavigateTab: widget.onNavigateTab,
        ),
        backgroundColor: TerraTheme.mist,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          titleSpacing: 18,
          title: Row(
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
            StreamBuilder<int>(
              stream: FarmNotificationService.getUnreadCountStream(_farmCode),
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
                          builder: (_) => NotificationsScreen(isArabic: isAr),
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
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
          children: [
            _buildProfileCard(
              isAr: isAr,
              userName: userName,
              farmName: farmName,
              roleLabel: roleLabel,
            ),
            const SizedBox(height: 22),
            _buildSectionTitle(
              isAr ? 'نظرة سريعة على المزرعة' : 'Farm Quick Overview',
              Icons.analytics_outlined,
            ),
            const SizedBox(height: 10),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
    );
  }

  Widget _buildProfileCard({
    required bool isAr,
    required String userName,
    required String farmName,
    required String roleLabel,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF214B3C), Color(0xFF102C25)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: TerraTheme.forest.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'مرحباً بك، $userName' : 'Welcome back, $userName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      farmName,
                      style: const TextStyle(
                        color: Color(0xFFBBD8C5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .17),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'كود المزرعة:' : 'Farm code:',
                  style: const TextStyle(
                    color: Color(0xFFBBD8C5),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _farmCode.isEmpty ? 'FARM-DEFAULT' : _farmCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Row(
      children: [
        Expanded(
          child: _buildCountCard(
            isAr ? 'طبيب النبات' : 'Plant Doctor',
            Icons.spa_rounded,
            const Color(0xFF2E7D32),
            'diagnosis_history',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlantDoctorScreen(isArabic: isAr),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCountCard(
            isAr ? 'كادر المزرعة' : 'Farm Staff',
            Icons.groups_rounded,
            TerraTheme.blue,
            'workers',
            onTap: () => widget.onNavigateTab(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCountCard(
            isAr ? 'المحاصيل' : 'Crops',
            Icons.eco_rounded,
            TerraTheme.forest,
            'crops',
            onTap: () => widget.onNavigateTab(1),
          ),
        ),
      ],
    );
  }

  Widget _buildCountCard(
    String label,
    IconData icon,
    Color color,
    String collection, {
    VoidCallback? onTap,
  }) {
    final stream = _farmCode.isEmpty
        ? FirebaseFirestore.instance.collection(collection).limit(0).snapshots()
        : FirebaseFirestore.instance
              .collection(collection)
              .where('farm_code', isEqualTo: _farmCode)
              .snapshots();
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final cardContent = Container(
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          decoration: BoxDecoration(
            color: TerraTheme.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: onTap != null
                  ? color.withValues(alpha: 0.35)
                  : TerraTheme.line,
              width: onTap != null ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (onTap != null ? color : TerraTheme.ink)
                    .withValues(alpha: .05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: 5),
              Text(
                '${snapshot.data?.docs.length ?? 0}',
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onTap != null ? color : Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight:
                      onTap != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );

        if (onTap == null) return cardContent;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: cardContent,
          ),
        );
      },
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
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: TerraTheme.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: TerraTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                          fontSize: 10,
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
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
            const Divider(height: 20),
            Row(
              children: [
                InkWell(
                  onTap: () => _toggleLike(doc.id, liked),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          size: 19,
                          color: liked ? Colors.redAccent : Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${likes.length}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                InkWell(
                  onTap: () => _showComments(doc, isAr),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    child: Row(
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
                          ),
                        ),
                      ],
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
