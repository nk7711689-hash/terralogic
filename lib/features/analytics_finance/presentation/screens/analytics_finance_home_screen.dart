import 'package:flutter/material.dart';

class AnalyticsFinanceHomeScreen extends StatelessWidget {
  const AnalyticsFinanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحليل والبيانات المالية')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رؤية مالية وتشغيلية للمزرعة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text('لوحة التحليلات'),
                subtitle: Text('مؤشرات الإنتاج، الأداء، والمواسم'),
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet),
                title: Text('البيانات المالية'),
                subtitle: Text('التكاليف، الإيرادات، وصافي الربح'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
