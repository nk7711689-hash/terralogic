import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/shared/widgets/farm_empty_state.dart';

class MyFarmsScreen extends StatelessWidget {
  final bool isArabic;

  const MyFarmsScreen({super.key, this.isArabic = true});

  Future<void> _selectFarm(
    BuildContext context,
    String farmCode,
    String role,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'farm_code': farmCode,
        'role': role,
      }, SetOptions(merge: true));
      if (context.mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'تعذر تبديل المزرعة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAr = isArabic;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isAr ? 'مزارعي' : 'My farms')),
        body: Center(
          child: Text(isAr ? 'سجل الدخول للمتابعة' : 'Log in to continue'),
        ),
      );
    }

    final memberships = FirebaseFirestore.instance
        .collection('farm_members')
        .where('user_uid', isEqualTo: user.uid)
        .snapshots();

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(isAr ? 'مزارعي' : 'My farms')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: memberships,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  isAr
                      ? 'تعذر تحميل المزارع المرتبطة'
                      : 'Could not load linked farms',
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs.where((doc) {
              return (doc.data()['farm_code']?.toString().trim() ?? '')
                  .isNotEmpty;
            }).toList();
            if (docs.isEmpty) {
              return FarmEmptyState(isArabic: isAr);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final membership = docs[index].data();
                final farmCode = membership['farm_code']?.toString() ?? '';
                final role = membership['role']?.toString() ?? 'worker';
                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('farms')
                      .doc(farmCode)
                      .get(),
                  builder: (context, farmSnapshot) {
                    final farm = farmSnapshot.data?.data();
                    final name =
                        farm?['farm_name']?.toString() ??
                        (isAr ? 'مزرعة غير مسماة' : 'Unnamed farm');
                    final isCurrent =
                        FarmSessionService.currentFarmCode == farmCode;
                    return Card(
                      elevation: 0,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(
                            Icons.agriculture_rounded,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('$farmCode • $role'),
                        trailing: isCurrent
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF2E7D32),
                              )
                            : TextButton(
                                onPressed: () =>
                                    _selectFarm(context, farmCode, role),
                                child: Text(isAr ? 'اختيار' : 'Select'),
                              ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
