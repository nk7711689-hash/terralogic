import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terralogic/core/language_controller.dart';
import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/core/notification_service.dart';
import 'package:terralogic/features/ai_plant_doctor/data/plant_disease_service.dart';

/// قاموس الأمراض الشامل ثنائي اللغة (عربي وإنجليزي) مع خطط التسميد والعلاج المخصصة لكل مرض
class DiseaseDetail {
  final String nameAr;
  final String nameEn;
  final String cropAr;
  final String cropEn;
  final String descriptionAr;
  final String descriptionEn;
  final List<String> treatmentsAr;
  final List<String> treatmentsEn;
  final String fertilizerAr;
  final String fertilizerEn;

  const DiseaseDetail({
    required this.nameAr,
    required this.nameEn,
    required this.cropAr,
    required this.cropEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.treatmentsAr,
    required this.treatmentsEn,
    required this.fertilizerAr,
    required this.fertilizerEn,
  });
}

const Map<String, DiseaseDetail> kPlantDiseasesBilingual = {
  'Apple___Apple_scab': DiseaseDetail(
    nameAr: 'جرب التفاح',
    nameEn: 'Apple Scab',
    cropAr: 'تفاح',
    cropEn: 'Apple',
    descriptionAr: 'مرض فطري يسبب بقعاً زيتية رمادية إلى سوداء على الأوراق والثمار تؤدي لتشوهها وتساقطها المبكر.',
    descriptionEn: 'Fungal disease causing olive-green to black velvety spots on leaves and fruit, leading to premature defoliation.',
    treatmentsAr: ['رش مبيد فطري وقائي نحاسي أو جهازي (ديفينوكونازول)', 'تقليم الأفرع المصابة والتخلص منها خارج المزرعة', 'تجنب الري الرذاذي العلوي'],
    treatmentsEn: ['Apply copper or systemic fungicide (Difenoconazole)', 'Prune and destroy infected branches', 'Avoid overhead sprinkler irrigation'],
    fertilizerAr: 'سماد بوتاسي لرفع مناعة الثمار + كالسيوم لتحسين صلابة القشرة.',
    fertilizerEn: 'Potassium fertilizer to boost fruit immunity + Calcium to enhance peel firmness.',
  ),
  'Apple___Black_rot': DiseaseDetail(
    nameAr: 'العفن الأسود في التفاح',
    nameEn: 'Apple Black Rot',
    cropAr: 'تفاح',
    cropEn: 'Apple',
    descriptionAr: 'تعفن دائري بني مسود على الثمار مع بقع عين الضفدع على الأوراق.',
    descriptionEn: 'Circular brownish-black rot on fruits accompanied by frog-eye leaf spots.',
    treatmentsAr: ['رش مبيدات فطرية وقائية عند تساقط البتلات', 'إزالة الثمار المتعفنة والمتساقطة فوراً'],
    treatmentsEn: ['Apply protective fungicides during petal fall', 'Remove and destroy rotting and mummified fruit immediately'],
    fertilizerAr: 'تسميد متوازن NPK 20-20-20 لتقوية النمو الخضري.',
    fertilizerEn: 'Balanced NPK 20-20-20 fertilization to support vigorous vegetative growth.',
  ),
  'Apple___Cedar_apple_rust': DiseaseDetail(
    nameAr: 'صدأ أرز التفاح',
    nameEn: 'Cedar Apple Rust',
    cropAr: 'تفاح',
    cropEn: 'Apple',
    descriptionAr: 'بقع برتقالية فاقعة على السطح العلوي للأوراق مع بروزات خيطية أسفلها.',
    descriptionEn: 'Bright orange-yellow spots on upper leaf surfaces with small tube-like projections underneath.',
    treatmentsAr: ['استخدام مبيدات فطرية متخصصة بالصدأ مثل المانكوزيب أو الميكلوبوتانيل', 'إبعاد أشجار العرعر القريبة'],
    treatmentsEn: ['Use rust-specific fungicides like Mancozeb or Myclobutanil', 'Remove nearby juniper/cedar host trees'],
    fertilizerAr: 'عناصر صغرى (زنك وحديد ومغنيسيوم) لتعويض إجهاد البناء الضوئي.',
    fertilizerEn: 'Micronutrients (Zinc, Iron, Magnesium) to compensate for photosynthetic stress.',
  ),
  'Apple___healthy': DiseaseDetail(
    nameAr: 'أوراق تفاح سليمة',
    nameEn: 'Healthy Apple Leaves',
    cropAr: 'تفاح',
    cropEn: 'Apple',
    descriptionAr: 'شجرة التفاح بحالة صحية ممتازة ومثالية ولا تظهر عليها أي أعراض مرضية.',
    descriptionEn: 'Apple tree is in excellent, vigorous condition with no visible signs of disease.',
    treatmentsAr: ['الاستمرار في برنامج الري والتسميد الدوري والوقائي المعتاد'],
    treatmentsEn: ['Continue standard routine watering and preventative care'],
    fertilizerAr: 'سماد NPK متوازن + عناصر صغرى دورية.',
    fertilizerEn: 'Balanced NPK fertilizer + periodic trace elements.',
  ),
  'Blueberry___healthy': DiseaseDetail(
    nameAr: 'نبات توت أزرق سليم',
    nameEn: 'Healthy Blueberry',
    cropAr: 'توت أزرق',
    cropEn: 'Blueberry',
    descriptionAr: 'النبات سليم ومعافى وينمو بشكل طبيعي.',
    descriptionEn: 'Blueberry plant is healthy, thriving under optimal acidic soil conditions.',
    treatmentsAr: ['الحفاظ على حموضة التربة المناسبة (pH 4.5 - 5.5)'],
    treatmentsEn: ['Maintain suitable acidic soil pH (4.5 - 5.5)'],
    fertilizerAr: 'سلفات الأمونيوم وسماد عضوي حامضي.',
    fertilizerEn: 'Ammonium sulfate and acidic organic fertilizer.',
  ),
  'Cherry_(including_sour)___Powdery_mildew': DiseaseDetail(
    nameAr: 'البياض الدقيقي في الكرز',
    nameEn: 'Cherry Powdery Mildew',
    cropAr: 'كرز',
    cropEn: 'Cherry',
    descriptionAr: 'طبقة مسحوقية بيضاء دقيقة تغطي الأوراق والنموات الحديثة وتلتف الأوراق المصابة.',
    descriptionEn: 'White powdery fungal coating on leaves and young shoots causing leaf distortion.',
    treatmentsAr: ['رش الكبريت الميكروني الوقائي', 'مبيد فطري جهازي مثل بينكونازول أو توباس'],
    treatmentsEn: ['Spray micronized wettable sulfur', 'Apply systemic fungicide (Penconazole or Topas)'],
    fertilizerAr: 'تجنب الإفراط في التسميد النيتروجيني واستخدام سيليكات البوتاسيوم.',
    fertilizerEn: 'Avoid excessive nitrogen; apply Potassium Silicate for cuticle strengthening.',
  ),
  'Cherry_(including_sour)___healthy': DiseaseDetail(
    nameAr: 'أوراق كرز سليمة',
    nameEn: 'Healthy Cherry',
    cropAr: 'كرز',
    cropEn: 'Cherry',
    descriptionAr: 'النبات سليم ومعافى تماماً.',
    descriptionEn: 'Cherry tree is healthy and foliage is vibrant.',
    treatmentsAr: ['المتابعة الدورية والتقليم الجيد لضمان دخول الشمس والتهوية'],
    treatmentsEn: ['Regular monitoring and good canopy pruning for sun exposure'],
    fertilizerAr: 'تسميد عضوي شتوي وNPK متوازن.',
    fertilizerEn: 'Winter organic manure and balanced NPK fertilizer.',
  ),
  'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot': DiseaseDetail(
    nameAr: 'تبقع أوراق الذرة الرمادي (سيركوسبورا)',
    nameEn: 'Corn Gray Leaf Spot (Cercospora)',
    cropAr: 'ذرة',
    cropEn: 'Corn',
    descriptionAr: 'بقع مستطيلة متوازية مع عروق الورقة تتحول للون الرمادي البني.',
    descriptionEn: 'Rectangular tan-to-gray lesions running parallel to leaf veins.',
    treatmentsAr: ['اتباع دورة زراعية مناسبة', 'رش مبيدات فطرية من مجموعة ستروبيلورين'],
    treatmentsEn: ['Implement crop rotation', 'Apply strobilurin-class fungicides'],
    fertilizerAr: 'تسميد بوتاسي لتقوية جدر الخلايا في الساق والأوراق ومقاومة الرقاد.',
    fertilizerEn: 'Potassium fertilization to strengthen stalks and prevent lodging.',
  ),
  'Corn_(maize)___Common_rust_': DiseaseDetail(
    nameAr: 'الصدأ الشائع في الذرة',
    nameEn: 'Corn Common Rust',
    cropAr: 'ذرة',
    cropEn: 'Corn',
    descriptionAr: 'بثور بنية محمرة تنتشر على سطحي الورقة تفرز غباراً بلون الصدأ يقلل البناء الضوئي.',
    descriptionEn: 'Reddish-brown pustules on both leaf surfaces releasing rust-colored powdery spores.',
    treatmentsAr: ['زراعة أصناف مقاومة', 'رش مبيدات مانكوزيب أو تيبوكونازول عند بداية الإصابة'],
    treatmentsEn: ['Plant resistant hybrid varieties', 'Apply Mancozeb or Tebuconazole upon early onset'],
    fertilizerAr: 'سماد متوازن وتجنب الإفراط في اليوريا عند اشتداد الرطوبة.',
    fertilizerEn: 'Balanced fertilizer; avoid excess urea in high humidity.',
  ),
  'Corn_(maize)___Northern_Leaf_Blight': DiseaseDetail(
    nameAr: 'لفحة أوراق الذرة الشمالية',
    nameEn: 'Northern Corn Leaf Blight',
    cropAr: 'ذرة',
    cropEn: 'Corn',
    descriptionAr: 'بقع بيضاوية رمادية كبيرة تشبه السيجار على الأوراق وتجفف مساحات كبيرة من المجموع الخضري.',
    descriptionEn: 'Large, elliptical, cigar-shaped grayish lesions on leaves.',
    treatmentsAr: ['مبيدات فطرية جهازية (أزوكسيستروبين)', 'التخلص من بقايا المحصول السابق بحراثة عميقة'],
    treatmentsEn: ['Systemic fungicides (Azoxystrobin)', 'Deep tillage to bury previous crop debris'],
    fertilizerAr: 'تسميد فوسفوري وبوتاسي متوازن.',
    fertilizerEn: 'Balanced phosphorus and potassium fertilization.',
  ),
  'Corn_(maize)___healthy': DiseaseDetail(
    nameAr: 'نبات ذرة سليم',
    nameEn: 'Healthy Corn (Maize)',
    cropAr: 'ذرة',
    cropEn: 'Corn',
    descriptionAr: 'نبات الذرة بحالة نمو ممتازة وسليمة.',
    descriptionEn: 'Corn plants are green, healthy, and developing normally.',
    treatmentsAr: ['متابعة الري بانتظام خصوصاً في مرحلة التزهير (طرد السنابل)'],
    treatmentsEn: ['Maintain regular watering especially during silking and grain fill'],
    fertilizerAr: 'جرعات نيتروجينية (يوريا أو نترات النشادر) على دفعات متتالية.',
    fertilizerEn: 'Sequential nitrogen side-dressings (Urea or Ammonium Nitrate).',
  ),
  'Grape___Black_rot': DiseaseDetail(
    nameAr: 'العفن الأسود في العنب',
    nameEn: 'Grape Black Rot',
    cropAr: 'عنب',
    cropEn: 'Grape',
    descriptionAr: 'بقع بنية على الأوراق مع جفاف وتجعد حبات العنب وتحولها للون الأسود الصلب.',
    descriptionEn: 'Brown leaf spots and shriveling of berries into hard, black, mummified fruit.',
    treatmentsAr: ['جمع العناقيد المصابة وإتلافها فوراً', 'الرش الوقائي بمبيد ميكلوبوتانيل أو مانكوزيب'],
    treatmentsEn: ['Remove and destroy infected clusters', 'Preventative sprays of Myclobutanil or Mancozeb'],
    fertilizerAr: 'كالسيوم وبورون لتقوية قشرة الحبات ومنع تشققها.',
    fertilizerEn: 'Calcium and Boron to reinforce berry skins and prevent cracking.',
  ),
  'Grape___Esca_(Black_Measles)': DiseaseDetail(
    nameAr: 'مرض إسكا (الحصبة السوداء) في العنب',
    cropAr: 'عنب',
    cropEn: 'Grape',
    nameEn: 'Grape Esca (Black Measles)',
    descriptionAr: 'اصفرار بين عروق الأوراق يعطي مظهر جلد النمر، مع بقع داكنة على الحبات وجفاف الأغصان.',
    descriptionEn: 'Tiger-stripe interveinal leaf discoloration with dark speckling on berries.',
    treatmentsAr: ['تقليم الأفرع المصابة وتعقيم المقصات بالكحول', 'تغطية جروح التقليم بعجينة بوردو'],
    treatmentsEn: ['Prune symptomatic wood and sanitize tools', 'Protect pruning wounds with Bordeaux paste'],
    fertilizerAr: 'هيوميك أسيد ومنشطات جذور لتقليل الإجهاد الوعائي على الكرمة.',
    fertilizerEn: 'Humic acid and root biostimulants to alleviate vascular stress.',
  ),
  'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)': DiseaseDetail(
    nameAr: 'لفحة أوراق العنب (إيزاريوبسيس)',
    nameEn: 'Grape Leaf Blight (Isariopsis)',
    cropAr: 'عنب',
    cropEn: 'Grape',
    descriptionAr: 'بقع بنية داكنة غير منتظمة على الأوراق مع حواف محددة تسبب جفاف الأوراق وسقوطها.',
    descriptionEn: 'Irregular dark brown leaf spots causing premature foliage drop.',
    treatmentsAr: ['مبيدات فطرية نحاسية بعد جني المحصول وفي بداية الربيع', 'تقليم الأوراق الزائدة للتهوية'],
    treatmentsEn: ['Copper-based fungicides post-harvest and in spring', 'Canopy management for air circulation'],
    fertilizerAr: 'سلفات البوتاسيوم لتحسين صلابة ومناعة الأوراق.',
    fertilizerEn: 'Potassium sulfate to improve leaf tissue resilience.',
  ),
  'Grape___healthy': DiseaseDetail(
    nameAr: 'أوراق عنب سليمة',
    nameEn: 'Healthy Grapevine',
    cropAr: 'عنب',
    cropEn: 'Grape',
    descriptionAr: 'كرمة العنب سليمة ونضرة ولا توجد أي إصابات.',
    descriptionEn: 'Grapevine is vigorous and free from disease or insect infestation.',
    treatmentsAr: ['التقليم الأخضر وتنظيم الري بالتنقيط'],
    treatmentsEn: ['Green shoot thinning and controlled drip irrigation'],
    fertilizerAr: 'برنامج تسميد متكامل (نيتروجين في الربيع، وبوتاسيوم عند تحجيم الثمار).',
    fertilizerEn: 'Comprehensive nutrition plan (Nitrogen in spring, Potassium during berry sizing).',
  ),
  'Orange___Haunglongbing_(Citrus_greening)': DiseaseDetail(
    nameAr: 'اخضرار الحمضيات (التدهور السريع)',
    nameEn: 'Citrus Greening (Huanglongbing)',
    cropAr: 'حمضيات',
    cropEn: 'Citrus',
    descriptionAr: 'اصفرار غير متماثل في الأوراق (مظهر مبرقش) وصغر الثمار وتراجع إنتاجية الشجرة.',
    descriptionEn: 'Asymmetrical blotchy mottle leaf yellowing, bitter lopsided small fruits.',
    treatmentsAr: ['مكافحة حشرة بسيلا الحمضيات الناقلة للبكتيريا فوراً بالمبيدات الحشرية', 'إزالة الأشجار شديدة التدهور'],
    treatmentsEn: ['Aggressively control the Asian Citrus Psyllid vector', 'Eradicate severely diseased trees'],
    fertilizerAr: 'رش عناصر صغرى ورقية (زنك، منغنيز، حديد، بورون) لتخفيف الإجهاد.',
    fertilizerEn: 'Foliar micronutrient sprays (Zinc, Manganese, Iron, Boron) to alleviate decline.',
  ),
  'Peach___Bacterial_spot': DiseaseDetail(
    nameAr: 'التبقع البكتيري في الخوخ',
    nameEn: 'Peach Bacterial Spot',
    cropAr: 'خوخ',
    cropEn: 'Peach',
    descriptionAr: 'ثقوب صغيرة تشبه طلقات الرصاص على الأوراق وبقع غائرة على الثمار.',
    descriptionEn: 'Shot-hole appearance on foliage and sunken dark lesions on peach fruit.',
    treatmentsAr: ['مركبات نحاسية في موسم السكون قبل تفتح البراعم', 'استخدام مضادات بكتيرية زراعية مخصصة'],
    treatmentsEn: ['Dormant copper sprays before bud break', 'Apply registered agricultural bactericides'],
    fertilizerAr: 'تسميد معتدل وتجنب زيادة النيتروجين التي تزيد طراوة الأنسجة وسرعة اختراق البكتيريا.',
    fertilizerEn: 'Moderate fertilization; avoid excessive nitrogen that softens tissue.',
  ),
  'Peach___healthy': DiseaseDetail(
    nameAr: 'شجرة خوخ سليمة',
    nameEn: 'Healthy Peach',
    cropAr: 'خوخ',
    cropEn: 'Peach',
    descriptionAr: 'أوراق وثمار الخوخ بحالة ممتازة وخالية من الأمراض.',
    descriptionEn: 'Peach tree is thriving with clean foliage and sound fruit.',
    treatmentsAr: ['الرش الشتوي الوقائي بالزيت المعدني مع النحاس'],
    treatmentsEn: ['Preventative winter spray with mineral oil and copper'],
    fertilizerAr: 'تسميد NPK متوازن + كالسيوم لصلابة الثمار وجودة التخزين.',
    fertilizerEn: 'Balanced NPK + Calcium for fruit firmness and shelf life.',
  ),
  'Pepper,_bell___Bacterial_spot': DiseaseDetail(
    nameAr: 'التبقع البكتيري في الفلفل الحلو',
    nameEn: 'Bell Pepper Bacterial Spot',
    cropAr: 'فلفل حلو',
    cropEn: 'Bell Pepper',
    descriptionAr: 'بقع دائرية مائية تتحول للبني الداكن مع هالة صفراء على الأوراق وتلف للأزهار.',
    descriptionEn: 'Water-soaked spots turning dark brown with yellow halos; blighting of blossoms.',
    treatmentsAr: ['رش هيدروكسيد النحاس أو مانكوزيب مع النحاس', 'تجنب العمل بالحقل والنباتات رطبة بالندى'],
    treatmentsEn: ['Spray copper hydroxide mixed with Mancozeb', 'Avoid field operations when foliage is wet'],
    fertilizerAr: 'كالسيوم وبورون لتقوية جدران الخلايا النباتية.',
    fertilizerEn: 'Calcium-Boron foliar application to reinforce cellular walls.',
  ),
  'Pepper,_bell___healthy': DiseaseDetail(
    nameAr: 'نبات فلفل سليم',
    nameEn: 'Healthy Bell Pepper',
    cropAr: 'فلفل حلو',
    cropEn: 'Bell Pepper',
    descriptionAr: 'نبات الفلفل ينمو بصحة ممتازة ولا تظهر عليه أعراض مرضية.',
    descriptionEn: 'Pepper plant is healthy and producing clean foliage and blossoms.',
    treatmentsAr: ['الحفاظ على الرطوبة المعتدلة والوقاية الدورية'],
    treatmentsEn: ['Maintain moderate moisture and routine preventative pest scouting'],
    fertilizerAr: 'سماد NPK متوازن 20-20-20 وكالسيوم دوري كل 10 أيام.',
    fertilizerEn: 'Balanced NPK 20-20-20 and periodic Calcium feeds every 10 days.',
  ),
  'Potato___Early_blight': DiseaseDetail(
    nameAr: 'اللفحة المبكرة في البطاطا',
    nameEn: 'Potato Early Blight',
    cropAr: 'بطاطا',
    cropEn: 'Potato',
    descriptionAr: 'بقع بنية دائرية متحدة المركز تشبه لوحة الهدف على الأوراق السفلية.',
    descriptionEn: 'Concentric ring target-board brown spots on lower mature potato leaves.',
    treatmentsAr: ['رش مبيد فطري (كلوروثالونيل أو مانكوزيب)', 'التخلص من الأوراق السفلية المصابة الملامسة للتربة'],
    treatmentsEn: ['Fungicide sprays (Chlorothalonil or Mancozeb)', 'Remove infected lower leaves in contact with soil'],
    fertilizerAr: 'سماد عالي البوتاسيوم لتقوية الدرنات والأوراق.',
    fertilizerEn: 'High-potassium fertilizer to enhance tuber bulking and foliage endurance.',
  ),
  'Potato___Late_blight': DiseaseDetail(
    nameAr: 'اللفحة المتأخرة في البطاطا',
    nameEn: 'Potato Late Blight',
    cropAr: 'بطاطا',
    cropEn: 'Potato',
    descriptionAr: 'بقع مائية داكنة تتسع بسرعة شديدة مع طبقة بيضاء رطبة على السطح السفلي للأوراق.',
    descriptionEn: 'Rapidly spreading dark water-soaked lesions with white mold on leaf undersides.',
    treatmentsAr: ['مبيدات جهازية عاجلة (ميتالاكسيل أو سيموكسانيل)', 'وقف الري الرذاذي وتقليل الرطوبة فوراً'],
    treatmentsEn: ['Urgent systemic fungicides (Metalaxyl or Cymoxanil)', 'Cease overhead watering to lower humidity'],
    fertilizerAr: 'فوسفيت البوتاسيوم لرفع المناعة المكتسبة للنبات.',
    fertilizerEn: 'Potassium Phosphite to activate systemic acquired resistance (SAR).',
  ),
  'Potato___healthy': DiseaseDetail(
    nameAr: 'نبات بطاطا سليم',
    nameEn: 'Healthy Potato',
    cropAr: 'بطاطا',
    cropEn: 'Potato',
    descriptionAr: 'مجموع خضري ممتاز وخالٍ من الإصابات الفطرية والحشرية.',
    descriptionEn: 'Vibrant, healthy potato canopy with no disease or pest damage.',
    treatmentsAr: ['تغطية الدرنات بالتربة جيداً (التحضين) وتنظيم الري'],
    treatmentsEn: ['Proper hilling to shield tubers from sunlight and blight spores'],
    fertilizerAr: 'سماد عالي الفوسفور في البداية ثم عالي البوتاسيوم لتحجيم الدرنات.',
    fertilizerEn: 'High phosphorus for root establishment, transitioning to high potassium for tuber sizing.',
  ),
  'Raspberry___healthy': DiseaseDetail(
    nameAr: 'توت العليق سليم',
    nameEn: 'Healthy Raspberry',
    cropAr: 'توت العليق',
    cropEn: 'Raspberry',
    descriptionAr: 'النبات سليم وجيد النمو.',
    descriptionEn: 'Raspberry canes are healthy with vigorous vegetative development.',
    treatmentsAr: ['تقليم القصبات القديمة بعد الإثمار والتهوية الجيدة'],
    treatmentsEn: ['Prune old floricanes post-harvest to encourage air circulation'],
    fertilizerAr: 'سماد عضوي وNPK متوازن.',
    fertilizerEn: 'Organic compost and balanced NPK fertilizer.',
  ),
  'Soybean___healthy': DiseaseDetail(
    nameAr: 'فول الصويا سليم',
    nameEn: 'Healthy Soybean',
    cropAr: 'فول صويا',
    cropEn: 'Soybean',
    descriptionAr: 'نبات سليم ومعافى.',
    descriptionEn: 'Soybean crop is thriving with healthy symbiotic nitrogen fixation.',
    treatmentsAr: ['مراقبة الآفات الحشرية والري المنتظم'],
    treatmentsEn: ['Routine insect monitoring and timely irrigation'],
    fertilizerAr: 'سماد فوسفوري وبوتاسي (النبات يثبت النيتروجين حيوياً من الجو).',
    fertilizerEn: 'Phosphorus and potassium fertilization (nodules fix biological nitrogen).',
  ),
  'Squash___Powdery_mildew': DiseaseDetail(
    nameAr: 'البياض الدقيقي في الكوسا والقرع',
    nameEn: 'Squash Powdery Mildew',
    cropAr: 'كوسا وقرع',
    cropEn: 'Squash / Pumpkin',
    descriptionAr: 'بودرة بيضاء دقيقة تشبه الطحين تغطي الأوراق وتؤدي لجفافها واصفرارها وموتها.',
    descriptionEn: 'White powdery fungal growth covering leaf surfaces causing yellowing and senescence.',
    treatmentsAr: ['رش مبيد فطري مخصص للبياض الدقيقي (بينكونازول أو تريفلوكسيستروبين)', 'رش محلول بيكربونات البوتاسيوم مخفف'],
    treatmentsEn: ['Fungicide sprays (Penconazole or Trifloxystrobin)', 'Foliar spray with diluted Potassium Bicarbonate'],
    fertilizerAr: 'سماد سيليكات البوتاسيوم لتقوية بشرة الورقة ومنع اختراق ميسليوم الفطر.',
    fertilizerEn: 'Potassium Silicate to thicken epidermis and deter fungal penetration.',
  ),
  'Strawberry___Leaf_scorch': DiseaseDetail(
    nameAr: 'حرق أوراق الفراولة',
    nameEn: 'Strawberry Leaf Scorch',
    cropAr: 'فراولة',
    cropEn: 'Strawberry',
    descriptionAr: 'بقع بنفسجية إلى بنية داكنة تغطي الأوراق حتى تجعلها تبدو كالمحترقة وتضعف المحصول.',
    descriptionEn: 'Purplish-brown angular spots coalescing and causing leaves to appear scorched.',
    treatmentsAr: ['إزالة الأوراق المحترقة بعد الحصاد', 'رش مبيدات فطرية وقائية نحاسية'],
    treatmentsEn: ['Remove scorched foliage after harvest', 'Apply preventative copper-based sprays'],
    fertilizerAr: 'تسميد كالسيوم ومغنيسيوم لتجديد المجموع الخضري وتقوية البراعم.',
    fertilizerEn: 'Calcium and Magnesium to regenerate leaf area and root crowns.',
  ),
  'Strawberry___healthy': DiseaseDetail(
    nameAr: 'نبات فراولة سليم',
    nameEn: 'Healthy Strawberry',
    cropAr: 'فراولة',
    cropEn: 'Strawberry',
    descriptionAr: 'نبات الفراولة سليم ونضر وثماره ممتازة.',
    descriptionEn: 'Strawberry plant is robust with clean foliage and strong runner growth.',
    treatmentsAr: ['فرش قش أو بلاستيك ملش تحت الثمار لمنع ملامسة التربة'],
    treatmentsEn: ['Maintain straw or plastic mulch to keep fruit off wet soil'],
    fertilizerAr: 'سماد NPK متوازن + بورون لزيادة عقد الثمار ونسبة السكر.',
    fertilizerEn: 'Balanced NPK + Boron to boost fruit set, sweetness, and uniform shape.',
  ),
  'Tomato___Bacterial_spot': DiseaseDetail(
    nameAr: 'التبقع البكتيري في الطماطم (البندورة)',
    nameEn: 'Tomato Bacterial Spot',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'بقع صغيرة مائية مسودة على الأوراق والثمار محاطة بهالة صفراء مميزة.',
    descriptionEn: 'Small water-soaked dark brown leaf spots with distinct yellow halos.',
    treatmentsAr: ['رش مركبات النحاس المخلبي مع مانكوزيب', 'تجنب الري العلوي واستخدام الري بالتنقيط'],
    treatmentsEn: ['Spray chelated copper combined with Mancozeb', 'Use drip irrigation and avoid overhead wetting'],
    fertilizerAr: 'تسميد بوتاسي لتقوية الجدران الخلوية وتجنب زيادة اليوريا.',
    fertilizerEn: 'Potassium application for cell wall strength; avoid excessive urea.',
  ),
  'Tomato___Early_blight': DiseaseDetail(
    nameAr: 'اللفحة المبكرة في الطماطم (البندورة)',
    nameEn: 'Tomato Early Blight',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'حلقات دائرية متحدة المركز بنية على الأوراق السفلية تجعلها تجف وتسقط.',
    descriptionEn: 'Concentric target-like brown rings on lower foliage leading to defoliation.',
    treatmentsAr: ['إزالة الأوراق السفلية الملامسة للتربة (التوريق)', 'رش مبيد دايفينوكونازول أو كلوروثالونيل'],
    treatmentsEn: ['Prune off lower soil-touching leaves', 'Apply Difenoconazole or Chlorothalonil fungicide'],
    fertilizerAr: 'سماد NPK 12-12-36 عالي البوتاسيوم لتقوية النبات وتحجيم الثمار.',
    fertilizerEn: 'High potassium NPK 12-12-36 for plant vigor and fruit sizing.',
  ),
  'Tomato___Late_blight': DiseaseDetail(
    nameAr: 'اللفحة المتأخرة في الطماطم (البندورة)',
    nameEn: 'Tomato Late Blight',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'بقع زيتية رمادية مائية سريعة الانتشار على الأوراق والسيقان والثمار في الأجواء الرطبة والباردة.',
    descriptionEn: 'Aggressive oily gray-green lesions on leaves and stems with white mold in humid weather.',
    treatmentsAr: ['رش مبيد جهازي عاجل (مانكوزيب + سيموكسانيل أو ميتالاكسيل)', 'تهوية البيوت البلاستيكية فوراً وتقليل الرطوبة'],
    treatmentsEn: ['Urgent systemic fungicide (Mancozeb + Cymoxanil / Metalaxyl)', 'Ventilate greenhouses to lower ambient humidity'],
    fertilizerAr: 'فوسفيت البوتاسيوم لتحفيز المقاومة الجهازية الذاتية في النبات.',
    fertilizerEn: 'Potassium Phosphite to stimulate natural immune defense mechanisms.',
  ),
  'Tomato___Leaf_Mold': DiseaseDetail(
    nameAr: 'عفن الأوراق في الطماطم (البندورة)',
    nameEn: 'Tomato Leaf Mold',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'بقع صفراء باهتة على السطح العلوي يقابلها نمو مخملي رمادي أو زيتوني على السطح السفلي.',
    descriptionEn: 'Pale yellow spots on upper leaf surfaces with olive-green velvety mold underneath.',
    treatmentsAr: ['خفض الرطوبة داخل البيت البلاستيكي بالتهوية المستمرة', 'رش مبيد فطري وقائي نحاسي'],
    treatmentsEn: ['Lower greenhouse humidity with active ventilation', 'Apply preventative copper fungicide'],
    fertilizerAr: 'تسميد كالسيوم ومغنيسيوم لتعزيز سماكة الأوراق.',
    fertilizerEn: 'Calcium and Magnesium feeds to boost leaf thickness and photosynthesis.',
  ),
  'Tomato___Septoria_leaf_spot': DiseaseDetail(
    nameAr: 'تبقع أوراق سبتوريا في الطماطم',
    nameEn: 'Tomato Septoria Leaf Spot',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'بقع دائرية صغيرة عديدة رمادية المركز مع حواف بنية داكنة ونقاط سوداء دقيقة بداخلها.',
    descriptionEn: 'Numerous small circular spots with grayish centers, dark brown borders, and tiny black dots.',
    treatmentsAr: ['إزالة الأوراق المصابة والتخلص منها', 'استخدام مبيد فطري كلوروثالونيل أو مانكوزيب'],
    treatmentsEn: ['Remove and destroy infected lower leaves', 'Apply Chlorothalonil or Mancozeb fungicide'],
    fertilizerAr: 'سماد متوازن وتجنب الإفراط في الري ومراعاة التهوية.',
    fertilizerEn: 'Balanced nutrition, avoiding overwatering and ensuring plant spacing.',
  ),
  'Tomato___Spider_mites Two-spotted_spider_mite': DiseaseDetail(
    nameAr: 'العناكب الحمراء (حلم الغبار) في الطماطم',
    nameEn: 'Two-Spotted Spider Mite on Tomato',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'نقط صفراء دقيقة جداً ومتقاربة مع وجود خيوط عنكبوتية رفيعة على السطح السفلي للورقة.',
    descriptionEn: 'Fine yellow stippling on leaves with fine silken webbing on leaf undersides.',
    treatmentsAr: ['رش مبيد أكاروسي متخصص (أبامكتين أو بروبارجيت)', 'غسيل النباتات بالماء لتقليل الغبار الذي ينعش العنكبوت'],
    treatmentsEn: ['Apply specialized miticide (Abamectin or Propargite)', 'Water misting to suppress dust-loving mite populations'],
    fertilizerAr: 'سماد ورقي مغنيسيوم وحديد لتعويض النقص في صبغة الكلوروفيل.',
    fertilizerEn: 'Foliar Magnesium and Iron to restore damaged chlorophyll pigments.',
  ),
  'Tomato___Target_Spot': DiseaseDetail(
    nameAr: 'التبقع المستهدف (تارجت سبوت) في الطماطم',
    nameEn: 'Tomato Target Spot',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'بقع بنية محددة تشبه لوحة التصويب تسبب تساقط الأوراق وتلف الثمار.',
    descriptionEn: 'Brown circular target-like lesions on foliage and sunken spots on tomato fruit.',
    treatmentsAr: ['رش مبيد أزوكسيستروبين أو كابريو ديو', 'تحسين حركة الهواء بين الشتلات'],
    treatmentsEn: ['Spray Azoxystrobin or Cabrio Duo fungicide', 'Improve canopy air movement'],
    fertilizerAr: 'سماد متوازن NPK مع كالسيوم بورون.',
    fertilizerEn: 'Balanced NPK with Calcium-Boron supplement.',
  ),
  'Tomato___Tomato_Yellow_Leaf_Curl_Virus': DiseaseDetail(
    nameAr: 'فيروس تجعد واصفرار أوراق الطماطم (TYLCV)',
    nameEn: 'Tomato Yellow Leaf Curl Virus (TYLCV)',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'تقزم شديد للنبات وتجعد الأوراق للأعلى مع اصفرار حوافها وصغر حجم الثمار أو انعدامها.',
    descriptionEn: 'Severe stunting, upward leaf curling, yellow margins, and flower abortion.',
    treatmentsAr: ['مكافحة الذبابة البيضاء الناقلة للفيروس بشدة (مبيد أسيتامبريد أو إيميداكلوبريد)', 'قلع النباتات المصابة مبكراً لتقليل العدوى'],
    treatmentsEn: ['Aggressive whitefly vector control (Acetamiprid or Imidacloprid)', 'Rogue out infected plants immediately'],
    fertilizerAr: 'أحماض أمينية + عناصر صغرى وزنك لمساعدة النبات على تحمل الإجهاد ومواصلة النمو.',
    fertilizerEn: 'Amino acids + zinc and micronutrients to alleviate viral stress.',
  ),
  'Tomato___Tomato_mosaic_virus': DiseaseDetail(
    nameAr: 'فيروس موزايك الطماطم (TMV)',
    nameEn: 'Tomato Mosaic Virus (TMV)',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'تبقع وتبرقش فاتح وداكن كالموزاييك على الأوراق وتشوه نصل الورقة إلى مظهر شريطي ضيق.',
    descriptionEn: 'Mottled light and dark green mosaic patterns on foliage, strap-like leaf distortion.',
    treatmentsAr: ['تعقيم الأيدي والأدوات بالحليب منزوع الدسم أو الصابون', 'قلع النبات المصاب والتخلص منه'],
    treatmentsEn: ['Sanitize hands and pruners with skim milk or soap', 'Eradicate and burn infected plants'],
    fertilizerAr: 'منشطات حيوية وهيوميك أسيد لدعم كفاءة المجموع الجذري.',
    fertilizerEn: 'Biostimulants and Humic Acid to support root vigor.',
  ),
  'Tomato___healthy': DiseaseDetail(
    nameAr: 'نبات طماطم (بندورة) سليم',
    nameEn: 'Healthy Tomato Plant',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'نبات الطماطم سليم وبحالة ممتازة وخالٍ من الأمراض والآفات.',
    descriptionEn: 'Tomato plant is robust, vigorous, with vibrant green foliage and clean stems.',
    treatmentsAr: ['الاستمرار في الرش الوقائي الدوري والري المنتظم بالتنقيط'],
    treatmentsEn: ['Maintain standard preventative spray schedule and drip irrigation'],
    fertilizerAr: 'برنامج تسميد NPK متوازن (عالي الفوسفور للتجذير، متوازن للنمو، عالي البوتاسيوم للتحجيم).',
    fertilizerEn: 'Balanced NPK regime (High-P for rooting, Balanced for growth, High-K for sizing).',
  ),
};

