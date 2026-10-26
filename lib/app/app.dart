import 'package:flutter/material.dart';
import '../core/terra_theme.dart';
import 'router/app_router.dart';

class TerraLogicApp extends StatelessWidget {
  const TerraLogicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TerraTheme.isDarkMode,
      builder: (context, isDark, _) => MaterialApp(
        title: 'TerraLogic',
        debugShowCheckedModeBanner: false,
        theme: TerraTheme.light(),
        darkTheme: TerraTheme.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        initialRoute: AppRouter.launch,
        routes: AppRouter.routes,
      ),
    );
  }
}
