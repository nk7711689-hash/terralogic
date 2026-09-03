import 'package:flutter/material.dart';

class ManagementHomeScreen extends StatelessWidget {
  const ManagementHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('وحدة الإدارة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إدارة العمليات الزراعية',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.agriculture),
                title: Text('إدارة المحاصيل'),
                subtitle: Text('مثل الزيتون، مراحل الزراعة، الإنتاج'),
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.groups),
                title: Text('إدارة العمال'),
                subtitle: Text('تسجيل المهام، الحضور، وتوزيع العمل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
