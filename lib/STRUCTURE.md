# TerraLogic Lib Structure

هذا التنظيم يعتمد على `feature-first` لتجميع كل وحدة وظيفية في مكان واحد.

```text
lib/
  main.dart
  app/
    router/
  core/
    constants/
    services/
    utils/
    widgets/
  shared/
    models/
    widgets/
  features/
    launch/
      presentation/
        screens/
    management/
      data/
      domain/
      presentation/
        controllers/
        screens/
        widgets/
    analytics_finance/
      data/
      domain/
      presentation/
        controllers/
        screens/
        widgets/
    weather_climate/
      data/
      domain/
      presentation/
        controllers/
        screens/
        widgets/
    ai_plant_doctor/
      data/
      domain/
      presentation/
        controllers/
        screens/
        widgets/
```

## Purpose

- `app`: إعدادات التطبيق العامة مثل التوجيه (Routing).
- `core`: مكونات أساسية مشتركة على مستوى التطبيق.
- `shared`: عناصر مشتركة بين الوحدات (Widgets/Models).
- `features`: كل وحدة أعمال معزولة بداخلها.

## Next Step

ابدأ بإنشاء شاشة رئيسية لكل وحدة داخل:

- `features/management/presentation/screens/`
- `features/analytics_finance/presentation/screens/`
- `features/weather_climate/presentation/screens/`
- `features/ai_plant_doctor/presentation/screens/`
