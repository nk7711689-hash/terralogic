import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terralogic/core/farm_session_service.dart';

class DataManagementScreen extends StatefulWidget {
  final bool isArabic;
  const DataManagementScreen({super.key, this.isArabic = true});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen>
    with SingleTickerProviderStateMixin {
  String? currentFarmCode;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFarmCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmCode() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          currentFarmCode = userDoc['farm_code'];
        });
      }
    }
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      String clean = val
          .replaceAll('٠', '0')
          .replaceAll('١', '1')
          .replaceAll('٢', '2')
          .replaceAll('٣', '3')
          .replaceAll('٤', '4')
          .replaceAll('٥', '5')
          .replaceAll('٦', '6')
          .replaceAll('٧', '7')
          .replaceAll('٨', '8')
          .replaceAll('٩', '9')
          .replaceAll('٫', '.')
          .replaceAll(',', '.')
          .trim();
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  void _showNotesDialog(String title, String notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          notes.isEmpty
              ? (widget.isArabic
                    ? "لا توجد ملاحظات مسجلة"
                    : "No additional notes")
              : notes,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              widget.isArabic ? "إغلاق" : "Close",
              style: const TextStyle(color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9F7),
        appBar: AppBar(
          title: Text(
            isAr ? "إدارة بيانات المزرعة" : "Farm Data Management",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: const Color(0xFF2E7D32),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.eco_rounded, size: 20),
                    text: isAr ? "المحاصيل" : "Crops",
                  ),
                  Tab(
                    icon: const Icon(Icons.people_alt_rounded, size: 20),
                    text: isAr ? "العمال" : "Workers",
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildCropsView(isAr), _buildWorkersView(isAr)],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            isAr ? "إضافة جديد" : "Add New",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            final isManager = FarmSessionService.isManager;
            final canEditCrop =
                isManager || FarmSessionService.allowWorkerCropEdit.value;

            if (_tabController.index == 0) {
              if (canEditCrop) {
                _showAddCropBottomSheet(isAr);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr
                          ? 'صلاحية إضافة وتعديل المحاصيل مقيدة من قبل المدير'
                          : 'Adding crops is restricted by the manager',
                    ),
                    backgroundColor: Colors.orange.shade800,
                  ),
                );
              }
            } else {
              if (isManager) {
                _showAddWorkerBottomSheet(isAr);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr
                          ? 'إدارة وتعيين العمال مقتصرة على مدير المزرعة'
                          : 'Managing staff roster is restricted to managers',
                    ),
                    backgroundColor: Colors.orange.shade800,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  // --- قسم المحاصيل ---
  Widget _buildCropsView(bool isAr) {
    final farmCode = FarmSessionService.currentFarmCode;
    return StreamBuilder<QuerySnapshot>(
      stream: farmCode.isEmpty
          ? FirebaseFirestore.instance.collection('crops').limit(0).snapshots()
          : FirebaseFirestore.instance
                .collection('crops')
                .where('farm_code', isEqualTo: farmCode)
                .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr
                        ? "حدث خطأ أثناء قراءة المحاصيل:"
                        : "Error reading crops:",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${snapshot.error}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final cropsDocs = snapshot.hasData ? snapshot.data!.docs : [];

        if (cropsDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  isAr ? "لا توجد محاصيل مضافة حتى الآن" : "No crops added yet",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? "اضغط على زر الإضافة بالأسفل لإضافة أول محصول"
                      : "Tap the add button below to add your first crop",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        double totalQuantity = 0.0;
        double totalSales = 0.0;
        for (var doc in cropsDocs) {
          var d = doc.data() as Map<String, dynamic>;
          totalQuantity += _toDouble(d['quantity']);
          totalSales += _toDouble(d['sales']);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    isAr ? "إجمالي المحاصيل" : "Total Crops",
                    "${cropsDocs.length}",
                    Icons.inventory_2_outlined,
                    const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    isAr ? "الكمية الكلية" : "Total Qty",
                    "$totalQuantity ${isAr ? 'كغم' : 'kg'}",
                    Icons.scale_outlined,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    isAr ? "المبيعات" : "Sales",
                    "$totalSales JD",
                    Icons.payments_outlined,
                    Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...cropsDocs.asMap().entries.map((entry) {
              int index = entry.key;
              var doc = entry.value;
              final data = doc.data() as Map<String, dynamic>;
              final String id = doc.id;

              final String name =
                  data['name']?.toString() ?? (isAr ? 'بدون اسم' : 'Unnamed');
              final String type =
                  data['type']?.toString() ?? (isAr ? 'خضار' : 'Vegetables');
              final String harvestDate = data['harvestDate']?.toString() ?? '-';
              final double quantity = _toDouble(data['quantity']);
              final double cost = _toDouble(data['cost']);
              final double sales = _toDouble(data['sales']);
              final String status =
                  data['status']?.toString() ?? (isAr ? 'ممتاز' : 'Excellent');
              final String notes = data['notes']?.toString() ?? '';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "#CRP-${index + 1} · $type",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (status == "ممتاز" ||
                                          status == "Excellent")
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        (status == "ممتاز" ||
                                            status == "Excellent")
                                        ? const Color(0xFF2E7D32)
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.grey,
                                ),
                                onSelected: (value) => _handleCropAction(
                                  value,
                                  doc,
                                  id,
                                  name,
                                  notes,
                                  isAr,
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'details',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(isAr ? 'التفاصيل' : 'Details'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(isAr ? 'تعديل' : 'Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(isAr ? 'حذف' : 'Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAF9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoMiniItem(
                              isAr ? "الكمية" : "Quantity",
                              "$quantity ${isAr ? 'كغم' : 'kg'}",
                            ),
                            _buildInfoMiniItem(
                              isAr ? "التكلفة" : "Cost",
                              "$cost JD",
                            ),
                            _buildInfoMiniItem(
                              isAr ? "المبيعات" : "Sales",
                              sales == 0
                                  ? (isAr ? "لم يبع" : "Not Sold")
                                  : "$sales JD",
                            ),
                            _buildInfoMiniItem(
                              isAr ? "القطاف" : "Harvest",
                              harvestDate,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // --- قسم العمال ---
  Widget _buildWorkersView(bool isAr) {
    final farmCode = FarmSessionService.currentFarmCode;
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
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr
                        ? "حدث خطأ أثناء قراءة بيانات العمال:"
                        : "Error reading workers:",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${snapshot.error}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final workersDocs = snapshot.hasData ? snapshot.data!.docs : [];

        if (workersDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  isAr
                      ? "لا يوجد عمال مسجلين حالياً"
                      : "No registered workers found",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? "اضغط على زر الإضافة بالأسفل لإضافة أول عامل"
                      : "Tap the add button below to add your first worker",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        int activeCount = 0;
        double totalPayroll = 0.0;
        for (var doc in workersDocs) {
          var d = doc.data() as Map<String, dynamic>;
          String s = d['status']?.toString() ?? 'نشط';
          if (s == 'نشط' || s == 'Active') activeCount++;
          totalPayroll += _toDouble(d['salary']);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    isAr ? "إجمالي العمال" : "Total Workers",
                    "${workersDocs.length}",
                    Icons.badge_outlined,
                    const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    isAr ? "العمال النشطين" : "Active Workers",
                    "$activeCount",
                    Icons.how_to_reg_outlined,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    isAr ? "الرواتب" : "Payroll",
                    "$totalPayroll JD",
                    Icons.account_balance_wallet_outlined,
                    Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...workersDocs.asMap().entries.map((entry) {
              var doc = entry.value;
              final data = doc.data() as Map<String, dynamic>;
              final String id = doc.id;

              final String name =
                  data['name']?.toString() ?? (isAr ? 'بدون اسم' : 'Unnamed');
              final String role =
                  data['role']?.toString() ??
                  (isAr ? 'عامل قطاف' : 'Harvester');
              final String status =
                  data['status']?.toString() ?? (isAr ? 'نشط' : 'Active');
              final String salaryType =
                  data['salaryType']?.toString() ?? (isAr ? 'شهري' : 'Monthly');
              final double salary = _toDouble(data['salary']);
              final String notes = data['notes']?.toString() ?? '';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(
                          Icons.person_rounded,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (status == "نشط" || status == "Active")
                                        ? const Color(0xFFE8F5E9)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          (status == "نشط" ||
                                              status == "Active")
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$role · ${isAr ? 'راتب' : 'Salary'} $salaryType: $salary JD",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.grey,
                        ),
                        onSelected: (value) => _handleWorkerAction(
                          value,
                          doc,
                          id,
                          name,
                          notes,
                          isAr,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(isAr ? 'التفاصيل' : 'Details'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(isAr ? 'تعديل' : 'Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(isAr ? 'حذف' : 'Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMiniItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _handleCropAction(
    String action,
    DocumentSnapshot doc,
    String id,
    String name,
    String notes,
    bool isAr,
  ) async {
    final isManager = FarmSessionService.isManager;
    final canEdit = isManager || FarmSessionService.allowWorkerCropEdit.value;
    final canDelete = isManager || FarmSessionService.allowWorkerDelete.value;

    if (action == 'details') {
      _showNotesDialog(name, notes);
    } else if (action == 'edit') {
      if (canEdit) {
        _showEditCropBottomSheet(isAr, doc);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'صلاحية التعديل مقيدة من قبل المدير'
                  : 'Editing is restricted by manager',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } else if (action == 'delete') {
      if (!canDelete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'صلاحية حذف السجلات مقيدة من قبل المدير'
                  : 'Deleting records is restricted by manager',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return;
      }
      try {
        await FirebaseFirestore.instance.collection('crops').doc(id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr ? 'تم حذف المحصول بنجاح ✅' : 'Crop deleted successfully ✅',
              ),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr ? 'خطأ أثناء الحذف: $e' : 'Delete error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleWorkerAction(
    String action,
    DocumentSnapshot doc,
    String id,
    String name,
    String notes,
    bool isAr,
  ) async {
    final isManager = FarmSessionService.isManager;

    if (action == 'details') {
      _showNotesDialog(name, notes);
    } else if (action == 'edit') {
      if (isManager) {
        _showEditWorkerBottomSheet(isAr, doc);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تعديل بيانات العمال مقتصر على المدير'
                  : 'Editing staff is restricted to managers',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } else if (action == 'delete') {
      if (!isManager) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'حذف العمال مقتصر على المدير'
                  : 'Deleting staff is restricted to managers',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return;
      }
      try {
        await FirebaseFirestore.instance.collection('workers').doc(id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'تم حذف العامل بنجاح ✅'
                    : 'Worker deleted successfully ✅',
              ),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr ? 'خطأ أثناء الحذف: $e' : 'Delete error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // نافذة إضافة محصول
  void _showAddCropBottomSheet(bool isAr) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final salesCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final plantDateCtrl = TextEditingController();
    final harvestDateCtrl = TextEditingController();

    String selectedType = isAr ? 'خضار' : 'Vegetables';
    String selectedStatus = isAr ? 'ممتاز' : 'Excellent';

    Future<void> selectDate(
      BuildContext ctx,
      TextEditingController ctrl,
    ) async {
      DateTime? picked = await showDatePicker(
        context: ctx,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null) {
        ctrl.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'إضافة محصول جديد' : 'Add New Crop',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'اسم المحصول *' : 'Crop Name *',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: isAr ? 'نوع المحصول' : 'Crop Category',
                  ),
                  items:
                      (isAr
                              ? ['خضار', 'فواكه', 'حبوب']
                              : ['Vegetables', 'Fruits', 'Grains'])
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                  onChanged: (val) => setModalState(() => selectedType = val!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: plantDateCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: isAr ? 'تاريخ الزراعة' : 'Planting Date',
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                        ),
                        onTap: () => selectDate(context, plantDateCtrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: harvestDateCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: isAr ? 'تاريخ القطاف' : 'Harvest Date',
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                        ),
                        onTap: () => selectDate(context, harvestDateCtrl),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr
                              ? 'الكمية (كغم) *'
                              : 'Quantity (kg) *',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr ? 'التكلفة (JD)' : 'Cost (JD)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: salesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr
                        ? 'سعر البيع المستلم (0 إن لم يبع)'
                        : 'Sales Revenue (0 if not sold)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    labelText: isAr ? 'حالة الجودة' : 'Quality Status',
                  ),
                  items:
                      (isAr
                              ? ['ممتاز', 'متوسط', 'ضعيف']
                              : ['Excellent', 'Medium', 'Poor'])
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedStatus = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'ملاحظات وتفاصيل' : 'Notes & Details',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    try {
                      await FirebaseFirestore.instance.collection('crops').add({
                        'name': nameCtrl.text.trim(),
                        'type': selectedType,
                        'plantDate': plantDateCtrl.text.isEmpty
                            ? '-'
                            : plantDateCtrl.text.trim(),
                        'harvestDate': harvestDateCtrl.text.isEmpty
                            ? '-'
                            : harvestDateCtrl.text.trim(),
                        'quantity': _toDouble(qtyCtrl.text),
                        'cost': _toDouble(costCtrl.text),
                        'sales': _toDouble(salesCtrl.text),
                        'status': selectedStatus,
                        'notes': notesCtrl.text.trim(),
                        'farm_code': currentFarmCode ?? '',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تم حفظ المحصول بنجاح ✅'
                                  : 'Crop saved successfully ✅',
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr ? 'خطأ أثناء الحفظ: $e' : 'Save error: $e',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    isAr ? 'حفظ المحصول' : 'Save Crop',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نافذة تعديل محصول
  void _showEditCropBottomSheet(bool isAr, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(
      text: data['name']?.toString() ?? '',
    );
    final qtyCtrl = TextEditingController(
      text: (data['quantity'] ?? '').toString(),
    );
    final costCtrl = TextEditingController(
      text: (data['cost'] ?? '0.0').toString(),
    );
    final salesCtrl = TextEditingController(
      text: (data['sales'] ?? '0.0').toString(),
    );
    final notesCtrl = TextEditingController(
      text: data['notes']?.toString() ?? '',
    );
    final plantDateCtrl = TextEditingController(
      text: data['plantDate']?.toString() ?? '',
    );
    final harvestDateCtrl = TextEditingController(
      text: data['harvestDate']?.toString() ?? '',
    );

    String selectedType =
        data['type']?.toString() ?? (isAr ? 'خضار' : 'Vegetables');
    String selectedStatus =
        data['status']?.toString() ?? (isAr ? 'ممتاز' : 'Excellent');

    Future<void> selectDate(
      BuildContext ctx,
      TextEditingController ctrl,
    ) async {
      DateTime? picked = await showDatePicker(
        context: ctx,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null) {
        ctrl.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? "تعديل بيانات المحصول" : "Edit Crop Details",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'اسم المحصول' : 'Crop Name',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: isAr ? 'نوع المحصول' : 'Crop Category',
                  ),
                  items:
                      (isAr
                              ? ['خضار', 'فواكه', 'حبوب']
                              : ['Vegetables', 'Fruits', 'Grains'])
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                  onChanged: (val) => setModalState(() => selectedType = val!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: plantDateCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: isAr ? 'تاريخ الزراعة' : 'Planting Date',
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                        ),
                        onTap: () => selectDate(context, plantDateCtrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: harvestDateCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: isAr ? 'تاريخ القطاف' : 'Harvest Date',
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                        ),
                        onTap: () => selectDate(context, harvestDateCtrl),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr ? 'الكمية' : 'Quantity',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr ? 'التكلفة' : 'Cost',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: salesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'سعر البيع المستلم' : 'Sales Revenue',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    labelText: isAr ? 'حالة الجودة' : 'Quality Status',
                  ),
                  items:
                      (isAr
                              ? ['ممتاز', 'متوسط', 'ضعيف']
                              : ['Excellent', 'Medium', 'Poor'])
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedStatus = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'ملاحظات' : 'Notes',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    try {
                      await FirebaseFirestore.instance
                          .collection('crops')
                          .doc(doc.id)
                          .update({
                            'name': nameCtrl.text.trim(),
                            'type': selectedType,
                            'plantDate': plantDateCtrl.text.trim(),
                            'harvestDate': harvestDateCtrl.text.trim(),
                            'quantity': _toDouble(qtyCtrl.text),
                            'cost': _toDouble(costCtrl.text),
                            'sales': _toDouble(salesCtrl.text),
                            'status': selectedStatus,
                            'notes': notesCtrl.text.trim(),
                          });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تم تحديث المحصول بنجاح ✅'
                                  : 'Crop updated successfully ✅',
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'خطأ أثناء التعديل: $e'
                                  : 'Update error: $e',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    isAr ? 'تحديث البيانات' : 'Update Crop',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نافذة إضافة عامل
  void _showAddWorkerBottomSheet(bool isAr) {
    final nameCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    String selectedRole = isAr ? 'عامل قطاف' : 'Harvester';
    String selectedStatus = isAr ? 'نشط' : 'Active';
    String selectedSalaryType = isAr ? 'شهري' : 'Monthly';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'إضافة عامل جديد' : 'Add New Worker',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr
                        ? 'اسم العامل الكامل *'
                        : 'Worker Full Name *',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الوظيفة / الدور' : 'Role / Position',
                  ),
                  items:
                      (isAr
                              ? [
                                  'عامل قطاف',
                                  'مشرف ري',
                                  'سائق تراكتور',
                                  'مهندس زراعي',
                                ]
                              : [
                                  'Harvester',
                                  'Irrigation Supervisor',
                                  'Tractor Driver',
                                  'Agronomist',
                                ])
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setModalState(() => selectedRole = val!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          labelText: isAr ? 'حالة النشاط' : 'Activity Status',
                        ),
                        items:
                            (isAr ? ['نشط', 'غير نشط'] : ['Active', 'Inactive'])
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedStatus = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSalaryType,
                        decoration: InputDecoration(
                          labelText: isAr ? 'نوع الراتب' : 'Salary Type',
                        ),
                        items: (isAr ? ['شهري', 'يومي'] : ['Monthly', 'Daily'])
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedSalaryType = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: salaryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'قيمة الراتب (JD)' : 'Salary Amount (JD)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'ملاحظات وتفاصيل' : 'Notes & Details',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    try {
                      await FirebaseFirestore.instance
                          .collection('workers')
                          .add({
                            'name': nameCtrl.text.trim(),
                            'role': selectedRole,
                            'status': selectedStatus,
                            'salaryType': selectedSalaryType,
                            'salary': _toDouble(salaryCtrl.text),
                            'notes': notesCtrl.text.trim(),
                            'farm_code': currentFarmCode ?? '',
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تم حفظ العامل بنجاح ✅'
                                  : 'Worker saved successfully ✅',
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr ? 'خطأ أثناء الحفظ: $e' : 'Save error: $e',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    isAr ? 'حفظ العامل الجديد' : 'Save Worker',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نافذة تعديل عامل
  void _showEditWorkerBottomSheet(bool isAr, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(
      text: data['name']?.toString() ?? '',
    );
    final salaryCtrl = TextEditingController(
      text: (data['salary'] ?? '').toString(),
    );
    final notesCtrl = TextEditingController(
      text: data['notes']?.toString() ?? '',
    );

    String selectedRole =
        data['role']?.toString() ?? (isAr ? 'عامل قطاف' : 'Harvester');
    String selectedStatus =
        data['status']?.toString() ?? (isAr ? 'نشط' : 'Active');
    String selectedSalaryType =
        data['salaryType']?.toString() ?? (isAr ? 'شهري' : 'Monthly');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? "تعديل بيانات العامل" : "Edit Worker Details",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'اسم العامل' : 'Worker Name',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الوظيفة' : 'Role',
                  ),
                  items:
                      (isAr
                              ? [
                                  'عامل قطاف',
                                  'مشرف ري',
                                  'سائق تراكتور',
                                  'مهندس زراعي',
                                ]
                              : [
                                  'Harvester',
                                  'Irrigation Supervisor',
                                  'Tractor Driver',
                                  'Agronomist',
                                ])
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setModalState(() => selectedRole = val!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          labelText: isAr ? 'حالة النشاط' : 'Activity Status',
                        ),
                        items:
                            (isAr ? ['نشط', 'غير نشط'] : ['Active', 'Inactive'])
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedStatus = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSalaryType,
                        decoration: InputDecoration(
                          labelText: isAr ? 'نوع الراتب' : 'Salary Type',
                        ),
                        items: (isAr ? ['شهري', 'يومي'] : ['Monthly', 'Daily'])
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedSalaryType = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: salaryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الراتب (JD)' : 'Salary (JD)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'ملاحظات' : 'Notes',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    try {
                      await FirebaseFirestore.instance
                          .collection('workers')
                          .doc(doc.id)
                          .update({
                            'name': nameCtrl.text.trim(),
                            'role': selectedRole,
                            'status': selectedStatus,
                            'salaryType': selectedSalaryType,
                            'salary': _toDouble(salaryCtrl.text),
                            'notes': notesCtrl.text.trim(),
                          });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تم تحديث بيانات العامل بنجاح ✅'
                                  : 'Worker updated successfully ✅',
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'خطأ أثناء التعديل: $e'
                                  : 'Update error: $e',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    isAr ? 'تحديث البيانات' : 'Update Worker',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