class PlantDoctorScreen extends StatefulWidget {
  final bool isArabic;
  const PlantDoctorScreen({super.key, this.isArabic = true});

  @override
  State<PlantDoctorScreen> createState() => _PlantDoctorScreenState();
}

class _PlantDoctorScreenState extends State<PlantDoctorScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final PlantDiseaseService _diseaseService = PlantDiseaseService();
  final TextEditingController _notesController = TextEditingController();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoadingModel = true;
  bool _isClassifying = false;
  String? _statusMessage;
  String? _predictedLabel;
  double? _confidence;

  Map<String, dynamic>? _diseaseResult;
  String? _symptomAnalysisNote;
  String? _customFertilizerAdvice;

  List<int> _inputShape = [1, 224, 224, 3];
  int _numClasses = 38;

  List<({String ar, String en})> get _quickSymptoms => const [
    (ar: 'توقف النمو / نفس الحجم منذ شهر', en: 'Stunted growth / same size for a month'),
    (ar: 'اصفرار الأوراق السفلية', en: 'Yellowing of lower leaves'),
    (ar: 'اصفرار القمم الحديثة مع بقاء العروق خضراء', en: 'Yellow young leaves with green veins (Iron Chlorosis)'),
    (ar: 'احتراق وجفاف حواف الأوراق', en: 'Scorched / burned leaf edges'),
    (ar: 'تساقط الأزهار والثمار الصغيرة', en: 'Flower and small fruit dropping'),
    (ar: 'سواد وتعفن أسفل الساق أو الجذور', en: 'Black stem / root rot'),
    (ar: 'ذبول في منتصف النهار', en: 'Midday wilting'),
    (ar: 'ضعف التحجيم وصغر الثمار', en: 'Poor fruit sizing'),
  ];

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      _inputShape = List<int>.from(inputTensor.shape);
      final outShape = outputTensor.shape;
      _numClasses = outShape.isNotEmpty ? outShape.last : 38;

      final String response = await rootBundle.loadString('assets/labels.json');
      final data = json.decode(response);
      final loaded = List<String>.from(data);

      if (!mounted) return;
      setState(() {
        _labels = loaded;
        _isLoadingModel = false;
        _statusMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingModel = false;
        _statusMessage = widget.isArabic ? 'تعذر تحميل النموذج: $e' : 'Failed to load model: $e';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _diseaseResult = null;
      _predictedLabel = null;
      _confidence = null;
      _statusMessage = null;
      _symptomAnalysisNote = null;
      _customFertilizerAdvice = null;
    });

    await _classifyAndDiagnose();
  }

  /// محرك ذكي لتحليل ملاحظات وأعراض المزارع وتحديد نقص العناصر والسماد الأنسب
  ({String analysis, String fertilizer, String treatment}) _analyzeFarmerNotes(String notes, bool isAr) {
    String text = notes.toLowerCase();

    if (text.contains('نفس الحجم') || text.contains('توقف النمو') || text.contains('بطء النمو') || text.contains('تقزم') || text.contains('stunted') || text.contains('growth') || text.contains('size')) {
      return (
        analysis: isAr 
            ? '🔍 تحليل الملاحظة: توقف نمو النبات وثبات حجمه يدل غالباً على ضعف المجموع الجذري، نقص عنصر الفوسفور، أو برودة/انضغاط التربة.'
            : '🔍 Observation Analysis: Stunted growth often indicates root stress, Phosphorus deficiency, or compacted/cold soil.',
        fertilizer: isAr
            ? '🌱 السماد الموصى به: سماد عالي الفوسفور (NPK 10-52-10 أو MAP مونو أمونيوم فوسفات) بمعدل 2-3 كغم/دونم + سقاية هيوميك أسيد (Humic Acid) لتنشيط الجذور وتفكيك التربة.'
            : '🌱 Recommended Fertilizer: High-Phosphorus fertilizer (NPK 10-52-10 or MAP) + Humic Acid root drench.',
        treatment: isAr
            ? 'فحص جذور النبات للتأكد من خلوها من النيماتودا أو الأعفان، وتنظيم فترات الري وتجنب التغريق.'
            : 'Inspect root system for nematodes/rot and regulate irrigation schedule.',
      );
    } else if (text.contains('اصفرار الأوراق السفلية') || text.contains('lower') || (text.contains('اصفرار') && text.contains('تحت'))) {
      return (
        analysis: isAr
            ? '🔍 تحليل الملاحظة: اصفرار الأوراق القديمة والسفلية علامة كلاسيكية على نقص عنصر النيتروجين (الآزوت) أو إجهاد مائي ناتج عن زيادة الري.'
            : '🔍 Observation Analysis: Yellowing of lower/older leaves is a classic sign of Nitrogen deficiency or overwatering stress.',
        fertilizer: isAr
            ? '🌱 السماد الموصى به: سماد نيتروجيني متوازن NPK 20-20-20 أو نترات الكالسيوم أو يوريا مخففة.'
            : '🌱 Recommended Fertilizer: Balanced Nitrogen fertilizer NPK 20-20-20 or Calcium Nitrate.',
        treatment: isAr
            ? 'تقليل كميات مياه الري وتنظيمها، والتسميد على دفعات صغيرة منتظمة.'
            : 'Reduce irrigation volume and apply fertilizer in frequent small doses.',
      );
    } else if (text.contains('عروق خضراء') || text.contains('veins') || text.contains('iron') || text.contains('حديد') || text.contains('قمم')) {
      return (
        analysis: isAr
            ? '🔍 تحليل الملاحظة: اصفرار الأوراق الحديثة العلوية مع بقاء العروق خضراء يدل على نقص عنصر الحديد (Iron Chlorosis) بسبب قلوية التربة.'
            : '🔍 Observation Analysis: Interveinal chlorosis on young upper leaves indicates Iron deficiency due to high soil pH.',
        fertilizer: isAr
            ? '🌱 السماد الموصى به: شيلات حديد (EDDHA Iron 6%) بمعدل 5-10 غرام لكل شجرة/شتلة مع مياه الري، أو رش ورقي بشيلات EDTA.'
            : '🌱 Recommended Fertilizer: Chelated Iron (EDDHA Iron 6%) soil drench or EDTA Iron foliar spray.',
        treatment: isAr
            ? 'إضافة حمض الفوسفوريك أو الكبريت الزراعي لخفض قلوية التربة وتسهيل امتصاص العناصر.'
            : 'Apply agricultural sulfur or phosphoric acid to lower root-zone soil pH.',
      );
    } else if (text.contains('احتراق') || text.contains('حواف') || text.contains('edge') || text.contains('scorch') || text.contains('burn')) {
      return (
        analysis: isAr
            ? '🔍 تحليل الملاحظة: احتراق حواف الأوراق والتفافها يعكس نقص عنصر البوتاسيوم أو ارتفاع ملوحة مياه الري والتربة.'
            : '🔍 Observation Analysis: Marginal leaf burn indicates Potassium deficiency or elevated soil/water salinity.',
        fertilizer: isAr
            ? '🌱 السماد الموصى به: سلفات البوتاسيوم (0-0-50) أو نترات البوتاسيوم، مع معالج ملوحة (كالسيوم سائل).'
            : '🌱 Recommended Fertilizer: Potassium Sulfate (0-0-50) or Potassium Nitrate with liquid calcium flush.',
        treatment: isAr
            ? 'غسيل التربة برية غزيرة للتخلص من تراكم الأملاح حول الجذور.'
            : 'Perform a heavy leaching irrigation to flush accumulated root-zone salts.',
      );
    } else if (text.contains('تساقط') || text.contains('أزهار') || text.contains('ثمار') || text.contains('flower') || text.contains('drop')) {
      return (
        analysis: isAr
            ? '🔍 تحليل الملاحظة: تساقط الأزهار والعقد الصغير ينتج عن نقص عنصري الكالسيوم والبورون أو تذبذب درجات الحرارة والري أثناء التزهير.'
            : '🔍 Observation Analysis: Blossom drop is triggered by Calcium-Boron deficiency or temperature/water fluctuations.',
        fertilizer: isAr
            ? '🌱 السماد الموصى به: رش سماد كالسيوم-بورون سائل (Cal-Bor) بمعدل 1.5 مل/لتر وقت التزهير والعقد.'
            : '🌱 Recommended Fertilizer: Liquid Calcium-Boron (Cal-Bor) foliar spray at 1.5 ml/L during bloom.',
        treatment: isAr
            ? 'تجنب التعطيش أو التغريق في مرحلة التزهير، والامتناع عن رش المبيدات الحشرية أثناء نشاط النحل.'
            : 'Avoid water stress during blooming and halt insecticide sprays during pollinator activity.',
      );
    } else if (text.contains('عفن') || text.contains('سواد') || text.contains('rot') || text.contains('black') || text.contains('ساق')) {
      return (
        analysis: isAr
            ? '🔍 تحليل الملاحظة: سواد أسفل الساق وتعفن الجذور دليل على الإصابة بأعفان الجذور الفطرية بسبب فرط الرطوبة.'
            : '🔍 Observation Analysis: Blackened collar and root rot indicate fungal pathogens from excess soil moisture.',
        fertilizer: isAr
            ? '🌱 السماد الموصى به: إيقاف التسميد مؤقتاً وسقاية منشط مناعة نباتية فوسفيت بوتاسيوم بعد العلاج.'
            : '🌱 Recommended Fertilizer: Pause fertilizer; apply Potassium Phosphite immune booster post-recovery.',
        treatment: isAr
            ? 'تعطيش النبات فوراً وسقاية مبيد فطري جهازي متخصص للأعفان (مثل هيمكسازول أو ميتالاكسيل).'
            : 'Withhold water immediately and drench with systemic root-rot fungicide (Hymexazol / Metalaxyl).',
      );
    }

    return (
      analysis: isAr
          ? '🔍 ملاحظة المزارع المرفقة: "${notes.trim()}" — تم أخذ هذه الملاحظة بالاعتبار ضمن خطة الرعاية.'
          : '🔍 Farmer Observation: "${notes.trim()}" — incorporated into care guidelines.',
      fertilizer: isAr
          ? '🌱 السماد العام الموصى به: سماد NPK متوازن 20-20-20 بمعدل منتظم لدعم النمو الشامل.'
          : '🌱 General Fertilizer: Balanced NPK 20-20-20 to support overall vegetative health.',
      treatment: isAr
          ? 'مراقبة تطور النبات والتأكد من ضبط معدلات الري والتهوية.'
          : 'Monitor foliage and ensure optimal moisture and airflow.',
    );
  }

  Future<void> _classifyAndDiagnose() async {
    if (_isClassifying) return;
    final isAr = widget.isArabic;

    if (_interpreter == null) {
      await _loadModelAndLabels();
    }
    if (_interpreter == null) {
      if (!mounted) return;
      setState(() => _statusMessage = isAr ? 'النموذج غير جاهز بعد.' : 'Model not ready yet.');
      return;
    }
    if (_image == null) {
      if (!mounted) return;
      setState(() => _statusMessage = isAr ? 'الرجاء اختيار أو التقاط صورة أولاً.' : 'Please select an image first.');
      return;
    }

    setState(() {
      _isClassifying = true;
      _statusMessage = isAr ? 'جاري تحليل الصورة والملاحظات بالذكاء الاصطناعي...' : 'Analyzing image & symptoms with AI...';
      _diseaseResult = null;
    });

    try {
      final imageBytes = await _image!.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        throw Exception(isAr ? 'تعذر قراءة ملف الصورة' : 'Could not decode image');
      }

      final height = _inputShape.length >= 3 ? _inputShape[1] : 224;
      final width = _inputShape.length >= 3 ? _inputShape[2] : 224;

      final input = _imageToFloat32Tensor(decoded, width, height);
      final output = List.filled(1 * _numClasses, 0.0).reshape([1, _numClasses]);

      _interpreter!.run(input, output);

      final result = List<double>.from(
        (output[0] as List).map((e) => (e as num).toDouble()),
      );

      int maxIndex = 0;
      double maxVal = result[0];
      for (int i = 1; i < result.length; i++) {
        if (result[i] > maxVal) {
          maxVal = result[i];
          maxIndex = i;
        }
      }

      final diseaseRawKey = (maxIndex < _labels.length) ? _labels[maxIndex] : 'Disease_$maxIndex';

      final bilingualInfo = kPlantDiseasesBilingual[diseaseRawKey];
      Map<String, dynamic> finalData = {};

      String diseaseAr = diseaseRawKey;
      String diseaseEn = diseaseRawKey;
      String cropNameAr = isAr ? 'نبات' : 'Plant';
      String cropNameEn = 'Plant';

      if (bilingualInfo != null) {
        diseaseAr = bilingualInfo.nameAr;
        diseaseEn = bilingualInfo.nameEn;
        cropNameAr = bilingualInfo.cropAr;
        cropNameEn = bilingualInfo.cropEn;

        finalData = {
          'name': isAr ? bilingualInfo.nameAr : bilingualInfo.nameEn,
          'crop': isAr ? bilingualInfo.cropAr : bilingualInfo.cropEn,
          'description': isAr ? bilingualInfo.descriptionAr : bilingualInfo.descriptionEn,
          'treatments': isAr ? List<String>.from(bilingualInfo.treatmentsAr) : List<String>.from(bilingualInfo.treatmentsEn),
          'fertilizer': isAr ? bilingualInfo.fertilizerAr : bilingualInfo.fertilizerEn,
        };
      } else {
        final lookupResult = await _diseaseService.lookup(diseaseRawKey);
        finalData = lookupResult.data;
      }

      String? customAnalysis;
      String? customFert;
      if (_notesController.text.trim().isNotEmpty) {
        final noteResult = _analyzeFarmerNotes(_notesController.text.trim(), isAr);
        customAnalysis = noteResult.analysis;
        customFert = noteResult.fertilizer;
        if (noteResult.treatment.isNotEmpty && finalData['treatments'] is List) {
          (finalData['treatments'] as List).insert(0, noteResult.treatment);
        }
      }

      // حفظ التشخيص تلقائياً في السجل التاريخي لقاعدة البيانات
      final farmCode = FarmSessionService.currentFarmCode;
      if (farmCode.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('diagnosis_history').add({
            'farm_code': farmCode,
            'crop_name_ar': cropNameAr,
            'crop_name_en': cropNameEn,
            'disease_name_ar': diseaseAr,
            'disease_name_en': diseaseEn,
            'disease_raw_key': diseaseRawKey,
            'confidence': maxVal,
            'notes': _notesController.text.trim(),
            'fertilizer': customFert ?? finalData['fertilizer'],
            'treatments': finalData['treatments'],
            'createdAt': FieldValue.serverTimestamp(),
          });

          // إرسال إشعار للمزرعة إذا تم تشخيص مرض
          if (!diseaseRawKey.contains('healthy')) {
            await FarmNotificationService.notifyDiseaseDetected(
              isAr ? cropNameAr : cropNameEn,
              diseaseAr,
              diseaseEn,
              farmCode,
            );
          }
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _predictedLabel = diseaseRawKey;
        _confidence = maxVal;
        _diseaseResult = finalData;
        _symptomAnalysisNote = customAnalysis;
        _customFertilizerAdvice = customFert;
        _isClassifying = false;
        _statusMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isClassifying = false;
        _statusMessage = isAr ? 'فشل التحليل: $e' : 'Analysis failed: $e';
      });
    }
  }

  Object _imageToFloat32Tensor(img.Image image, int width, int height) {
    final resized = img.copyResize(image, width: width, height: height);
    final floats = Float32List(1 * height * width * 3);
    var i = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = resized.getPixel(x, y);
        floats[i++] = (pixel.r.toDouble() - 127.5) / 127.5;
        floats[i++] = (pixel.g.toDouble() - 127.5) / 127.5;
        floats[i++] = (pixel.b.toDouble() - 127.5) / 127.5;
      }
    }
    return floats.reshape([1, height, width, 3]);
  }

  String _formatTreatments(dynamic treatments, bool isAr) {
    if (treatments == null) return isAr ? 'لا توجد علاجات مسجّلة' : 'No recorded treatments';
    if (treatments is List) {
      if (treatments.isEmpty) return isAr ? 'لا توجد علاجات مسجّلة' : 'No recorded treatments';
      return treatments.map((e) => '• $e').join('\n');
    }
    return treatments.toString();
  }

  void _showDiagnosisHistoryBottomSheet(BuildContext ctx, bool isAr) {
    final farmCode = FarmSessionService.currentFarmCode;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? '📋 سجل الفحوصات والتشخيصات السابقة' : '📋 Past Diagnosis History',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('diagnosis_history')
                        .where('farm_code', isEqualTo: farmCode.isEmpty ? 'FARM-DEFAULT' : farmCode)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                      }

                      var docs = snapshot.hasData ? snapshot.data!.docs : [];

                      docs.sort((a, b) {
                        final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                        final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return bTime.compareTo(aTime);
                      });

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                isAr ? 'لا توجد فحوصات سابقة مسجلة' : 'No recorded scan history yet',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, idx) {
                          final d = docs[idx].data() as Map<String, dynamic>;
                          final diseaseName = isAr ? (d['disease_name_ar'] ?? d['disease_raw_key']) : (d['disease_name_en'] ?? d['disease_raw_key']);
                          final crop = isAr ? (d['crop_name_ar'] ?? 'محصول') : (d['crop_name_en'] ?? 'Crop');
                          final double conf = (d['confidence'] is num) ? (d['confidence'] as num).toDouble() : 0.85;
                          final notes = d['notes']?.toString() ?? '';
                          final fert = d['fertilizer']?.toString() ?? '';
                          final Timestamp? ts = d['createdAt'] as Timestamp?;

                          String dateStr = '';
                          if (ts != null) {
                            final dt = ts.toDate();
                            dateStr = "${dt.year}/${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                          }

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ExpansionTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 22),
                              ),
                              title: Text(
                                "$crop: $diseaseName",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              subtitle: Text(
                                "$dateStr · ${isAr ? 'دقة' : 'Conf'}: ${(conf * 100).toStringAsFixed(0)}%",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (notes.isNotEmpty) ...[
                                        Text(isAr ? '📝 ملاحظات المزارع: $notes' : '📝 Notes: $notes', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                        const SizedBox(height: 6),
                                      ],
                                      if (fert.isNotEmpty) ...[
                                        Text(isAr ? '🌱 السماد الموصى به: $fert' : '🌱 Recommended Fertilizer: $fert', style: TextStyle(fontSize: 12, color: Colors.green.shade900, fontWeight: FontWeight.bold)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    bool isLowConfidence = _confidence != null && _confidence! < 0.35;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9F7),
        appBar: AppBar(
          title: Text(
            isAr ? 'طبيب النبات والتشخيص الذكي' : 'AI Plant Doctor Diagnosis',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Color(0xFF2E7D32)),
              tooltip: isAr ? 'سجل الفحوصات السابقة' : 'Past Scans History',
              onPressed: () => _showDiagnosisHistoryBottomSheet(context, isAr),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. بطاقة الهيدر الترحيبية
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.white, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'تشخيص أمراض النبات ونقص العناصر' : 'Plant Disease & Nutrient Diagnosis',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? 'التقط صورة مقربة لورقة النبات واكتب أي أعراض للحصول على السماد والعلاج الأنسب.'
                                : 'Snap a close leaf photo and type any symptoms to receive tailored fertilizer & care.',
                            style: TextStyle(color: Colors.green.shade100, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. بطاقة الصورة الملتقطة
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _image == null
                        ? Container(
                            height: 190,
                            width: double.infinity,
                            color: Colors.white,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.green.shade400),
                                const SizedBox(height: 10),
                                Text(
                                  isAr ? 'التقط صورة لورقة النبات أو اختر من المعرض' : 'Snap a leaf photo or pick from gallery',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAr ? '💡 نصيحة: صوّر الورقة عن قرب للحصول على أعلى دقة' : '💡 Tip: Take a close-up photo of the leaf for best accuracy',
                                  style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.file(
                                _image!,
                                height: 230,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _image = null;
                                        _diseaseResult = null;
                                        _predictedLabel = null;
                                        _confidence = null;
                                        _statusMessage = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side: BorderSide(color: Colors.green.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isClassifying ? null : () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: Text(isAr ? 'كاميرا' : 'Camera'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal.shade800,
                                side: BorderSide(color: Colors.teal.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isClassifying ? null : () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: Text(isAr ? 'معرض الصور' : 'Gallery'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. خانة ملاحظات وأعراض المزارع
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'ملاحظات وأعراض إضافية (اختياري):' : 'Additional Symptoms & Notes (Optional):',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'مثال: النبتة لها شهر نفس الحجم، أو الأوراق السفلية صفراء...'
                            : 'e.g. Same size for a month, yellow lower leaves, flower dropping...',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: isAr
                              ? 'اكتب هنا ما تلاحظه على النبتة ولم تلتقطه الصورة...'
                              : 'Describe observations not visible in the photo...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAr ? 'أعراض شائعة جاهزة للضغط:' : 'Quick Symptom Tags:',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _quickSymptoms.map((symptom) {
                          return ActionChip(
                            label: Text(isAr ? symptom.ar : symptom.en, style: const TextStyle(fontSize: 10)),
                            backgroundColor: const Color(0xFFE8F5E9),
                            side: BorderSide(color: Colors.green.shade200),
                            onPressed: () {
                              final text = isAr ? symptom.ar : symptom.en;
                              if (_notesController.text.isEmpty) {
                                _notesController.text = text;
                              } else {
                                _notesController.text += isAr ? '، $text' : ', $text';
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // زر بدء الفحص
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: (_isClassifying || _image == null) ? null : _classifyAndDiagnose,
                  icon: _isClassifying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    _isClassifying
                        ? (isAr ? 'جاري الفحص الدقيق...' : 'Diagnosing...')
                        : (isAr ? 'تشخيص الحالة وإيجاد السماد المناسب' : 'Diagnose & Get Fertilizer Plan'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // رسائل الحالة والتحميل
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _statusMessage!.startsWith('فشل') || _statusMessage!.startsWith('Failed')
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _statusMessage!.startsWith('فشل') || _statusMessage!.startsWith('Failed') ? Colors.red.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _statusMessage!.startsWith('فشل') || _statusMessage!.startsWith('Failed') ? Colors.red.shade800 : Colors.orange.shade900,
                    ),
                  ),
                ),

              // 4. بطاقة نتائج التشخيص المتكاملة
              if (_diseaseResult != null) ...[
                if (isLowConfidence)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade800, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr
                                    ? 'تنبيه: دقة قراءة الصورة منخفضة (${(_confidence! * 100).toStringAsFixed(1)}%)'
                                    : 'Notice: Low image confidence score (${(_confidence! * 100).toStringAsFixed(1)}%)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAr
                                    ? 'النموذج مدرب أساساً على أوراق النبات المقربة. تم الاستناد لملاحظاتك لإعطاء أفضل توصية سمادية.'
                                    : 'The vision model is trained on close leaf images. Symptoms notes were used to provide optimal nutrition advice.',
                                style: TextStyle(color: Colors.amber.shade900, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _diseaseResult!['name'] ?? (isAr ? 'تشخيص نباتي' : 'Diagnosis Result'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                              ),
                            ),
                            if (_confidence != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLowConfidence ? Colors.orange.shade100 : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${isAr ? 'دقة' : 'Confidence'}: ${(_confidence! * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isLowConfidence ? Colors.orange.shade900 : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),

                        Text(
                          isAr ? '📖 الوصف والأعراض:' : '📖 Disease Overview & Symptoms:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _diseaseResult!['description'] ?? (isAr ? 'لا يوجد وصف متاح.' : 'No description available.'),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        if (_symptomAnalysisNote != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              _symptomAnalysisNote!,
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.4),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade50, Colors.teal.shade50],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAr ? '🌱 السماد والتغذية الموصى بها:' : '🌱 Recommended Fertilizer & Nutrition:',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _customFertilizerAdvice ?? (_diseaseResult!['fertilizer'] ?? (isAr ? 'سماد متوازن NPK 20-20-20 لدعم حيوية النبات.' : 'Balanced NPK 20-20-20 to support vigor.')),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade900, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          isAr ? '🛡️ الإجراءات العلاجية والمكافحة:' : '🛡️ Actionable Treatment & Care:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTreatments(_diseaseResult!['treatments'], isAr),
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
