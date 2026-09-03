// 1. كلاس الهيكل الأساسي للمرض
class DiseaseInfo {
  final String scientificName;
  final String commonName;
  final String description;
  final List<String> treatments;
  final String riskLevel;

  DiseaseInfo({
    required this.scientificName,
    required this.commonName,
    required this.description,
    required this.treatments,
    required this.riskLevel,
  });
}

// 2. قاعدة بيانات الأمراض (محلية داخل التطبيق)
final Map<String, DiseaseInfo> diseaseDatabase = {
  'Tomato_Blight': DiseaseInfo(
    scientificName: 'Phytophthora infestans',
    commonName: 'اللفحة المتأخرة في الطماطم',
    description: 'بقع بنية داكنة تظهر على الأوراق وتتوسع بسرعة مع رطوبة عالية.',
    treatments: [
      'استخدام مبيدات فطرية نحاسية.',
      'إزالة الأوراق المصابة فوراً.',
      'تحسين التهوية بين النباتات.'
    ],
    riskLevel: 'عالي',
  ),
  'Cucumber_Powdery': DiseaseInfo(
    scientificName: 'Podosphaera xanthii',
    commonName: 'البياض الدقيقي في الخيار',
    description: 'بقع بيضاء تشبه البودرة تغطي سطح الورقة.',
    treatments: [
      'استخدام محلول بيكربونات الصوديوم المخفف.',
      'تجنب الري العلوي للورق.',
      'مبيدات فطرية متخصصة.'
    ],
    riskLevel: 'متوسط',
  ),
};