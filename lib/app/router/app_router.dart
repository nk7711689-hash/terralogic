import 'package:flutter/material.dart';
import '../../features/ai_plant_doctor/presentation/screens/plant_doctor_screen.dart';
import '../../features/analytics_finance/presentation/screens/analytics_finance_home_screen.dart';
import '../../features/launch/presentation/screens/launch_screen.dart';
import '../../features/management/presentation/screens/management_home_screen.dart';
import '../../features/weather_climate/presentation/screens/weather_climate_home_screen.dart';

class AppRouter {
  static const String launch = '/';
  static const String management = '/management';
  static const String analyticsFinance = '/analytics-finance';
  static const String weatherClimate = '/weather-climate';
  static const String aiPlantDoctor = '/ai-plant-doctor';

  static final Map<String, WidgetBuilder> routes = {
    launch: (_) => const LaunchScreen(),
    management: (_) => const ManagementHomeScreen(),
    analyticsFinance: (_) => const AnalyticsFinanceHomeScreen(),
    weatherClimate: (_) => const WeatherClimateHomeScreen(),
    aiPlantDoctor: (_) => const PlantDoctorScreen(),
  };
}
