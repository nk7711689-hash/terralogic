import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:terralogic/core/farm_session_service.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final _nameController = TextEditingController();
  final _salaryController = TextEditingController();
  String _selectedRole = 'worker'; // worker أو admin
  bool isArabic = true;
  
  // جلب كود المزرعة الخاص بالـ Owner الحالي لقراءة عمال مزرعته فقط
  String? currentFarmCode;

  @override
  void initState() {
    super.initState();
    _loadCurrentFarmCode();
  }

  Future<void> _loadCurrentFarmCode() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          currentFarmCode = userDoc['farm_code'];
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  // دالة إضافة عامل جديد إلى الفايربيس
  Future<void> _addWorker() async {
    if (_nameController.text.isEmpty || _salaryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'الرجاء تعبئة جميع الحقول' : 'Please fill all fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('workers').add({
        'name': _nameController.text.trim(),
        'salary': double.parse(_salaryController.text.trim()),
        'role': _selectedRole,
        'farm_code': currentFarmCode, // ربط العامل بمزرعة هذا المزارع
        'createdAt': DateTime.now(),
      });

      _nameController.clear();
      _salaryController.clear();
      if (!mounted) return;
      Navigator.pop(context); // إغلاق النافذة المنبثقة
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // دالة تعديل بيانات العامل (الراتب أو الصلاحية)
  Future<void> _editWorker(String docId, String currentName, double currentSalary, String currentRole) async {
    _nameController.text = currentName;
    _salaryController.text = currentSalary.toString();
    _selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تعديل بيانات العامل' : 'Edit Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: isArabic ? 'الاسم' : 'Name'),
            ),
            TextField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: isArabic ? 'الراتب الشهري' : 'Salary'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('workers').doc(docId).update({
                'name': _nameController.text.trim(),
                'salary': double.parse(_salaryController.text.trim()),
              });
              if (!mounted || !context.mounted) return;
              _nameController.clear();
              _salaryController.clear();
              Navigator.pop(context);
            },
            child: Text(isArabic ? 'حفظ التغييرات' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!FarmSessionService.isOwner) {
      return Scaffold(
        appBar: AppBar(title: Text(isArabic ? 'إدارة العمال' : 'Worker management')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              isArabic
                  ? 'بيانات الفريق متاحة للمالك فقط حتى اعتماد نطاقات تفويض المدير.'
                  : 'Team records are owner-only until manager scopes are configured.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (currentFarmCode == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إدارة شؤون العمال' : 'Workers Management'),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _showAddWorkerDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب عمال هذه المزرعة فقط بشكل مباشر وحي (Real-time)
        stream: FirebaseFirestore.instance
            .collection('workers')
            .where('farm_code', isEqualTo: currentFarmCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(isArabic ? 'لا يوجد عمال مضافين حالياً' : 'No workers added yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var worker = docs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.person, color: Colors.white)),
                  title: Text(worker['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${isArabic ? 'الراتب:' : 'Salary:'} \$${worker['salary']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editWorker(worker.id, worker['name'], worker['salary'], worker['role']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // نافذة منبثقة لإضافة عامل جديد
  void _showAddWorkerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isArabic ? 'إضافة عامل جديد للمزرعة' : 'Add New Worker', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: isArabic ? 'اسم العامل الكامل' : 'Worker Name')),
            const SizedBox(height: 15),
            TextField(controller: _salaryController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isArabic ? 'الراتب الشهري (\$)' : 'Monthly Salary')),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _addWorker,
                child: Text(isArabic ? 'إضافة العامل الآن' : 'Add Worker', style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
