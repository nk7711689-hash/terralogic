import 'package:flutter/material.dart';
import '../../../../app/router/app_router.dart';
import 'package:terralogic/features/weather_climate/presentation/screens/weather_climate_home_screen.dart';

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TerraLogic')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحبًا بك في TerraLogic',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'اختر الوحدة التي تريد البدء بها:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _FeatureButton(
              title: 'وحدة الإدارة',
              subtitle: 'إدارة المحاصيل والعمال',
              onTap: () => Navigator.pushNamed(context, AppRouter.management),
            ),
            const SizedBox(height: 12),
            _FeatureButton(
              title: 'وحدة التحليل والبيانات المالية',
              subtitle: 'تحليل الأداء والتكاليف والعوائد',
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.analyticsFinance),
            ),

            //السوق والطقس 
            const SizedBox(height: 12),
            _FeatureButton(
              title: 'وحدة الطقس والمناخ',
              subtitle: 'متابعة حالة الطقس والتنبؤات',
              onTap: () {
      Navigator.push(
         context,
            MaterialPageRoute(
             builder: (context) => const WeatherClimateHomeScreen(isArabic: true),
    ),
  );
},
            ),


            const SizedBox(height: 12),
            _FeatureButton(
              title: 'وحدة الذكاء الاصطناعي - طبيب النبات',
              subtitle: 'تشخيص أمراض النبات عبر الكاميرا',
              onTap: () => Navigator.pushNamed(context, AppRouter.aiPlantDoctor),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
