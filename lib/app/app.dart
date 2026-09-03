import 'package:flutter/material.dart';
import 'router/app_router.dart';

class TerraLogicApp extends StatelessWidget {
  const TerraLogicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerraLogic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: AppRouter.launch,
      routes: AppRouter.routes,
    );
  }
}
