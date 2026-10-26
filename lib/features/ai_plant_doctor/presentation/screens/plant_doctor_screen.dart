import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/core/notification_service.dart';
import 'package:terralogic/core/terra_theme.dart';
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
  // ================= 1. حمضيات (Citrus) =================
  'citrus_Sooty Mould': DiseaseDetail(
    nameAr: 'العفن الهبابي (السخامي) في الحمضيات',
    nameEn: 'Citrus Sooty Mould',
    cropAr: 'حمضيات',
    cropEn: 'Citrus',
    descriptionAr:
        'طبقة فحمية سوداء تشبه السخام تغطي أسطح الأوراق والأغصان والثمار نتيجة نمو فطريات رمية على الإفرازات العسلية للحشرات الماصة، مما يحجب الضوء ويعطل التمثيل الضوئي.',
    descriptionEn:
        'A dark powdery or velvety fungal layer on foliage and fruit growing on honeydew secreted by sucking insects, blocking sunlight and photosynthesis.',
    treatmentsAr: [
      'مكافحة الحشرات الثاقبة الماصة فوراً (المن، الذبابة البيضاء، البق الدقيقي) بمبيد حشري مناسب (أسيتامبريد أو إيميداكلوبريد)',
      'غسيل الأشجار بالماء المضغوط مع الصابون الزراعي البوتاسي لإزالة الطبقة السوداء',
      'رش مبيد نحاسي وقائي خفيف (أوكسي كلوريد النحاس) بعد تنظيف الشجرة لحمايتها',
    ],
    treatmentsEn: [
      'Control honeydew-producing sucking pests immediately (Aphids, Whiteflies, Mealybugs) with Acetamiprid or Imidacloprid',
      'Wash foliage with pressurized water and potassium agricultural soap to remove soot',
      'Apply light protective copper spray (Copper Oxychloride) after cleaning',
    ],
    fertilizerAr:
        'رش ورقي بالأحماض الأمينية والزنك والحديد المخلبي لتنشيط المجموع الخضري واستعادة كفاءة التمثيل الضوئي.',
    fertilizerEn:
        'Foliar spray with amino acids, chelated iron and zinc to restore vegetative vigor and photosynthetic activity.',
  ),
  'citrus_citrus_canker': DiseaseDetail(
    nameAr: 'تقرح الحمضيات البكتيري',
    nameEn: 'Citrus Canker',
    cropAr: 'حمضيات',
    cropEn: 'Citrus',
    descriptionAr:
        'مرض بكتيري خطير يسببه Xanthomonas axonopodis، يظهر على شكل بثور وبقع فلينية خشنة بارزة محاطة بهالة صفراء زيتية على الأوراق والسيقان والثمار مسبباً تساقطها وتشوهها.',
    descriptionEn:
        'Severe bacterial disease caused by Xanthomonas axonopodis, characterized by raised corky lesions with oily water-soaked margins and yellow halos on leaves and fruit.',
    treatmentsAr: [
      'رش مركبات النحاس الوقائية (هيدروكسيد النحاس أو أوكسي كلوريد النحاس) مع بدء خروج النموات الحديثة',
      'تقليم الأفرع والأغصان المصابة بشدة والتخلص منها بالحرق مع تعقيم مقصات التقليم بالكحول',
      'زراعة مصدات رياح حول البستان لتقليل جروح الرياح التي تنفذ منها البكتيريا',
    ],
    treatmentsEn: [
      'Apply preventative copper sprays (Copper Hydroxide or Oxychloride) during new flushes',
      'Prune and destroy heavily infected twigs, sanitizing shears between cuts',
      'Establish windbreaks around orchards to minimize wind-driven leaf injuries',
    ],
    fertilizerAr:
        'تسميد متوازن وتجنب الإفراط في النيتروجين الذي يولد نموات غضة ضعيفة المقاومة.',
    fertilizerEn:
        'Balanced NPK regime; avoid excessive quick-release nitrogen that produces succulent vulnerable tissues.',
  ),
  'citrus_healthy': DiseaseDetail(
    nameAr: 'أشجار حمضيات سليمة',
    nameEn: 'Healthy Citrus',
    cropAr: 'حمضيات',
    cropEn: 'Citrus',
    descriptionAr:
        'شجرة الحمضيات بحالة ممتازة، وأوراقها خضراء داكنة لامعة وسميكة، خالية من أي آفات أو بقع أو أعراض نقص عناصر.',
    descriptionEn:
        'Citrus tree is robust with lush, dark-green glossy leaves and no signs of bacterial, fungal, or insect infestations.',
    treatmentsAr: [
      'الاستمرار في برنامج الري المنتظم وتجنب ملامسة المياه المباشرة لجذع الشجرة لتفادي التصمغ',
      'الفحص الوقائي الدوري للبراعم والنموات الغضة لحمايتها من صانعات الأنفاق',
    ],
    treatmentsEn: [
      'Maintain regular irrigation while avoiding standing water against root flares',
      'Conduct regular scoutings for citrus leafminer and pests during growth flushes',
    ],
    fertilizerAr:
        'تسميد NPK متوازن مع إضافة الحديد المخلبي (Fe-EDDHA) والزنك والمنغنيز مرتين سنوياً.',
    fertilizerEn:
        'Balanced NPK program supplemented with chelated iron (Fe-EDDHA), zinc, and manganese.',
  ),

  // ================= 2. زيتون (Olive) =================
  'olive_healthy': DiseaseDetail(
    nameAr: 'أشجار زيتون سليمة',
    nameEn: 'Healthy Olive',
    cropAr: 'زيتون',
    cropEn: 'Olive',
    descriptionAr:
        'أشجار الزيتون نضرة وقوية، أوراقها جلدية خضراء فضية خالية تماماً من بقع عين الطاووس أو ذبول الفيرتيسيليوم، ونموها الثمري ممتاز.',
    descriptionEn:
        'Olive tree shows excellent health with clean leathery foliage, silver-green undersides, and vigorous canopy structure.',
    treatmentsAr: [
      'إجراء التقليم السنوي التهوي لفتح قلب الشجرة لدخول أشعة الشمس والهواء',
      'إزالة الأعشاب الضارة وحراثة خفيفة لحفظ رطوبة التربة',
    ],
    treatmentsEn: [
      'Perform annual canopy thinning to allow light penetration and aeration',
      'Keep tree basins free of weed competition and conserve soil moisture',
    ],
    fertilizerAr:
        'إضافة سماد عضوي متخمر وسوبر فوسفات في الشتاء، ورش سماد البورون في الربيع لدعم عقد وجودة الثمار.',
    fertilizerEn:
        'Winter compost and superphosphate, followed by spring foliar Boron to boost fruit set.',
  ),
  'olive_peacock_spot': DiseaseDetail(
    nameAr: 'مرض عين الطاووس في الزيتون',
    nameEn: 'Olive Peacock Spot',
    cropAr: 'زيتون',
    cropEn: 'Olive',
    descriptionAr:
        'مرض فطري يسببه Spilocaea oleaginea، تظهر بقع دائرية مميزة تشبه ريش عين الطاووس بهالات متحدة المركز بلون بني ورمادي مصفر على الأوراق تؤدي إلى تساقط كثيف للأوراق وضعف الشجرة.',
    descriptionEn:
        'Fungal leaf spot caused by Spilocaea oleaginea, producing distinctive target-like concentric circles (peacock eyes) on leaves, leading to severe defoliation.',
    treatmentsAr: [
      'رش وقائي بمركبات النحاس (محلول بوردو أو أوكسي كلوريد النحاس) في الخريف وبداية الربيع قبل هطول الأمطار',
      'تقليم الأفرع المتشابكة والسفلية لتحسين التهوية وخفض الرطوبة داخل الشجرة',
      'جمع الأوراق المصابة المتساقطة على الأرض والتخلص منها لتقليل مصدر العدوى',
    ],
    treatmentsEn: [
      'Preventative copper sprays (Bordeaux mixture or Copper Oxychloride) in autumn and early spring',
      'Prune dense branches to enhance airflow and sunlight penetration',
      'Collect and destroy fallen infected leaves to eradicate inoculum sources',
    ],
    fertilizerAr:
        'التسميد بالبوتاسيوم لتقوية جدران الخلايا، وتجنب الإفراط في النيتروجين في الخريف.',
    fertilizerEn:
        'Apply Potassium to strengthen cuticle barriers; avoid late autumn nitrogen overfeeding.',
  ),

  // ================= 3. بطاطس (Potato) =================
  'potato_Early_Blight': DiseaseDetail(
    nameAr: 'اللفحة المبكرة في البطاطس',
    nameEn: 'Potato Early Blight',
    cropAr: 'بطاطس',
    cropEn: 'Potato',
    descriptionAr:
        'مرض فطري يسببه Alternaria solani، يظهر على شكل بقع بنية داكنة ذات حلقات دائرية متحدة المركز (عين الهدف) على الأوراق السفلية أولاً، وتؤدي إلى اصفرار الأوراق وموتها وضعف نمو الدرنات.',
    descriptionEn:
        'Fungal disease caused by Alternaria solani, characterized by dark brown circular spots with concentric target-board rings on older foliage.',
    treatmentsAr: [
      'رش مبيد فطري وقائي أو علاجي (دايفينوكونازول، مانكوزيب، أو أزوكسيستروبين)',
      'التخلص من بقايا النباتات المصابة وتدوير المحاصيل مع نباتات غير باذنجانية',
      'تنظيم الري واستخدام الري بالتنقيط لتجنب ترطيب الأوراق',
    ],
    treatmentsEn: [
      'Spray targeted fungicides (Difenoconazole, Mancozeb, or Azoxystrobin)',
      'Destroy infected crop residues and rotate with non-solanaceous crops',
      'Employ drip irrigation to prevent foliage wetting',
    ],
    fertilizerAr:
        'تسميد بوتاسيوم عالي لرفع متانة الأوراق ومقاومة الفطريات + كالسيوم لتحسين جودة الدرنات.',
    fertilizerEn:
        'High potassium feeding for tissue resistance + Calcium for tuber peel strength.',
  ),
  'potato_Late_blight': DiseaseDetail(
    nameAr: 'اللفحة المتأخرة في البطاطس',
    nameEn: 'Potato Late Blight',
    cropAr: 'بطاطس',
    cropEn: 'Potato',
    descriptionAr:
        'مرض وبائي خطير يسببه شبه الفطر Phytophthora infestans، يسبب بقعاً مائية رمادية إلى بنية داكنة سريعة الانتشار على الأوراق والسيقان مع زغب أبيض خفيف على السطح السفلي في الطقس الرطب والبارد.',
    descriptionEn:
        'Aggressive oomycete pathogen (Phytophthora infestans) causing rapid water-soaked dark lesions, white underside sporulation, and devastating vine kill.',
    treatmentsAr: [
      'التدخل الفوري بمبيد جهازي قوي (سيموكسانيل + مانكوزيب، أو ميتالاكسيل، أو بروباموكارب)',
      'التخلص الفوري من النباتات المصابة بشدة ودفنها بعيداً لمنع انتشار العدوى',
      'التوقف الفوري عن الري العلوي وخفض الرطوبة قدر الإمكان',
    ],
    treatmentsEn: [
      'Urgent intervention with systemic fungicides (Cymoxanil + Mancozeb, Metalaxyl, or Propamocarb)',
      'Rogue out severely diseased plants and eliminate cull piles',
      'Avoid overhead irrigation and reduce field moisture',
    ],
    fertilizerAr:
        'رش فوسفيت البوتاسيوم لتحفيز المناعة الجهازية المكتسبة داخل أنسجة النبات.',
    fertilizerEn:
        'Potassium Phosphite foliar applications to trigger systemic acquired resistance (SAR).',
  ),
  'potato_healthy': DiseaseDetail(
    nameAr: 'نبات بطاطس سليم',
    nameEn: 'Healthy Potato',
    cropAr: 'بطاطس',
    cropEn: 'Potato',
    descriptionAr:
        'نبات البطاطس سليم وقوي ومكتمل النمو، أوراقه خضراء نضرة خالية من اللفحات أو الفيروسات، وتكوين الدرنات تحت التربة نشط وصحي.',
    descriptionEn:
        'Potato plant is vigorous with lush green canopy, free from blights or viruses, supporting active subterranean tuberization.',
    treatmentsAr: [
      'المحافظة على الترديم والتكويم حول السيقان لحماية الدرنات النامية من أشعة الشمس واخضرار القشرة',
      'الري المنتظم والموزون لتجنب تشقق الدرنات',
    ],
    treatmentsEn: [
      'Maintain regular hillings around stems to protect swelling tubers from sunburn and greening',
      'Provide uniform moisture to avoid growth cracks and hollow hearts',
    ],
    fertilizerAr:
        'تسميد NPK عالي البوتاسيوم (مثل 0-0-50 أو 12-12-36) لدعم تحجيم ونوعية الدرنات.',
    fertilizerEn:
        'High potassium NPK (such as 0-0-50 or 12-12-36) to maximize tuber sizing and solid content.',
  ),

  // ================= 4. طماطم (Tomato) =================
  'tomato_early_blight': DiseaseDetail(
    nameAr: 'اللفحة المبكرة في الطماطم (البندورة)',
    nameEn: 'Tomato Early Blight',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'مرض فطري يسببه Alternaria solani، يبدأ كبقع بنية صغيرة على الأوراق القديمة وتتوسع لتشكل حلقات دائرية متحدة المركز وهالات صفراء، مسببة جفاف الأوراق وسقوطها.',
    descriptionEn:
        'Fungal pathogen (Alternaria solani) producing dark brown concentric rings surrounded by yellow halos on lower tomato foliage.',
    treatmentsAr: [
      'إزالة الأوراق السفلية المصابة والملامسة للتربة (التوريق الوقائي)',
      'رش مبيد فطري كلوروثالونيل أو دايفينوكونازول أو أزوكسيستروبين',
      'تجنب الري الرذاذي العلوي والاعتماد على الري بالتنقيط',
    ],
    treatmentsEn: [
      'Prune off diseased lower soil-touching leaves',
      'Apply Chlorothalonil, Difenoconazole, or Azoxystrobin fungicide',
      'Use drip irrigation instead of sprinkler systems to keep foliage dry',
    ],
    fertilizerAr:
        'سماد NPK عالي البوتاسيوم 12-12-36 مع كالسيوم بورون لتقوية النبات وجدران الخلايا.',
    fertilizerEn:
        'High-potassium NPK 12-12-36 combined with Calcium-Boron for cell wall fortitude.',
  ),
  'tomato_healthy': DiseaseDetail(
    nameAr: 'نبات طماطم (بندورة) سليم',
    nameEn: 'Healthy Tomato Plant',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'نبات الطماطم سليم وبحالة ممتازة وخالٍ تماماً من اللفحات والتبقعات والآفات، مع نمو خضري وزهري متوازن وقوي.',
    descriptionEn:
        'Tomato plant is in prime health with vigorous green foliage, strong stems, and flawless flower and fruit clusters.',
    treatmentsAr: [
      'الاستمرار في الرش الوقائي الدوري والري المنتظم بالتنقيط',
      'التهوية الجيدة داخل البيوت المحمية وضبط درجات الحرارة والرطوبة',
    ],
    treatmentsEn: [
      'Continue routine preventative scouting and drip irrigation schedule',
      'Maintain greenhouse ventilation and climate management',
    ],
    fertilizerAr:
        'برنامج تسميد NPK متوازن ومتدرج (عالي الفوسفور للتجذير، متوازن للنمو الخضري، وعالي البوتاسيوم للتحجيم).',
    fertilizerEn:
        'Balanced progressive NPK regime tailored to stage (High-P roots, 20-20-20 growth, High-K fruit sizing).',
  ),
  'tomato_late_blight': DiseaseDetail(
    nameAr: 'اللفحة المتأخرة في الطماطم (البندورة)',
    nameEn: 'Tomato Late Blight',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'مرض وبائي مائي شرس يسببه Phytophthora infestans، يصيب الأوراق والسيقان بمسحات مائية بنية داكنة سريعة الانتشار مع عفن مائي مسود على الثمار الخضراء في الطقس البارد الرطب.',
    descriptionEn:
        'Highly destructive water-mold disease causing rapidly spreading water-soaked dark lesions, white fungal growth under leaves, and rotting fruit.',
    treatmentsAr: [
      'رش فوري بمبيدات جهازية متخصصة (مانكوزيب + سيموكسانيل أو ميتالاكسيل أو ديميثومورف)',
      'تهوية البيوت المحمية فوراً وخفض الرطوبة النسبية إلى أقل من 80%',
      'التخلص من الثمار والأوراق المصابة بحرص خارج المزرعة',
    ],
    treatmentsEn: [
      'Urgent foliar spray with systemic fungicides (Mancozeb + Cymoxanil, Metalaxyl, or Dimethomorph)',
      'Ventilate greenhouses immediately to lower relative humidity below 80%',
      'Cull and dispose of all infected fruit and foliage safely away from fields',
    ],
    fertilizerAr:
        'سقاية فوسفيت البوتاسيوم لتحفيز الدفاعات الذاتية وتجنب إضافة أي سماد نيتروجيني حر أثناء الإصابة.',
    fertilizerEn:
        'Potassium Phosphite root drench for defense stimulation; avoid quick-acting nitrogen.',
  ),

  // ================= 5. قمح (Wheat) =================
  'wheat_Brown_Rust': DiseaseDetail(
    nameAr: 'صدأ الأوراق (الصدأ البني) في القمح',
    nameEn: 'Wheat Brown Rust (Leaf Rust)',
    cropAr: 'قمح',
    cropEn: 'Wheat',
    descriptionAr:
        'مرض فطري يسببه Puccinia triticina، تظهر بثرات دائرية صغيرة بلون بني محمر أو برتقالي مبعثرة عشوائياً على أنصال الأوراق تطلق مسحوقاً برتقالياً عند لمسها، وتؤدي لجفاف الأوراق وموتها قبل امتلاء الحبوب.',
    descriptionEn:
        'Fungal leaf rust caused by Puccinia triticina, producing scattered round red-orange pustules on leaf blades that reduce grain fill and yield.',
    treatmentsAr: [
      'رش مبيد فطري جهازي من مجموعة التريازول (تيبوكونازول أو بروبيكونازول) عند أول ظهور للبثرات',
      'زراعة الأصناف المعتمدة المقاومة للصدأ',
      'التخلص من حشائش الحقول والنجيليات البرية المضيفة للفطر',
    ],
    treatmentsEn: [
      'Apply systemic triazole fungicide (Tebuconazole or Propiconazole) at first sign of pustules',
      'Plant certified rust-resistant wheat cultivars',
      'Eradicate volunteer cereal grasses acting as secondary hosts',
    ],
    fertilizerAr:
        'تسميد فوسفاتي وبوتاسي متوازن لدعم صلابة السيقان، وعدم الإفراط في التسميد الآزوتي المتأخر.',
    fertilizerEn:
        'Balanced phosphate and potash to support stem strength; avoid late excessive nitrogen bursts.',
  ),
  'wheat_healthy': DiseaseDetail(
    nameAr: 'حقل قمح سليم',
    nameEn: 'Healthy Wheat',
    cropAr: 'قمح',
    cropEn: 'Wheat',
    descriptionAr:
        'سنابل وأوراق القمح نضرة وخضراء يانعة، خالية تماماً من بثرات الأصداء أو البياض أو التبقعات، مع كفاءة نمو ممتازة وتفريع قوي.',
    descriptionEn:
        'Wheat field displays outstanding health with deep-green foliage, uniform tillering, clean flag leaves, and disease-free emerging spikes.',
    treatmentsAr: [
      'إدارة الري بكفاءة أثناء فترات التفريع والامتلاء وتجنب ركود المياه',
      'مراقبة الحقل الدورية لاكتشاف أي بؤر مرضية مبكرة',
    ],
    treatmentsEn: [
      'Manage irrigation carefully during tillering, heading, and grain-fill phases',
      'Conduct regular field scouting to catch any early disease hotspots',
    ],
    fertilizerAr:
        'برنامج تسميد نيتروجيني موزع على دفعات (عند الزراعة والتفريع وطرد السنابل) مع سلفات الزنك وعناصر صغرى.',
    fertilizerEn:
        'Split nitrogen fertilization schedule (planting, tillering, heading) fortified with Zinc sulfate.',
  ),
  'wheat_yellow_rust': DiseaseDetail(
    nameAr: 'الصدأ الأصفر (الصدأ المخطط) في القمح',
    nameEn: 'Wheat Yellow Rust (Stripe Rust)',
    cropAr: 'قمح',
    cropEn: 'Wheat',
    descriptionAr:
        'مرض وبائي خطير جداً يسببه Puccinia striiformis، يظهر على شكل بثرات صفراء ليمونية دقيقة مصطفة في خطوط طولية متوازية على طول عروق الورقة تشبه الخطوط الملونة، وينتشر بسرعة في الأجواء الباردة والرطبة مسبباً خسائر جسيمة.',
    descriptionEn:
        'Devastating stripe rust caused by Puccinia striiformis, exhibiting bright yellow pustules arranged in distinct linear stripes along leaf veins in cool humid weather.',
    treatmentsAr: [
      'الرش الفوري والشامل بمبيد فطري جهازي متخصص (تيبوكونازول، إيبوكسيكونازول، أو أزوكسيستروبين مع بروبيكونازول)',
      'الاستجابة السريعة فور ظهور أي بؤرة صفراء في الحقل لمنع انتشار الوباء',
      'اختيار أصناف قمح ذات مقاومة وراثية عالية للأصداء الصفراء',
    ],
    treatmentsEn: [
      'Urgent whole-field spraying with high-efficacy systemic triazole/strobilurin fungicides',
      'Act rapidly upon spotting the earliest yellow foci to prevent epidemic surges',
      'Select genetics with proven stripe rust resistance genes',
    ],
    fertilizerAr:
        'رش ورقي بسلفات البوتاسيوم لتعزيز سماكة جدر الخلايا وتجنب المغالاة في التسميد النيتروجيني.',
    fertilizerEn:
        'Foliar Potassium Sulfate to reinforce epidermal cells and reduce tissue susceptibility.',
  ),

  'Apple___Apple_scab': DiseaseDetail(
    nameAr: 'جرب التفاح',
    nameEn: 'Apple Scab',
    cropAr: 'تفاح',
    cropEn: 'Apple',
    descriptionAr:
        'مرض فطري يسبب بقعاً زيتية رمادية إلى سوداء على الأوراق والثمار تؤدي لتشوهها وتساقطها المبكر.',
    descriptionEn:
        'Fungal disease causing olive-green to black velvety spots on leaves and fruit, leading to premature defoliation.',
    treatmentsAr: [
      'رش مبيد فطري وقائي نحاسي أو جهازي (ديفينوكونازول)',
      'تقليم الأفرع المصابة والتخلص منها خارج المزرعة',
      'تجنب الري الرذاذي العلوي',
    ],
    treatmentsEn: [
      'Apply copper or systemic fungicide (Difenoconazole)',
      'Prune and destroy infected branches',
      'Avoid overhead sprinkler irrigation',
    ],
    fertilizerAr:
        'سماد بوتاسي لرفع مناعة الثمار + كالسيوم لتحسين صلابة القشرة.',
    fertilizerEn:
        'Potassium fertilizer to boost fruit immunity + Calcium to enhance peel firmness.',
  ),

  'Apple___Black_rot': DiseaseDetail(
    nameAr: 'العفن الأسود في التفاح',
    nameEn: 'Apple Black Rot',
    cropAr: 'تفاح',
    cropEn: 'Apple',
    descriptionAr:
        'تعفن دائري بني مسود على الثمار مع بقع عين الضفدع على الأوراق.',
    descriptionEn:
        'Circular brownish-black rot on fruits accompanied by frog-eye leaf spots.',
    treatmentsAr: [
      'رش مبيدات فطرية وقائية عند تساقط البتلات',
      'إزالة الثمار المتعفنة والمتساقطة فوراً',
    ],
    treatmentsEn: [
      'Apply protective fungicides during petal fall',
      'Remove and destroy rotting and mummified fruit immediately',
    ],
    fertilizerAr: 'تسميد متوازن NPK 20-20-20 لتقوية النمو الخضري.',
    fertilizerEn:
        'Balanced NPK 20-20-20 fertilization to support vigorous vegetative growth.',
  ),

  'Apple___Cedar_apple_rust': DiseaseDetail(
    nameAr: 'صدأ أرز التفاح',
    nameEn: 'Cedar Apple Rust',
    cropAr: 'تفاح',
    cropEn: 'Apple',
    descriptionAr:
        'بقع برتقالية فاقعة على السطح العلوي للأوراق مع بروزات خيطية أسفلها.',
    descriptionEn:
        'Bright orange-yellow spots on upper leaf surfaces with small tube-like projections underneath.',
    treatmentsAr: [
      'استخدام مبيدات فطرية متخصصة بالصدأ مثل المانكوزيب أو الميكلوبوتانيل',
      'إبعاد أشجار العرعر القريبة',
    ],
    treatmentsEn: [
      'Use rust-specific fungicides like Mancozeb or Myclobutanil',
      'Remove nearby juniper/cedar host trees',
    ],
    fertilizerAr:
        'عناصر صغرى (زنك وحديد ومغنيسيوم) لتعويض إجهاد البناء الضوئي.',
    fertilizerEn:
        'Micronutrients (Zinc, Iron, Magnesium) to compensate for photosynthetic stress.',
  ),

  'Apple___healthy': DiseaseDetail(
    nameAr: 'أوراق تفاح سليمة',
    nameEn: 'Healthy Apple Leaves',
    cropAr: 'تفاح',
    cropEn: 'Apple',
    descriptionAr:
        'شجرة التفاح بحالة صحية ممتازة ومثالية ولا تظهر عليها أي أعراض مرضية.',
    descriptionEn:
        'Apple tree is in excellent, vigorous condition with no visible signs of disease.',
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
    descriptionEn:
        'Blueberry plant is healthy, thriving under optimal acidic soil conditions.',
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
    descriptionAr:
        'طبقة مسحوقية بيضاء دقيقة تغطي الأوراق والنموات الحديثة وتلتف الأوراق المصابة.',
    descriptionEn:
        'White powdery fungal coating on leaves and young shoots causing leaf distortion.',
    treatmentsAr: [
      'رش الكبريت الميكروني الوقائي',
      'مبيد فطري جهازي مثل بينكونازول أو توباس',
    ],
    treatmentsEn: [
      'Spray micronized wettable sulfur',
      'Apply systemic fungicide (Penconazole or Topas)',
    ],
    fertilizerAr:
        'تجنب الإفراط في التسميد النيتروجيني واستخدام سيليكات البوتاسيوم.',
    fertilizerEn:
        'Avoid excessive nitrogen; apply Potassium Silicate for cuticle strengthening.',
  ),

  'Cherry_(including_sour)___healthy': DiseaseDetail(
    nameAr: 'أوراق كرز سليمة',
    nameEn: 'Healthy Cherry',
    cropAr: 'كرز',
    cropEn: 'Cherry',
    descriptionAr: 'النبات سليم ومعافى تماماً.',
    descriptionEn: 'Cherry tree is healthy and foliage is vibrant.',
    treatmentsAr: ['المتابعة الدورية والتقليم الجيد لضمان دخول الشمس والتهوية'],
    treatmentsEn: [
      'Regular monitoring and good canopy pruning for sun exposure',
    ],
    fertilizerAr: 'تسميد عضوي شتوي وNPK متوازن.',
    fertilizerEn: 'Winter organic manure and balanced NPK fertilizer.',
  ),

  'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot': DiseaseDetail(
    nameAr: 'تبقع أوراق الذرة الرمادي (سيركوسبورا)',
    nameEn: 'Corn Gray Leaf Spot (Cercospora)',
    cropAr: 'ذرة',
    cropEn: 'Corn',
    descriptionAr:
        'بقع مستطيلة متوازية مع عروق الورقة تتحول للون الرمادي البني.',
    descriptionEn:
        'Rectangular tan-to-gray lesions running parallel to leaf veins.',
    treatmentsAr: [
      'اتباع دورة زراعية مناسبة',
      'رش مبيدات فطرية من مجموعة ستروبيلورين',
    ],
    treatmentsEn: [
      'Implement crop rotation',
      'Apply strobilurin-class fungicides',
    ],
    fertilizerAr:
        'تسميد بوتاسي لتقوية جدر الخلايا في الساق والأوراق ومقاومة الرقاد.',
    fertilizerEn:
        'Potassium fertilization to strengthen stalks and prevent lodging.',
  ),

  'Corn_(maize)___Common_rust_': DiseaseDetail(
    nameAr: 'الصدأ الشائع في الذرة',
    nameEn: 'Corn Common Rust',
    cropAr: 'ذرة',
    cropEn: 'Corn',
    descriptionAr:
        'بثور بنية محمرة تنتشر على سطحي الورقة تفرز غباراً بلون الصدأ يقلل البناء الضوئي.',
    descriptionEn:
        'Reddish-brown pustules on both leaf surfaces releasing rust-colored powdery spores.',
    treatmentsAr: [
      'زراعة أصناف مقاومة',
      'رش مبيدات مانكوزيب أو تيبوكونازول عند بداية الإصابة',
    ],
    treatmentsEn: [
      'Plant resistant hybrid varieties',
      'Apply Mancozeb or Tebuconazole upon early onset',
    ],
    fertilizerAr: 'سماد متوازن وتجنب الإفراط في اليوريا عند اشتداد الرطوبة.',
    fertilizerEn: 'Balanced fertilizer; avoid excess urea in high humidity.',
  ),

  'Corn_(maize)___Northern_Leaf_Blight': DiseaseDetail(
    nameAr: 'لفحة أوراق الذرة الشمالية',
    nameEn: 'Northern Corn Leaf Blight',
    cropAr: 'ذرة',
    cropEn: 'Corn',
    descriptionAr:
        'بقع بيضاوية رمادية كبيرة تشبه السيجار على الأوراق وتجفف مساحات كبيرة من المجموع الخضري.',
    descriptionEn: 'Large, elliptical, cigar-shaped grayish lesions on leaves.',
    treatmentsAr: [
      'مبيدات فطرية جهازية (أزوكسيستروبين)',
      'التخلص من بقايا المحصول السابق بحراثة عميقة',
    ],
    treatmentsEn: [
      'Systemic fungicides (Azoxystrobin)',
      'Deep tillage to bury previous crop debris',
    ],
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
    treatmentsEn: [
      'Maintain regular watering especially during silking and grain fill',
    ],
    fertilizerAr:
        'جرعات نيتروجينية (يوريا أو نترات النشادر) على دفعات متتالية.',
    fertilizerEn:
        'Sequential nitrogen side-dressings (Urea or Ammonium Nitrate).',
  ),

  'Grape___Black_rot': DiseaseDetail(
    nameAr: 'العفن الأسود في العنب',
    nameEn: 'Grape Black Rot',
    cropAr: 'عنب',
    cropEn: 'Grape',
    descriptionAr:
        'بقع بنية على الأوراق مع جفاف وتجعد حبات العنب وتحولها للون الأسود الصلب.',
    descriptionEn:
        'Brown leaf spots and shriveling of berries into hard, black, mummified fruit.',
    treatmentsAr: [
      'جمع العناقيد المصابة وإتلافها فوراً',
      'الرش الوقائي بمبيد ميكلوبوتانيل أو مانكوزيب',
    ],
    treatmentsEn: [
      'Remove and destroy infected clusters',
      'Preventative sprays of Myclobutanil or Mancozeb',
    ],
    fertilizerAr: 'كالسيوم وبورون لتقوية قشرة الحبات ومنع تشققها.',
    fertilizerEn:
        'Calcium and Boron to reinforce berry skins and prevent cracking.',
  ),

  'Grape___Esca_(Black_Measles)': DiseaseDetail(
    nameAr: 'مرض إسكا (الحصبة السوداء) في العنب',
    cropAr: 'عنب',
    cropEn: 'Grape',
    nameEn: 'Grape Esca (Black Measles)',
    descriptionAr:
        'اصفرار بين عروق الأوراق يعطي مظهر جلد النمر، مع بقع داكنة على الحبات وجفاف الأغصان.',
    descriptionEn:
        'Tiger-stripe interveinal leaf discoloration with dark speckling on berries.',
    treatmentsAr: [
      'تقليم الأفرع المصابة وتعقيم المقصات بالكحول',
      'تغطية جروح التقليم بعجينة بوردو',
    ],
    treatmentsEn: [
      'Prune symptomatic wood and sanitize tools',
      'Protect pruning wounds with Bordeaux paste',
    ],
    fertilizerAr: 'هيوميك أسيد ومنشطات جذور لتقليل الإجهاد الوعائي على الكرمة.',
    fertilizerEn:
        'Humic acid and root biostimulants to alleviate vascular stress.',
  ),

  'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)': DiseaseDetail(
    nameAr: 'لفحة أوراق العنب (إيزاريوبسيس)',
    nameEn: 'Grape Leaf Blight (Isariopsis)',
    cropAr: 'عنب',
    cropEn: 'Grape',
    descriptionAr:
        'بقع بنية داكنة غير منتظمة على الأوراق مع حواف محددة تسبب جفاف الأوراق وسقوطها.',
    descriptionEn:
        'Irregular dark brown leaf spots causing premature foliage drop.',
    treatmentsAr: [
      'مبيدات فطرية نحاسية بعد جني المحصول وفي بداية الربيع',
      'تقليم الأوراق الزائدة للتهوية',
    ],
    treatmentsEn: [
      'Copper-based fungicides post-harvest and in spring',
      'Canopy management for air circulation',
    ],
    fertilizerAr: 'سلفات البوتاسيوم لتحسين صلابة ومناعة الأوراق.',
    fertilizerEn: 'Potassium sulfate to improve leaf tissue resilience.',
  ),

  'Grape___healthy': DiseaseDetail(
    nameAr: 'أوراق عنب سليمة',
    nameEn: 'Healthy Grapevine',
    cropAr: 'عنب',
    cropEn: 'Grape',
    descriptionAr: 'كرمة العنب سليمة ونضرة ولا توجد أي إصابات.',
    descriptionEn:
        'Grapevine is vigorous and free from disease or insect infestation.',
    treatmentsAr: ['التقليم الأخضر وتنظيم الري بالتنقيط'],
    treatmentsEn: ['Green shoot thinning and controlled drip irrigation'],
    fertilizerAr:
        'برنامج تسميد متكامل (نيتروجين في الربيع، وبوتاسيوم عند تحجيم الثمار).',
    fertilizerEn:
        'Comprehensive nutrition plan (Nitrogen in spring, Potassium during berry sizing).',
  ),

  'Orange___Haunglongbing_(Citrus_greening)': DiseaseDetail(
    nameAr: 'اخضرار الحمضيات (التدهور السريع)',
    nameEn: 'Citrus Greening (Huanglongbing)',
    cropAr: 'حمضيات',
    cropEn: 'Citrus',
    descriptionAr:
        'اصفرار غير متماثل في الأوراق (مظهر مبرقش) وصغر الثمار وتراجع إنتاجية الشجرة.',
    descriptionEn:
        'Asymmetrical blotchy mottle leaf yellowing, bitter lopsided small fruits.',
    treatmentsAr: [
      'مكافحة حشرة بسيلا الحمضيات الناقلة للبكتيريا فوراً بالمبيدات الحشرية',
      'إزالة الأشجار شديدة التدهور',
    ],
    treatmentsEn: [
      'Aggressively control the Asian Citrus Psyllid vector',
      'Eradicate severely diseased trees',
    ],
    fertilizerAr:
        'رش عناصر صغرى ورقية (زنك، منغنيز، حديد، بورون) لتخفيف الإجهاد.',
    fertilizerEn:
        'Foliar micronutrient sprays (Zinc, Manganese, Iron, Boron) to alleviate decline.',
  ),

  'Peach___Bacterial_spot': DiseaseDetail(
    nameAr: 'التبقع البكتيري في الخوخ',
    nameEn: 'Peach Bacterial Spot',
    cropAr: 'خوخ',
    cropEn: 'Peach',
    descriptionAr:
        'ثقوب صغيرة تشبه طلقات الرصاص على الأوراق وبقع غائرة على الثمار.',
    descriptionEn:
        'Shot-hole appearance on foliage and sunken dark lesions on peach fruit.',
    treatmentsAr: [
      'مركبات نحاسية في موسم السكون قبل تفتح البراعم',
      'استخدام مضادات بكتيرية زراعية مخصصة',
    ],
    treatmentsEn: [
      'Dormant copper sprays before bud break',
      'Apply registered agricultural bactericides',
    ],
    fertilizerAr:
        'تسميد معتدل وتجنب زيادة النيتروجين التي تزيد طراوة الأنسجة وسرعة اختراق البكتيريا.',
    fertilizerEn:
        'Moderate fertilization; avoid excessive nitrogen that softens tissue.',
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
    descriptionAr:
        'بقع دائرية مائية تتحول للبني الداكن مع هالة صفراء على الأوراق وتلف للأزهار.',
    descriptionEn:
        'Water-soaked spots turning dark brown with yellow halos; blighting of blossoms.',
    treatmentsAr: [
      'رش هيدروكسيد النحاس أو مانكوزيب مع النحاس',
      'تجنب العمل بالحقل والنباتات رطبة بالندى',
    ],
    treatmentsEn: [
      'Spray copper hydroxide mixed with Mancozeb',
      'Avoid field operations when foliage is wet',
    ],
    fertilizerAr: 'كالسيوم وبورون لتقوية جدران الخلايا النباتية.',
    fertilizerEn:
        'Calcium-Boron foliar application to reinforce cellular walls.',
  ),

  'Pepper,_bell___healthy': DiseaseDetail(
    nameAr: 'نبات فلفل سليم',
    nameEn: 'Healthy Bell Pepper',
    cropAr: 'فلفل حلو',
    cropEn: 'Bell Pepper',
    descriptionAr: 'نبات الفلفل ينمو بصحة ممتازة ولا تظهر عليه أعراض مرضية.',
    descriptionEn:
        'Pepper plant is healthy and producing clean foliage and blossoms.',
    treatmentsAr: ['الحفاظ على الرطوبة المعتدلة والوقاية الدورية'],
    treatmentsEn: [
      'Maintain moderate moisture and routine preventative pest scouting',
    ],
    fertilizerAr: 'سماد NPK متوازن 20-20-20 وكالسيوم دوري كل 10 أيام.',
    fertilizerEn:
        'Balanced NPK 20-20-20 and periodic Calcium feeds every 10 days.',
  ),

  'Potato___Early_blight': DiseaseDetail(
    nameAr: 'اللفحة المبكرة في البطاطا',
    nameEn: 'Potato Early Blight',
    cropAr: 'بطاطا',
    cropEn: 'Potato',
    descriptionAr:
        'بقع بنية دائرية متحدة المركز تشبه لوحة الهدف على الأوراق السفلية.',
    descriptionEn:
        'Concentric ring target-board brown spots on lower mature potato leaves.',
    treatmentsAr: [
      'رش مبيد فطري (كلوروثالونيل أو مانكوزيب)',
      'التخلص من الأوراق السفلية المصابة الملامسة للتربة',
    ],
    treatmentsEn: [
      'Fungicide sprays (Chlorothalonil or Mancozeb)',
      'Remove infected lower leaves in contact with soil',
    ],
    fertilizerAr: 'سماد عالي البوتاسيوم لتقوية الدرنات والأوراق.',
    fertilizerEn:
        'High-potassium fertilizer to enhance tuber bulking and foliage endurance.',
  ),

  'Potato___Late_blight': DiseaseDetail(
    nameAr: 'اللفحة المتأخرة في البطاطا',
    nameEn: 'Potato Late Blight',
    cropAr: 'بطاطا',
    cropEn: 'Potato',
    descriptionAr:
        'بقع مائية داكنة تتسع بسرعة شديدة مع طبقة بيضاء رطبة على السطح السفلي للأوراق.',
    descriptionEn:
        'Rapidly spreading dark water-soaked lesions with white mold on leaf undersides.',
    treatmentsAr: [
      'مبيدات جهازية عاجلة (ميتالاكسيل أو سيموكسانيل)',
      'وقف الري الرذاذي وتقليل الرطوبة فوراً',
    ],
    treatmentsEn: [
      'Urgent systemic fungicides (Metalaxyl or Cymoxanil)',
      'Cease overhead watering to lower humidity',
    ],
    fertilizerAr: 'فوسفيت البوتاسيوم لرفع المناعة المكتسبة للنبات.',
    fertilizerEn:
        'Potassium Phosphite to activate systemic acquired resistance (SAR).',
  ),

  'Potato___healthy': DiseaseDetail(
    nameAr: 'نبات بطاطا سليم',
    nameEn: 'Healthy Potato',
    cropAr: 'بطاطا',
    cropEn: 'Potato',
    descriptionAr: 'مجموع خضري ممتاز وخالٍ من الإصابات الفطرية والحشرية.',
    descriptionEn:
        'Vibrant, healthy potato canopy with no disease or pest damage.',
    treatmentsAr: ['تغطية الدرنات بالتربة جيداً (التحضين) وتنظيم الري'],
    treatmentsEn: [
      'Proper hilling to shield tubers from sunlight and blight spores',
    ],
    fertilizerAr:
        'سماد عالي الفوسفور في البداية ثم عالي البوتاسيوم لتحجيم الدرنات.',
    fertilizerEn:
        'High phosphorus for root establishment, transitioning to high potassium for tuber sizing.',
  ),

  'Raspberry___healthy': DiseaseDetail(
    nameAr: 'توت العليق سليم',
    nameEn: 'Healthy Raspberry',
    cropAr: 'توت العليق',
    cropEn: 'Raspberry',
    descriptionAr: 'النبات سليم وجيد النمو.',
    descriptionEn:
        'Raspberry canes are healthy with vigorous vegetative development.',
    treatmentsAr: ['تقليم القصبات القديمة بعد الإثمار والتهوية الجيدة'],
    treatmentsEn: [
      'Prune old floricanes post-harvest to encourage air circulation',
    ],
    fertilizerAr: 'سماد عضوي وNPK متوازن.',
    fertilizerEn: 'Organic compost and balanced NPK fertilizer.',
  ),

  'Soybean___healthy': DiseaseDetail(
    nameAr: 'فول الصويا سليم',
    nameEn: 'Healthy Soybean',
    cropAr: 'فول صويا',
    cropEn: 'Soybean',
    descriptionAr: 'نبات سليم ومعافى.',
    descriptionEn:
        'Soybean crop is thriving with healthy symbiotic nitrogen fixation.',
    treatmentsAr: ['مراقبة الآفات الحشرية والري المنتظم'],
    treatmentsEn: ['Routine insect monitoring and timely irrigation'],
    fertilizerAr:
        'سماد فوسفوري وبوتاسي (النبات يثبت النيتروجين حيوياً من الجو).',
    fertilizerEn:
        'Phosphorus and potassium fertilization (nodules fix biological nitrogen).',
  ),

  'Squash___Powdery_mildew': DiseaseDetail(
    nameAr: 'البياض الدقيقي في الكوسا والقرع',
    nameEn: 'Squash Powdery Mildew',
    cropAr: 'كوسا وقرع',
    cropEn: 'Squash / Pumpkin',
    descriptionAr:
        'بودرة بيضاء دقيقة تشبه الطحين تغطي الأوراق وتؤدي لجفافها واصفرارها وموتها.',
    descriptionEn:
        'White powdery fungal growth covering leaf surfaces causing yellowing and senescence.',
    treatmentsAr: [
      'رش مبيد فطري مخصص للبياض الدقيقي (بينكونازول أو تريفلوكسيستروبين)',
      'رش محلول بيكربونات البوتاسيوم مخفف',
    ],
    treatmentsEn: [
      'Fungicide sprays (Penconazole or Trifloxystrobin)',
      'Foliar spray with diluted Potassium Bicarbonate',
    ],
    fertilizerAr:
        'سماد سيليكات البوتاسيوم لتقوية بشرة الورقة ومنع اختراق ميسليوم الفطر.',
    fertilizerEn:
        'Potassium Silicate to thicken epidermis and deter fungal penetration.',
  ),

  'Strawberry___Leaf_scorch': DiseaseDetail(
    nameAr: 'حرق أوراق الفراولة',
    nameEn: 'Strawberry Leaf Scorch',
    cropAr: 'فراولة',
    cropEn: 'Strawberry',
    descriptionAr:
        'بقع بنفسجية إلى بنية داكنة تغطي الأوراق حتى تجعلها تبدو كالمحترقة وتضعف المحصول.',
    descriptionEn:
        'Purplish-brown angular spots coalescing and causing leaves to appear scorched.',
    treatmentsAr: [
      'إزالة الأوراق المحترقة بعد الحصاد',
      'رش مبيدات فطرية وقائية نحاسية',
    ],
    treatmentsEn: [
      'Remove scorched foliage after harvest',
      'Apply preventative copper-based sprays',
    ],
    fertilizerAr:
        'تسميد كالسيوم ومغنيسيوم لتجديد المجموع الخضري وتقوية البراعم.',
    fertilizerEn:
        'Calcium and Magnesium to regenerate leaf area and root crowns.',
  ),

  'Strawberry___healthy': DiseaseDetail(
    nameAr: 'نبات فراولة سليم',
    nameEn: 'Healthy Strawberry',
    cropAr: 'فراولة',
    cropEn: 'Strawberry',
    descriptionAr: 'نبات الفراولة سليم ونضر وثماره ممتازة.',
    descriptionEn:
        'Strawberry plant is robust with clean foliage and strong runner growth.',
    treatmentsAr: ['فرش قش أو بلاستيك ملش تحت الثمار لمنع ملامسة التربة'],
    treatmentsEn: [
      'Maintain straw or plastic mulch to keep fruit off wet soil',
    ],
    fertilizerAr: 'سماد NPK متوازن + بورون لزيادة عقد الثمار ونسبة السكر.',
    fertilizerEn:
        'Balanced NPK + Boron to boost fruit set, sweetness, and uniform shape.',
  ),

  'Tomato___Bacterial_spot': DiseaseDetail(
    nameAr: 'التبقع البكتيري في الطماطم (البندورة)',
    nameEn: 'Tomato Bacterial Spot',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'بقع صغيرة مائية مسودة على الأوراق والثمار محاطة بهالة صفراء مميزة.',
    descriptionEn:
        'Small water-soaked dark brown leaf spots with distinct yellow halos.',
    treatmentsAr: [
      'رش مركبات النحاس المخلبي مع مانكوزيب',
      'تجنب الري العلوي واستخدام الري بالتنقيط',
    ],
    treatmentsEn: [
      'Spray chelated copper combined with Mancozeb',
      'Use drip irrigation and avoid overhead wetting',
    ],
    fertilizerAr: 'تسميد بوتاسي لتقوية الجدران الخلوية وتجنب زيادة اليوريا.',
    fertilizerEn:
        'Potassium application for cell wall strength; avoid excessive urea.',
  ),

  'Tomato___Early_blight': DiseaseDetail(
    nameAr: 'اللفحة المبكرة في الطماطم (البندورة)',
    nameEn: 'Tomato Early Blight',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'حلقات دائرية متحدة المركز بنية على الأوراق السفلية تجعلها تجف وتسقط.',
    descriptionEn:
        'Concentric target-like brown rings on lower foliage leading to defoliation.',
    treatmentsAr: [
      'إزالة الأوراق السفلية الملامسة للتربة (التوريق)',
      'رش مبيد دايفينوكونازول أو كلوروثالونيل',
    ],
    treatmentsEn: [
      'Prune off lower soil-touching leaves',
      'Apply Difenoconazole or Chlorothalonil fungicide',
    ],
    fertilizerAr:
        'سماد NPK 12-12-36 عالي البوتاسيوم لتقوية النبات وتحجيم الثمار.',
    fertilizerEn:
        'High potassium NPK 12-12-36 for plant vigor and fruit sizing.',
  ),

  'Tomato___Late_blight': DiseaseDetail(
    nameAr: 'اللفحة المتأخرة في الطماطم (البندورة)',
    nameEn: 'Tomato Late Blight',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'بقع زيتية رمادية مائية سريعة الانتشار على الأوراق والسيقان والثمار في الأجواء الرطبة والباردة.',
    descriptionEn:
        'Aggressive oily gray-green lesions on leaves and stems with white mold in humid weather.',
    treatmentsAr: [
      'رش مبيد جهازي عاجل (مانكوزيب + سيموكسانيل أو ميتالاكسيل)',
      'تهوية البيوت البلاستيكية فوراً وتقليل الرطوبة',
    ],
    treatmentsEn: [
      'Urgent systemic fungicide (Mancozeb + Cymoxanil / Metalaxyl)',
      'Ventilate greenhouses to lower ambient humidity',
    ],
    fertilizerAr:
        'فوسفيت البوتاسيوم لتحفيز المقاومة الجهازية الذاتية في النبات.',
    fertilizerEn:
        'Potassium Phosphite to stimulate natural immune defense mechanisms.',
  ),

  'Tomato___Leaf_Mold': DiseaseDetail(
    nameAr: 'عفن الأوراق في الطماطم (البندورة)',
    nameEn: 'Tomato Leaf Mold',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'بقع صفراء باهتة على السطح العلوي يقابلها نمو مخملي رمادي أو زيتوني على السطح السفلي.',
    descriptionEn:
        'Pale yellow spots on upper leaf surfaces with olive-green velvety mold underneath.',
    treatmentsAr: [
      'خفض الرطوبة داخل البيت البلاستيكي بالتهوية المستمرة',
      'رش مبيد فطري وقائي نحاسي',
    ],
    treatmentsEn: [
      'Lower greenhouse humidity with active ventilation',
      'Apply preventative copper fungicide',
    ],
    fertilizerAr: 'تسميد كالسيوم ومغنيسيوم لتعزيز سماكة الأوراق.',
    fertilizerEn:
        'Calcium and Magnesium feeds to boost leaf thickness and photosynthesis.',
  ),

  'Tomato___Septoria_leaf_spot': DiseaseDetail(
    nameAr: 'تبقع أوراق سبتوريا في الطماطم',
    nameEn: 'Tomato Septoria Leaf Spot',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'بقع دائرية صغيرة عديدة رمادية المركز مع حواف بنية داكنة ونقاط سوداء دقيقة بداخلها.',
    descriptionEn:
        'Numerous small circular spots with grayish centers, dark brown borders, and tiny black dots.',
    treatmentsAr: [
      'إزالة الأوراق المصابة والتخلص منها',
      'استخدام مبيد فطري كلوروثالونيل أو مانكوزيب',
    ],
    treatmentsEn: [
      'Remove and destroy infected lower leaves',
      'Apply Chlorothalonil or Mancozeb fungicide',
    ],
    fertilizerAr: 'سماد متوازن وتجنب الإفراط في الري ومراعاة التهوية.',
    fertilizerEn:
        'Balanced nutrition, avoiding overwatering and ensuring plant spacing.',
  ),

  'Tomato___Spider_mites Two-spotted_spider_mite': DiseaseDetail(
    nameAr: 'العناكب الحمراء (حلم الغبار) في الطماطم',
    nameEn: 'Two-Spotted Spider Mite on Tomato',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'نقط صفراء دقيقة جداً ومتقاربة مع وجود خيوط عنكبوتية رفيعة على السطح السفلي للورقة.',
    descriptionEn:
        'Fine yellow stippling on leaves with fine silken webbing on leaf undersides.',
    treatmentsAr: [
      'رش مبيد أكاروسي متخصص (أبامكتين أو بروبارجيت)',
      'غسيل النباتات بالماء لتقليل الغبار الذي ينعش العنكبوت',
    ],
    treatmentsEn: [
      'Apply specialized miticide (Abamectin or Propargite)',
      'Water misting to suppress dust-loving mite populations',
    ],
    fertilizerAr: 'سماد ورقي مغنيسيوم وحديد لتعويض النقص في صبغة الكلوروفيل.',
    fertilizerEn:
        'Foliar Magnesium and Iron to restore damaged chlorophyll pigments.',
  ),

  'Tomato___Target_Spot': DiseaseDetail(
    nameAr: 'التبقع المستهدف (تارجت سبوت) في الطماطم',
    nameEn: 'Tomato Target Spot',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'بقع بنية محددة تشبه لوحة التصويب تسبب تساقط الأوراق وتلف الثمار.',
    descriptionEn:
        'Brown circular target-like lesions on foliage and sunken spots on tomato fruit.',
    treatmentsAr: [
      'رش مبيد أزوكسيستروبين أو كابريو ديو',
      'تحسين حركة الهواء بين الشتلات',
    ],
    treatmentsEn: [
      'Spray Azoxystrobin or Cabrio Duo fungicide',
      'Improve canopy air movement',
    ],
    fertilizerAr: 'سماد متوازن NPK مع كالسيوم بورون.',
    fertilizerEn: 'Balanced NPK with Calcium-Boron supplement.',
  ),

  'Tomato___Tomato_Yellow_Leaf_Curl_Virus': DiseaseDetail(
    nameAr: 'فيروس تجعد واصفرار أوراق الطماطم (TYLCV)',
    nameEn: 'Tomato Yellow Leaf Curl Virus (TYLCV)',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'تقزم شديد للنبات وتجعد الأوراق للأعلى مع اصفرار حوافها وصغر حجم الثمار أو انعدامها.',
    descriptionEn:
        'Severe stunting, upward leaf curling, yellow margins, and flower abortion.',
    treatmentsAr: [
      'مكافحة الذبابة البيضاء الناقلة للفيروس بشدة (مبيد أسيتامبريد أو إيميداكلوبريد)',
      'قلع النباتات المصابة مبكراً لتقليل العدوى',
    ],
    treatmentsEn: [
      'Aggressive whitefly vector control (Acetamiprid or Imidacloprid)',
      'Rogue out infected plants immediately',
    ],
    fertilizerAr:
        'أحماض أمينية + عناصر صغرى وزنك لمساعدة النبات على تحمل الإجهاد ومواصلة النمو.',
    fertilizerEn:
        'Amino acids + zinc and micronutrients to alleviate viral stress.',
  ),

  'Tomato___Tomato_mosaic_virus': DiseaseDetail(
    nameAr: 'فيروس موزايك الطماطم (TMV)',
    nameEn: 'Tomato Mosaic Virus (TMV)',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr:
        'تبقع وتبرقش فاتح وداكن كالموزاييك على الأوراق وتشوه نصل الورقة إلى مظهر شريطي ضيق.',
    descriptionEn:
        'Mottled light and dark green mosaic patterns on foliage, strap-like leaf distortion.',
    treatmentsAr: [
      'تعقيم الأيدي والأدوات بالحليب منزوع الدسم أو الصابون',
      'قلع النبات المصاب والتخلص منه',
    ],
    treatmentsEn: [
      'Sanitize hands and pruners with skim milk or soap',
      'Eradicate and burn infected plants',
    ],
    fertilizerAr: 'منشطات حيوية وهيوميك أسيد لدعم كفاءة المجموع الجذري.',
    fertilizerEn: 'Biostimulants and Humic Acid to support root vigor.',
  ),

  'Tomato___healthy': DiseaseDetail(
    nameAr: 'نبات طماطم (بندورة) سليم',
    nameEn: 'Healthy Tomato Plant',
    cropAr: 'طماطم',
    cropEn: 'Tomato',
    descriptionAr: 'نبات الطماطم سليم وبحالة ممتازة وخالٍ من الأمراض والآفات.',
    descriptionEn:
        'Tomato plant is robust, vigorous, with vibrant green foliage and clean stems.',
    treatmentsAr: ['الاستمرار في الرش الوقائي الدوري والري المنتظم بالتنقيط'],
    treatmentsEn: [
      'Maintain standard preventative spray schedule and drip irrigation',
    ],
    fertilizerAr:
        'برنامج تسميد NPK متوازن (عالي الفوسفور للتجذير، متوازن للنمو، عالي البوتاسيوم للتحجيم).',
    fertilizerEn:
        'Balanced NPK regime (High-P for rooting, Balanced for growth, High-K for sizing).',
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
  final TextEditingController _notesController = TextEditingController();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isClassifying = false;
  String? _statusMessage;
  double? _confidence;

  Map<String, dynamic>? _diseaseResult;
  String? _symptomCategoryTitle;
  String? _symptomAnalysisNote;
  String? _symptomGuidance;
  String? _customFertilizerAdvice;

  List<int> _inputShape = [1, 224, 224, 3];
  int _numClasses = 14;

  String _selectedCropType = 'Auto';
  final List<String> _cropOptions = [
    'Auto',
    'Tomato',
    'Potato',
    'Olive',
    'Wheat',
    'Citrus',
  ];

  final Map<String, String> _cropTranslations = {
    'Tomato': 'طماطم',
    'Potato': 'بطاطس',
    'Olive': 'زيتون',
    'Wheat': 'قمح',
    'Citrus': 'حمضيات',
  };

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
      _interpreter = await Interpreter.fromAsset(
        'assets/plant_disease_model.tflite',
      );

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      _inputShape = List<int>.from(inputTensor.shape);
      _numClasses = outputTensor.shape.last;
      if (inputTensor.type != TensorType.float32 ||
          _inputShape.join(',') != '1,224,224,3' ||
          outputTensor.type != TensorType.float32 ||
          outputTensor.shape.join(',') != '1,14') {
        throw StateError(
          'Unexpected model tensors: input ${inputTensor.shape} '
          '(${inputTensor.type}), output ${outputTensor.shape} '
          '(${outputTensor.type})',
        );
      }

      final response = await rootBundle.loadString('assets/labels.txt');
      final loaded = response
          .split(RegExp(r'\r?\n'))
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty && !label.startsWith('#'))
          .toList();
      if (loaded.length != _numClasses) {
        throw StateError(
          'Expected $_numClasses labels, found ${loaded.length}',
        );
      }

      if (!mounted) return;
      setState(() {
        _labels = loaded;
        _statusMessage = null;
      });
    } catch (e) {
      _interpreter?.close();
      _interpreter = null;
      _labels = [];
      if (!mounted) return;
      setState(() {
        _statusMessage = widget.isArabic
            ? 'تعذر تحميل النموذج: $e'
            : 'Failed to load model: $e';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _diseaseResult = null;
      _confidence = null;
      _statusMessage = null;
      _symptomCategoryTitle = null;
      _symptomAnalysisNote = null;
      _symptomGuidance = null;
      _customFertilizerAdvice = null;
    });

    await _classifyAndDiagnose();
  }

  /// محرك ذكي تفاعلي لتحليل ملاحظات المزارع (المدة، ثبات الحجم، الرطوبة، التزهير، ونقص العناصر)
  ({
    String categoryTitle,
    String analysis,
    String guidance,
    String fertilizer,
    String treatment,
  })
  _analyzeFarmerNotes(String notes, bool isAr) {
    String text = notes.toLowerCase();

    // 1. مدة الإصابة وثبات الحجم / توقف النمو (مثل: "الها شهر نفس الحجم"، "توقف النمو"، "ما بتكبر")
    if (text.contains('نفس الحجم') ||
        text.contains('شهر') ||
        text.contains('توقف النمو') ||
        text.contains('ما بتكبر') ||
        text.contains('ما عم تكبر') ||
        text.contains('واقفة') ||
        text.contains('ركود') ||
        text.contains('بطء النمو') ||
        text.contains('تقزم') ||
        text.contains('stunted') ||
        text.contains('same size') ||
        text.contains('not growing') ||
        text.contains('month')) {
      return (
        categoryTitle: isAr
            ? '⏳ تحليل مدة الإصابة: ثبات الحجم وركود النمو'
            : '⏳ Duration Insight: Stunted Growth & Static Size',
        analysis: isAr
            ? '🔍 تحليل الملاحظة: بقاء النبات أو الأعراض بنفس الحجم لمدة شهر (أو أكثر) يعكس حالة "إجهاد فسيولوجي مزمن وركود نمو" (Chronic Stagnation). هذا الثبات يعني أن المشكلة لم تعد سطحية، بل تدل على كسل المجموع الجذري وتوقف امتصاص الفوسفور والعناصر الكبرى نتيجة برودة أو انضغاط التربة، أو وجود أعفان ونيماتودا خفية تعطل صعود الغذاء للقمم النامية.'
            : '🔍 Observation Analysis: Static lesion expansion or stagnant plant size for a month indicates chronic physiological stagnation. Feeder roots have stalled, blocking Phosphorus and micronutrient uptake due to soil compaction, cold root-zones, or hidden subclinical root rot/nematodes.',
        guidance: isAr
            ? '📋 التوجيه الفوري الموصى به:\r\n1. إجراء عزق (خربشة) سطحي خفيف للتربة حول الشتلة لتهوية الجذور وتصريف الرطوبة الراكدة.\r\n2. فحص أسفل الساق والتاج للتأكد من خلو الجذور من الاسوداد أو التدرنات.\r\n3. تقليم الأوراق السفلية القديمة الراكدة لتوجيه طاقة النبات لإنتاج براعم وأوراق جديدة نضرة.'
            : '📋 Actionable Guidance:\r\n1. Perform gentle shallow hoeing around root flare to aerate compacted soil.\r\n2. Check root collar for browning or nematode galls.\r\n3. Prune stalled lower foliage to redirect energy to fresh vegetative flushes.',
        fertilizer: isAr
            ? '🌱 برنامج كسر السكون وإعادة التنشيط:\r\n• سقاية سماد عالي الفوسفور (NPK 10-52-10 أو MAP) بمعدل 2-3 كغم/دونم لتجديد الشعيرات الجذرية.\r\n• سقاية منشط جذري مركب من "هيوميك أسيد + مستخلص طحالب بحرية" (Seaweed Extract) لكسر طور الركود وتحفيز الهرمونات النباتية (الأوكسينات والسيتوكينينات).'
            : '🌱 Dormancy-Break Program:\r\n• Drench High-Phosphorus fertilizer (NPK 10-52-10 or MAP) at 2-3 kg/dunam.\r\n• Apply Humic Acid + Seaweed Extract drench to stimulate lateral roots and endogenous auxins/cytokinins.',
        treatment: isAr
            ? 'إزالة الأوراق المسنة الراكدة وسقاية مبيد أعفان وقائي خفيف لتطهير محيط الجذور.'
            : 'Remove stagnant older foliage and apply a preventative light root-zone drench.',
      );
    }

    // 2. تفشي حديث ونشط (مثل: "بدأت من يومين"، "من أسبوع"، "سريعة الانتشار")
    if (text.contains('يومين') ||
        text.contains('أسبوع') ||
        text.contains('اسبوع') ||
        text.contains('أمس') ||
        text.contains('امس') ||
        text.contains('جديد') ||
        text.contains('حديث') ||
        text.contains('سريع') ||
        text.contains('recent') ||
        text.contains('yesterday') ||
        text.contains('week') ||
        text.contains('rapid') ||
        text.contains('fast')) {
      return (
        categoryTitle: isAr
            ? '⚡ تفشي حديث ونشط (إصابة في بدايتها)'
            : '⚡ Acute & Early Onset Infection',
        analysis: isAr
            ? '🔍 تحليل الملاحظة: ظهور الأعراض منذ أيام قليلة أو أسبوع مع ملاحظة الانتشار السريع يعني أن الممرض في قمة مرحلة التكاثر النشط وإطلاق الجراثيم المتحركة (Active Sporulation). التدخل في هذا التوقيت المبكر يحقق نسبة شفاء تتجاوز 90% ويمنع تحول البؤرة إلى وباء شامل.'
            : '🔍 Observation Analysis: Onset within days or a week with rapid expansion indicates an active sporulation phase. Early systemic intervention during this window delivers over 90% recovery and halts field epidemics.',
        guidance: isAr
            ? '📋 التوجيه الفوري الموصى به:\r\n1. تطبيق الرش العلاجي بالمبيد المتخصص خلال أول 24 إلى 48 ساعة دون تأخير.\r\n2. الامتناع التام عن لمس النباتات أو تقليمها أثناء وجود الندى الصباحي منعاً لنقل الجراثيم السابحة للأشجار المجاورة.'
            : '📋 Actionable Guidance:\r\n1. Apply targeted therapeutic spray within 24-48 hours.\r\n2. Do not handle or prune foliage while wet with dew to avoid dispersing waterborne spores.',
        fertilizer: isAr
            ? '🌱 دعم المناعة السريعة: رش فوسفيت البوتاسيوم (Potassium Phosphite) لتحفيز مركبات الفيتوالكسين الدفاعية في النبات، مع إيقاف الأسمدة النيتروجينية الحرة مؤقتاً لتجنب إضعاف جدر الخلايا.'
            : '🌱 Rapid Immunity Boost: Foliar Potassium Phosphite to induce phytoalexin defenses; halt free nitrogen fertilizers to avoid tissue softening.',
        treatment: isAr
            ? 'الرش الموضعي الفوري لبؤرة الإصابة والمحيط المباشر لها بمبيد جهازي فعال.'
            : 'Urgent spot-spray of the infection focus and adjacent canopy with systemic fungicide.',
      );
    }

    // 3. إصابة مزمنة طويلة الأمد (مثل: "من زمان"، "شهور"، "طولت وما طابت")
    if (text.contains('من زمان') ||
        text.contains('شهور') ||
        text.contains('قديمة') ||
        text.contains('طولت') ||
        text.contains('ما طابت') ||
        text.contains('ما استجابت') ||
        text.contains('فترة طويلة') ||
        text.contains('chronic') ||
        text.contains('long time') ||
        text.contains('months') ||
        text.contains('persisting')) {
      return (
        categoryTitle: isAr
            ? '🛡️ إصابة مزمنة متكررة'
            : '🛡️ Chronic Persistent Infection',
        analysis: isAr
            ? '🔍 تحليل الملاحظة: استمرار المرض لفترة طويلة دون تحسن يشير غالباً إلى اكتساب الفطر مقاومة ضد المبيد المكرر (Fungicide Resistance)، أو وجود خلل بيئي مستمر مثل فرط الرطوبة الأرضية أو سوء الصرف الذي يحافظ على دورة حياة الممرض نشطة باستمرار.'
            : '🔍 Observation Analysis: Persistence of symptoms over extended weeks or months suggests pathogen fungicide-resistance or persistent conducive conditions (high humidity, poor air drainage, or contaminated soil).',
        guidance: isAr
            ? '📋 التوجيه الفوري الموصى به:\r\n1. التناوب وتغيير مجموعة المبيد الكيميائية (استخدام مبيد بآلية عمل ومجموعة FRAC مختلفة كلياً عن السابق).\r\n2. قطع الأفرع والأوراق المصابة القديمة والتخلص منها بالحرق خارج المزرعة.'
            : '📋 Actionable Guidance:\r\n1. Rotate chemical classes (use a fungicide with a different FRAC mode of action).\r\n2. Prune heavily infested old growth and incinerate off-site.',
        fertilizer: isAr
            ? '🌱 ترميم وتقوية الأنسجة: رش سيليكات البوتاسيوم + سماد متوازن NPK 20-20-20 لإعادة بناء جدر الخلايا التالفة.'
            : '🌱 Tissue Restoration: Foliar Potassium Silicate + balanced NPK 20-20-20 to rebuild damaged cell walls.',
        treatment: isAr
            ? 'تغيير مبيد الرش لمادة فعالة جديدة وتعقيم أدوات التقليم بمحلول الكلور أو الكحول.'
            : 'Switch active ingredient and disinfect pruning tools with alcohol/bleach.',
      );
    }

    // 4. فرط الري والرطوبة وسواد الساق والتعفن (Overwatering & Moisture Stress)
    if (text.contains('ري كثير') ||
        text.contains('تغريق') ||
        text.contains('كل يوم') ||
        text.contains('رطوبة') ||
        text.contains('طين') ||
        text.contains('سواد بالساق') ||
        text.contains('سواد') ||
        text.contains('تعفن') ||
        text.contains('عفن') ||
        text.contains('overwatering') ||
        text.contains('waterlogged') ||
        text.contains('moist') ||
        text.contains('wet') ||
        text.contains('rot') ||
        text.contains('black')) {
      return (
        categoryTitle: isAr
            ? '💧 إجهاد مائي واختناق الجذور'
            : '💧 Waterlogging & Root Hypoxia',
        analysis: isAr
            ? '🔍 تحليل الملاحظة: كثرة الري واستمرار رطوبة التربة يطرد الأكسجين من مسامات الجذور مما يسبب اختناقها (Root Hypoxia) وموت الشعيرات الماصة، ويهيئ بيئة مثالية لفطريات الأعفان (بيثيوم وفيتوفثورا وفطريات الساق).'
            : '🔍 Observation Analysis: Excessive watering deprives roots of oxygen (hypoxia), killing root hairs and triggering destructive soil-borne water molds (Pythium and Phytophthora).',
        guidance: isAr
            ? '📋 التوجيه الفوري الموصى به:\r\n1. إيقاف الري تماماً حتى يجف سطح التربة بعمق 3-5 سم.\r\n2. تحسين مصارف المياه وتجنب ملامسة مياه الري المباشرة لجذع النبات.'
            : '📋 Actionable Guidance:\r\n1. Pause irrigation until top 3-5 cm of soil dries completely.\r\n2. Unclog drainage channels and prevent standing water around plant collars.',
        fertilizer: isAr
            ? '🌱 إيقاف الأسمدة الكيميائية فوراً لتفادي احتراق الجذور المختنقة، وإضافة منشط مناعة فوسفيت بوتاسيوم بعد جفاف التربة.'
            : '🌱 Suspend chemical fertilizers immediately; drench with Potassium Phosphite once soil breathes.',
        treatment: isAr
            ? 'تعطيش فوري ثم سقاية مبيد فطري جهازي متخصص للأعفان (مثل ميتالاكسيل أو هيمكسازول).'
            : 'Withhold water then drench with systemic root-rot fungicide (Metalaxyl or Hymexazol).',
      );
    }

    // 5. العطش والجفاف (Drought / Under-watering)
    if (text.contains('عطش') ||
        text.contains('جفاف') ||
        text.contains('يابسة') ||
        text.contains('قلة الري') ||
        text.contains('ناشفة') ||
        text.contains('ذبول') ||
        text.contains('drought') ||
        text.contains('dry') ||
        text.contains('thirsty') ||
        text.contains('wilting')) {
      return (
        categoryTitle: isAr
            ? '☀️ إجهاد جفاف ونقص مائي'
            : '☀️ Drought & Moisture Deficit Stress',
        analysis: isAr
            ? '🔍 تحليل الملاحظة: جفاف التربة الشديد يؤدي إلى فقدان ضغط الامتلاء وذبول الأوراق وتركيز الأملاح في العصارة النباتية، مما يسبب احتراق أطراف الأوراق وضعف مقاومة النبات للآفات.'
            : '🔍 Observation Analysis: Extreme soil dryness causes loss of turgor pressure, leaf wilting, and sap salinity buildup, scorching leaf margins and lowering pest defense.',
        guidance: isAr
            ? '📋 التوجيه الفوري الموصى به:\r\n1. الري المعتدل المنتظم في الصباح الباكر وتجنب الري وقت الظهيرة الحارة.\r\n2. وضع ملش عضوي (قش أو نشارة) حول مسقط الشتلة لحفظ رطوبة التربة.'
            : '📋 Actionable Guidance:\r\n1. Scheduled moderate watering in early mornings, avoiding peak midday heat.\r\n2. Apply organic mulch around base to conserve soil moisture.',
        fertilizer: isAr
            ? '🌱 رش أحماض أمينية مع بوتاسيوم ومغنيسيوم لتقليل فقد الماء بالنتح واستعادة النضارة.'
            : '🌱 Foliar Amino Acids + Potassium and Magnesium to reduce transpiration and restore turgidity.',
        treatment: isAr
            ? 'تنظيم فترات الري عبر عداد ري أو قياس رطوبة التربة بانتظام.'
            : 'Establish consistent irrigation intervals and monitor soil moisture.',
      );
    }

    // 6. تساقط الأزهار والثمار (Blossom & Fruit Drop / Abortion)
    if (text.contains('تساقط') ||
        text.contains('أزهار') ||
        text.contains('ازهار') ||
        text.contains('ثمار') ||
        text.contains('الزهر') ||
        text.contains('تنفيل') ||
        text.contains('بوقع') ||
        text.contains('بتسقط') ||
        text.contains('flower') ||
        text.contains('blossom') ||
        text.contains('fruit drop') ||
        text.contains('abortion')) {
      return (
        categoryTitle: isAr
            ? '🌸 إجهاد مرحلة التزهير والعقد (تنفيل الأزهار)'
            : '🌸 Bloom & Fruit-Set Stress',
        analysis: isAr
            ? '🔍 تحليل الملاحظة: تساقط الأزهار والعقد الصغير (التنفيل) ينتج غالباً عن تذبذب الري (عطش متبوع بري غزير)، أو نقص عنصري الكالسيوم والبورون المسؤولين عن قوة أنبوب اللقاح وتثبيت العقد.'
            : '🔍 Observation Analysis: Blossom and fruitlet abortion (drop) is triggered by moisture swings or deficiencies in Calcium and Boron, which govern pollen tube vitality and pedicel retention.',
        guidance: isAr
            ? '📋 التوجيه الفوري الموصى به:\r\n1. تثبيت كميات ومواعيد الري تماماً أثناء التزهير دون أي تذبذب.\r\n2. الامتناع عن رش المبيدات الحشرية القوية وقت نشاط حشرات التلقيح (الصباح الباكر).'
            : '📋 Actionable Guidance:\r\n1. Fix exact irrigation volume and schedule during bloom.\r\n2. Halt harsh chemical insecticides during pollinator foraging hours.',
        fertilizer: isAr
            ? '🌱 رش ورقي بمركب كالسيوم-بورون سائل (Cal-Bor) بمعدل 1.5-2 مل/لتر + سماد عالي الفوسفور لتثبيت العقد وزيادة نسبة الإخصاب.'
            : '🌱 Foliar spray with Liquid Calcium-Boron (Cal-Bor) at 1.5-2 ml/L + High-P to secure fruit set.',
        treatment: isAr
            ? 'فحص الأزهار لضمان خلوها من حشرات التربس التي تثقب قواعد الأزهار وتسقطها.'
            : 'Scout blossoms for thrips that pierce flower bases and trigger drop.',
      );
    }

    // 7. اصفرار بين العروق ونقص الحديد
    if (text.contains('عروق خضراء') ||
        text.contains('حديد') ||
        text.contains('قمم') ||
        text.contains('veins') ||
        text.contains('iron')) {
      return (
        categoryTitle: isAr
            ? '🍃 نقص عنصر الحديد (اصفرار بين العروق)'
            : '🍃 Interveinal Iron Chlorosis',
        analysis: isAr
            ? '🔍 تحليل الملاحظة: اصفرار الأوراق الحديثة العلوية مع بقاء العروق خضراء يشير بوضوح لنقص عنصر الحديد المتاح للنبات بسبب قلوية التربة (High pH) أو زيادة الكلس.'
            : '🔍 Observation Analysis: Interveinal chlorosis on top new leaves indicates Iron deficiency caused by alkaline soil pH tie-up.',
        guidance: isAr
            ? '📋 التوجيه الفوري الموصى به: إضافة كبريت زراعي أو حمض فوسفوريك مع ماء الري لتخفيض قلوية التربة وتيسير العناصر.'
            : '📋 Actionable Guidance: Apply sulfur or phosphoric acid to lower rhizosphere pH and liberate micronutrients.',
        fertilizer: isAr
            ? '🌱 سقاية شيلات حديد (EDDHA Iron 6%) بمعدل 5-10 غرام للشتلة مع ماء الري، أو رش ورقي بشيلات EDTA.'
            : '🌱 Soil drench with EDDHA Iron 6% at 5-10g per plant or foliar EDTA Iron.',
        treatment: isAr
            ? 'الري المنتظم وتجنب الإفراط في الفوسفور الذي يرسب الحديد في التربة.'
            : 'Regulate watering and avoid excess phosphorus which binds iron.',
      );
    }

    // 8. اصفرار الأوراق واصفرار الأوراق السفلية
    if (text.contains('اصفرار') ||
        text.contains('أوراق صفراء') ||
        text.contains('صفار') ||
        text.contains('شاحبة') ||
        text.contains('yellow') ||
        text.contains('chlorosis') ||
        text.contains('pale')) {
      return (
        categoryTitle: isAr
            ? '🍂 نقص نيتروجين وإجهاد أوراق سفلية'
            : '🍂 Nitrogen Deficiency & Foliar Yellowing',
        analysis: isAr
            ? '🔍 تحليل الملاحظة: اصفرار الأوراق السفلية والقديمة علامة كلاسيكية على نقص النيتروجين (الآزوت) حيث يسحب النبات العنصر من الأوراق القديمة ليغذي القمم النامية، أو نتيجة اختناق الجذور المؤقت.'
            : '🔍 Observation Analysis: Yellowing of lower/older foliage is classic Nitrogen translocation or temporary root asphyxiation.',
        guidance: isAr
            ? '📋 التوجيه الفوري الموصى به: فحص رطوبة التربة وضبط التسميد على دفعات متوازنة لتجنب غسيل الآزوت.'
            : '📋 Actionable Guidance: Verify soil moisture and split nitrogen feeds into balanced doses.',
        fertilizer: isAr
            ? '🌱 سماد نيتروجيني متوازن NPK 20-20-20 أو نترات الكالسيوم بمعدل معتدل لتجديد الاخضرار.'
            : '🌱 Balanced NPK 20-20-20 or Calcium Nitrate at moderate rates.',
        treatment: isAr
            ? 'إزالة الأوراق الصفراء الميتة لتحسين التهوية والحد من الفطريات الرمية.'
            : 'Remove dead yellow leaves to improve canopy aeration.',
      );
    }

    // 9. احتراق الحواف والملوحة
    if (text.contains('احتراق') ||
        text.contains('حواف') ||
        text.contains('يباس') ||
        text.contains('أملاح') ||
        text.contains('ملوحة') ||
        text.contains('scorch') ||
        text.contains('burn') ||
        text.contains('edge') ||
        text.contains('margin') ||
        text.contains('salinity')) {
      return (
        categoryTitle: isAr
            ? '🧂 إجهاد ملوحة واحتراق الحواف'
            : '🧂 Marginal Scorch & Salinity Stress',
        analysis: isAr
            ? '🔍 تحليل الملاحظة: احتراق حواف الأوراق والتفافها يعكس إجهاد ملوحة ناتجاً عن تراكم الأملاح في ماء الري أو نقص عنصر البوتاسيوم المسؤول عن تنظيم الضغط الأسموزي للخلايا.'
            : '🔍 Observation Analysis: Marginal leaf burn indicates salt accumulation in leaf tips or acute Potassium deficiency impairing osmotic regulation.',
        guidance: isAr
            ? '📋 التوجيه الفوري الموصى به: غسيل التربة برية غزيرة للتخلص من تراكم الأملاح حول الجذور وفحص ملوحة مياه الري (EC).'
            : '📋 Actionable Guidance: Perform leaching irrigation to flush salts away from root zone; test EC of irrigation water.',
        fertilizer: isAr
            ? '🌱 سلفات البوتاسيوم (0-0-50) أو نترات البوتاسيوم + معالج ملوحة سائل (نترات الكالسيوم مع أحماض كربوكسيلية).'
            : '🌱 Potassium Sulfate (0-0-50) + liquid calcium salinity flusher.',
        treatment: isAr
            ? 'الامتناع عن إضافة أسمدة كلوريدية واستخدام أسمدة نقية منخفضة الملوحة.'
            : 'Avoid chloride-based feeds and use low-salt index fertilizers.',
      );
    }

    // 10. التفاف الأوراق والحشرات الماصة
    if (text.contains('التفاف') ||
        text.contains('تجعيد') ||
        text.contains('كرمشة') ||
        text.contains('من') ||
        text.contains('ذبابة') ||
        text.contains('تربس') ||
        text.contains('دودة') ||
        text.contains('حشرات') ||
        text.contains('curling') ||
        text.contains('wrinkled') ||
        text.contains('pests') ||
        text.contains('aphids') ||
        text.contains('whitefly')) {
      return (
        categoryTitle: isAr
            ? '🐛 إجهاد حشري والتفاف الأوراق'
            : '🐛 Sucking Pests & Leaf Distortion',
        analysis: isAr
            ? '🔍 تحليل الملاحظة: تجعد والتفاف الأوراق يشير إلى امتصاص الحشرات الثاقبة الماصة (مثل المن والذبابة والتربس) للعصارة النباتية من السطح السفلي، أو انتقال فيروس نباتي.'
            : '🔍 Observation Analysis: Leaf curling and puckering typically indicates sucking pests (aphids, thrips, whiteflies) drawing sap from leaf undersides, or viral transmission.',
        guidance: isAr
            ? '📋 التوجيه الفوري الموصى به: فحص السطح السفلي للأوراق بعدسة مكبرة، وتركيب مصائد لاصقة صفراء وزرقاء.'
            : '📋 Actionable Guidance: Inspect leaf undersides with a hand lens and install yellow/blue sticky traps.',
        fertilizer: isAr
            ? '🌱 رش سيليكات البوتاسيوم لزيادة صلابة بشرة الأوراق وتقليل قدرة الحشرات على اختراقها.'
            : '🌱 Foliar Potassium Silicate to harden epidermis against insect feeding.',
        treatment: isAr
            ? 'رش مبيد حشري جهازي متخصص (أسيتامبريد أو إيميداكلوبريد أو زيت نيم طبيعي).'
            : 'Apply systemic insecticide (Acetamiprid, Imidacloprid, or neem oil).',
      );
    }

    // 11. الرد الذكي الافتراضي لأي ملاحظة مخصصة أخرى
    return (
      categoryTitle: isAr
          ? '📝 تحليل فسيولوجي لملاحظة المزارع'
          : '📝 Farmer Observation Contextual Analysis',
      analysis: isAr
          ? '🔍 تم ربط ملاحظتك: "${notes.trim()}" مع نتيجة الفحص البصري للذكاء الاصطناعي. تبيّن أن الأعراض المذكورة تعزز التشخيص المكتشف وتتطلب ضبط بيئة النمو والتغذية بالتوازي مع مكافحة المرض.'
          : '🔍 Your observation: "${notes.trim()}" was integrated with the AI vision diagnosis. The reported field condition aligns with the diagnosed pathogen and requires synchronized environmental and nutritional care.',
      guidance: isAr
          ? '📋 التوجيه الفوري الموصى به:\r\n1. متابعة تطور الأعراض يومياً والتحقق من عدم انتشارها للنباتات المجاورة.\r\n2. ضبط التهوية وانتظام الري وتجنب ترطيب الأوراق أثناء التسميد أو الري.'
          : '📋 Actionable Guidance:\r\n1. Monitor symptom progression daily across adjacent crop rows.\r\n2. Maintain canopy aeration, uniform irrigation, and avoid foliage wetting.',
      fertilizer: isAr
          ? '🌱 سماد NPK متوازن 20-20-20 بمعدل منتظم لدعم حيوية المجموع الخضري والمناعة العامة.'
          : '🌱 Balanced NPK 20-20-20 to support overall vigor and disease tolerance.',
      treatment: isAr
          ? 'تنفيذ خطة العلاج الموصى بها بدقة مع الالتزام بفترة الأمان قبل الحصاد (PHI).'
          : 'Execute the recommended treatment plan adhering strictly to Pre-Harvest Intervals (PHI).',
    );
  }

  // ======= خطوة 1: استخراج نوع المحصول من مفتاح الـ label =======
  // يدعم المحاصيل الزراعية الخمسة: Tomato, Potato, Olive, Wheat, Citrus
  String? _extractCropFromLabel(String rawLabel) {
    final lower = rawLabel.toLowerCase().trim();
    if (lower.startsWith('tomato')) return 'Tomato';
    if (lower.startsWith('potato')) return 'Potato';
    if (lower.startsWith('olive')) return 'Olive';
    if (lower.startsWith('wheat')) return 'Wheat';
    if (lower.startsWith('citrus')) return 'Citrus';

    // دعم التسميات المركبة أو أي فاصل آخر
    final parts = rawLabel.split(RegExp(r'___|_'));
    if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
      final p = parts[0].trim().toLowerCase();
      if (p == 'tomato') return 'Tomato';
      if (p == 'potato') return 'Potato';
      if (p == 'olive') return 'Olive';
      if (p == 'wheat') return 'Wheat';
      if (p == 'citrus') return 'Citrus';
      return parts[0].trim();
    }
    return null;
  }

  Future<void> _classifyAndDiagnose() async {
    if (_isClassifying) return;
    final isAr = widget.isArabic;

    if (_interpreter == null) {
      await _loadModelAndLabels();
    }
    if (_interpreter == null) {
      if (!mounted) return;
      setState(
        () => _statusMessage ??= isAr
            ? '???? ????? ???????. ???? ?? ????? ??????? ???????.'
            : 'Model could not be loaded. Check the model and labels assets.',
      );
      return;
    }
    if (_image == null) {
      if (!mounted) return;
      setState(
        () => _statusMessage = isAr
            ? 'الرجاء اختيار أو التقاط صورة أولاً.'
            : 'Please select an image first.',
      );
      return;
    }

    setState(() {
      _isClassifying = true;
      // خطوة 1: نبدأ بالتعرف على نوع النبات
      _statusMessage = isAr
          ? '🌿 جاري التعرف على نوع المحصول...'
          : '🌿 Identifying the crop type...';
      _diseaseResult = null;
    });

    try {
      final imageBytes = await _image!.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        throw Exception(
          isAr ? 'تعذر قراءة ملف الصورة' : 'Could not decode image',
        );
      }

      final height = _inputShape.length >= 3 ? _inputShape[1] : 224;
      final width = _inputShape.length >= 3 ? _inputShape[2] : 224;

      final input = _imageToFloat32Tensor(decoded, width, height);
      final output = List.filled(
        1 * _numClasses,
        0.0,
      ).reshape([1, _numClasses]);

      _interpreter!.run(input, output);

      final result = List<double>.from(
        (output[0] as List).map((e) => (e as num).toDouble()),
      );

      if (result.length != _labels.length || result.length != _numClasses) {
        throw StateError(
          'Model returned ${result.length} scores for ${_labels.length} labels',
        );
      }

      // Pick the highest-scoring class, optionally limited to the selected crop.
      final candidateIndices = <int>[];
      for (int i = 0; i < result.length; i++) {
        final crop = _extractCropFromLabel(_labels[i]);
        if (crop != null &&
            (_selectedCropType == 'Auto' ||
                crop.toLowerCase() == _selectedCropType.toLowerCase())) {
          candidateIndices.add(i);
        }
      }
      if (candidateIndices.isEmpty) {
        throw StateError('No model labels match the selected crop');
      }

      final diseaseIndex = candidateIndices.reduce(
        (best, index) => result[index] > result[best] ? index : best,
      );
      final detectedCrop = _extractCropFromLabel(_labels[diseaseIndex]);
      if (detectedCrop == null) {
        throw StateError('Predicted label has no recognized crop');
      }
      final maxVal = result[diseaseIndex];
      final diseaseRawKey = _labels[diseaseIndex];

      // ======= Step 2: Disease Detection =======
      if (mounted) {
        setState(() {
          _statusMessage = isAr
              ? '🔬 تم التعرف على: "$detectedCrop" — جاري فحص الأمراض...'
              : '🔬 Detected "$detectedCrop" — scanning for diseases...';
        });
      }

      // البحث في قاموس الأمراض ثنائي اللغة مع دعم المطابقة الدقيقة والمرنة
      DiseaseDetail? bilingualInfo = kPlantDiseasesBilingual[diseaseRawKey];
      if (bilingualInfo == null) {
        final cleanKey = diseaseRawKey.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
        for (final entry in kPlantDiseasesBilingual.entries) {
          if (entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
              cleanKey) {
            bilingualInfo = entry.value;
            break;
          }
        }
      }
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
          'description': isAr
              ? bilingualInfo.descriptionAr
              : bilingualInfo.descriptionEn,
          'treatments': isAr
              ? List<String>.from(bilingualInfo.treatmentsAr)
              : List<String>.from(bilingualInfo.treatmentsEn),
          'fertilizer': isAr
              ? bilingualInfo.fertilizerAr
              : bilingualInfo.fertilizerEn,
        };
      } else {
        final lookupResult = DiseaseLookupResult.fallback(diseaseRawKey);
        finalData = lookupResult.data;
        // استخراج أسماء المحصول والمرض من بيانات الخدمة
        cropNameAr = _cropTranslations[detectedCrop] ?? detectedCrop;
        cropNameEn = detectedCrop;
        finalData['crop'] = isAr ? cropNameAr : cropNameEn;
        diseaseAr = finalData['name']?.toString() ?? diseaseRawKey;
        diseaseEn = finalData['name']?.toString() ?? diseaseRawKey;
      }

      String? customCategory;
      String? customAnalysis;
      String? customGuidance;
      String? customFert;
      if (_notesController.text.trim().isNotEmpty) {
        final noteResult = _analyzeFarmerNotes(
          _notesController.text.trim(),
          isAr,
        );
        customCategory = noteResult.categoryTitle;
        customAnalysis = noteResult.analysis;
        customGuidance = noteResult.guidance;
        customFert = noteResult.fertilizer;
        if (noteResult.treatment.isNotEmpty &&
            finalData['treatments'] is List) {
          (finalData['treatments'] as List).insert(0, noteResult.treatment);
        }
      }

      // حفظ التشخيص تلقائياً في السجل التاريخي لقاعدة البيانات
      // Render the local diagnosis before starting optional Firebase work.
      if (!mounted) return;
      setState(() {
        _confidence = maxVal;
        _diseaseResult = finalData;
        _symptomCategoryTitle = customCategory;
        _symptomAnalysisNote = customAnalysis;
        _symptomGuidance = customGuidance;
        _customFertilizerAdvice = customFert;
        _statusMessage = FarmSessionService.canSaveDiagnosis
            ? null
            : (isAr
                  ? 'اكتمل التشخيص محليًا. لا تتوفر صلاحية حفظ السجل أو مزامنته.'
                  : 'Diagnosis completed locally. Saving and sync permission is unavailable.');
      });

      final farmCode = FarmSessionService.currentFarmCode;
      if (farmCode.isNotEmpty && FarmSessionService.canSaveDiagnosis) {
        final userProfile = FarmSessionService.currentUserProfile.value;
        unawaited(
          _persistDiagnosisInBackground(
            farmCode: farmCode,
            record: {
              'farm_code': farmCode,
              'crop_name_ar': cropNameAr,
              'crop_name_en': cropNameEn,
              'disease_name_ar': diseaseAr,
              'disease_name_en': diseaseEn,
              'disease_raw_key': diseaseRawKey,
              'confidence': maxVal,
              'notes': _notesController.text.trim(),
              'note_category': customCategory,
              'note_analysis': customAnalysis,
              'note_guidance': customGuidance,
              'fertilizer': customFert ?? finalData['fertilizer'],
              'treatments': finalData['treatments'],
              'created_by_uid': FirebaseAuth.instance.currentUser?.uid ?? '',
              'created_by_name': userProfile?['name']?.toString() ?? 'Unknown',
              'created_by_role': userProfile?['role']?.toString() ?? 'worker',
              'createdAt': FieldValue.serverTimestamp(),
            },
            notify: !diseaseRawKey.contains('healthy'),
            cropName: isAr ? cropNameAr : cropNameEn,
            diseaseAr: diseaseAr,
            diseaseEn: diseaseEn,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final isUnknownCrop = e.toString().contains('نوع المحصول غير معروف');
      setState(() {
        _statusMessage = isUnknownCrop
            ? (isAr ? 'نوع المحصول غير معروف' : 'Unknown crop type')
            : (isAr ? 'فشل التحليل: $e' : 'Analysis failed: $e');
      });
    } finally {
      if (mounted) {
        setState(() => _isClassifying = false);
      }
    }
  }

  Future<void> _persistDiagnosisInBackground({
    required String farmCode,
    required Map<String, dynamic> record,
    required bool notify,
    required String cropName,
    required String diseaseAr,
    required String diseaseEn,
  }) async {
    if (!FarmSessionService.canSaveDiagnosis) return;
    try {
      await FirebaseFirestore.instance
          .collection('diagnosis_history')
          .add(record);
      if (notify) {
        await FarmNotificationService.notifyDiseaseDetected(
          cropName,
          diseaseAr,
          diseaseEn,
          farmCode,
        );
      }
    } catch (_) {
      // The local diagnosis is already visible; syncing is best effort.
    }
  }

  /// ==========================================================================
  /// [Image Preprocessing Engine]
  /// Converts a decoded image to a Float32 tensor ready for TFLite inference.
  ///
  /// Pipeline (must match training exactly):
  ///   1. Resize to [width x height] — matches model input shape (224x224)
  ///   2. Normalize pixel values: pixel / 255.0  →  range [0.0, 1.0]
  ///      ⚠️ This matches `ImageDataGenerator(rescale=1./255)` used in training.
  ///   3. Output shape: [1, height, width, 3]  (batch=1, H, W, RGB)
  /// ==========================================================================
  Object _imageToFloat32Tensor(img.Image image, int width, int height) {
    final resized = img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear, // Bilinear — standard for CNNs
    );
    final floats = Float32List(1 * height * width * 3);
    var i = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = resized.getPixel(x, y);
        // Normalize to [0, 1] — matches training rescale=1./255
        floats[i++] = pixel.r.toDouble() / 255.0;
        floats[i++] = pixel.g.toDouble() / 255.0;
        floats[i++] = pixel.b.toDouble() / 255.0;
      }
    }
    return floats.reshape([1, height, width, 3]);
  }

  String _formatTreatments(dynamic treatments, bool isAr) {
    if (treatments == null) {
      return isAr ? 'لا توجد علاجات مسجّلة' : 'No recorded treatments';
    }
    if (treatments is List) {
      if (treatments.isEmpty) {
        return isAr ? 'لا توجد علاجات مسجّلة' : 'No recorded treatments';
      }
      return treatments.map((e) => '• $e').join('\r\n');
    }
    return treatments.toString();
  }

  // ======= حذف سجل تشخيص مع تأكيد =======
  Future<void> _deleteDiagnosisRecord(
    BuildContext ctx,
    String docId,
    bool isAr,
    String diseaseName,
  ) async {
    final canDelete =
        FarmSessionService.isManager ||
        FarmSessionService.allowWorkerDelete.value;
    if (!canDelete) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'لا تملك الصلاحية لحذف هذا السجل'
                  : 'You do not have permission to delete this record',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              isAr ? 'تأكيد الحذف' : 'Confirm Delete',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد من حذف سجل التشخيص "$diseaseName"؟\r\nلا يمكن التراجع عن هذه العملية.'
              : 'Are you sure you want to delete the diagnosis record "$diseaseName"?\r\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              isAr ? 'حذف نهائياً' : 'Delete',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('diagnosis_history')
            .doc(docId)
            .delete();
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'تم حذف سجل التشخيص بنجاح ✅'
                    : 'Diagnosis record deleted successfully ✅',
              ),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(isAr ? 'خطأ أثناء الحذف: $e' : 'Delete failed: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  void _showDiagnosisHistoryBottomSheet(BuildContext ctx, bool isAr) {
    final farmCode = FarmSessionService.currentFarmCode;
    // تحديد صلاحية الحذف: المالك والمدير والآدمن فقط
    final canDelete =
        FarmSessionService.isManager ||
        FarmSessionService.allowWorkerDelete.value;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            height: MediaQuery.of(sheetCtx).size.height * 0.80,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isAr
                            ? '📋 سجل الفحوصات والتشخيصات السابقة'
                            : '📋 Past Diagnosis History',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                // شريط الصلاحيات — يُظهر للمستخدم ما إذا كان بإمكانه الحذف
                if (!canDelete)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'عرض فقط — صلاحية الحذف مقتصرة على المدير والمالك'
                                : 'View only — deletion is restricted to Admin/Owner',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('diagnosis_history')
                        .where(
                          'farm_code',
                          isEqualTo: farmCode.isEmpty
                              ? 'FARM-DEFAULT'
                              : farmCode,
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32),
                          ),
                        );
                      }

                      var docs = snapshot.hasData ? snapshot.data!.docs : [];

                      // ترتيب تنازلي حسب التاريخ (الأحدث أولاً)
                      docs.sort((a, b) {
                        final aTime =
                            (a.data() as Map<String, dynamic>)['createdAt']
                                as Timestamp?;
                        final bTime =
                            (b.data() as Map<String, dynamic>)['createdAt']
                                as Timestamp?;
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
                              Icon(
                                Icons.history_rounded,
                                size: 56,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isAr
                                    ? 'لا توجد فحوصات سابقة مسجلة'
                                    : 'No recorded scan history yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr
                                    ? 'التقط صورة نبات لبدء التشخيص'
                                    : 'Snap a plant photo to start diagnosing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, idx) {
                          final doc = docs[idx];
                          final docId = doc.id;
                          final d = doc.data() as Map<String, dynamic>;
                          final diseaseName = isAr
                              ? (d['disease_name_ar'] ??
                                    d['disease_raw_key'] ??
                                    '')
                              : (d['disease_name_en'] ??
                                    d['disease_raw_key'] ??
                                    '');
                          final crop = isAr
                              ? (d['crop_name_ar'] ?? 'محصول')
                              : (d['crop_name_en'] ?? 'Crop');
                          final double conf = (d['confidence'] is num)
                              ? (d['confidence'] as num).toDouble()
                              : 0.0;
                          final notes = d['notes']?.toString() ?? '';
                          final fert = d['fertilizer']?.toString() ?? '';
                          final Timestamp? ts = d['createdAt'] as Timestamp?;
                          final bool isHealthy =
                              (d['disease_raw_key']?.toString() ?? '').contains(
                                'healthy',
                              );
                          final docCreatorName =
                              d['created_by_name']?.toString() ?? '';

                          final hasDeletePermission = canDelete;

                          String dateStr = '';
                          if (ts != null) {
                            final dt = ts.toDate();
                            dateStr =
                                '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
                                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          }

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isHealthy
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                              ),
                            ),
                            child: ExpansionTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isHealthy
                                      ? const Color(0xFFE8F5E9)
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isHealthy
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.spa_rounded,
                                  color: isHealthy
                                      ? const Color(0xFF2E7D32)
                                      : Colors.orange.shade800,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                '$crop: $diseaseName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$dateStr · ${isAr ? 'دقة' : 'Conf'}: ${(conf * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (docCreatorName.isNotEmpty)
                                    Text(
                                      '${isAr ? 'بواسطة' : 'by'}: $docCreatorName',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                              // ===== زر الحذف =====
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasDeletePermission)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      tooltip: isAr
                                          ? 'حذف هذا السجل'
                                          : 'Delete record',
                                      onPressed: () => _deleteDiagnosisRecord(
                                        sheetCtx,
                                        docId,
                                        isAr,
                                        '$crop: $diseaseName',
                                      ),
                                    )
                                  else
                                    IconButton(
                                      icon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: Colors.grey.shade400,
                                        size: 18,
                                      ),
                                      tooltip: isAr
                                          ? 'لا تملك الصلاحية لحذف هذا السجل'
                                          : 'You do not have permission to delete this record',
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isAr
                                                  ? '🔒 لا تملك الصلاحية لحذف هذا السجل'
                                                  : '🔒 You do not have permission to delete this record',
                                            ),
                                            backgroundColor:
                                                Colors.orange.shade800,
                                          ),
                                        );
                                      },
                                    ),
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (notes.isNotEmpty) ...[
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.notes_rounded,
                                              size: 14,
                                              color: Colors.blueGrey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                isAr
                                                    ? 'ملاحظات المزارع: $notes'
                                                    : 'Farmer Notes: $notes',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      if (fert.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F8E9),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                '🌱',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  isAr
                                                      ? 'السماد الموصى به:\r\n$fert'
                                                      : 'Recommended Fertilizer:\r\n$fert',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.green.shade900,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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

  Widget _buildQuickNoteChip(String label, String noteText) {
    final isSelected = _notesController.text.trim() == noteText.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          if (isSelected) {
            _notesController.clear();
          } else {
            _notesController.text = noteText;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    bool isLowConfidence = _confidence != null && _confidence! < 0.35;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: TerraTheme.mist,
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
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0E7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TerraTheme.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android_rounded, color: TerraTheme.forest),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'يعمل تشخيص الصورة على الجهاز. مزامنة سجل التشخيص تحتاج إلى اتصال وصلاحية.'
                            : 'Image diagnosis runs on this device. Syncing history requires connection and permission.',
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              // اختيار المحصول يدوياً
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCropType,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.grass_rounded,
                      color: Color(0xFF2E7D32),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    labelText: isAr
                        ? 'حدد نوع النبات (لزيادة الدقة)'
                        : 'Select Plant Type (for better accuracy)',
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down_circle,
                    color: Color(0xFF2E7D32),
                  ),
                  items: _cropOptions.map((crop) {
                    String displayText = crop;
                    if (crop == 'Auto') {
                      displayText = isAr
                          ? 'الكل (كشف ذكي وتلقائي للمحصول)'
                          : 'All (Auto-detect crop)';
                    } else if (isAr) {
                      displayText =
                          '${_cropTranslations[crop] ?? crop} ($crop)';
                    }

                    return DropdownMenuItem(
                      value: crop,
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontWeight: crop == 'Auto'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: crop == 'Auto'
                              ? const Color(0xFF2E7D32)
                              : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCropType = val);
                  },
                ),
              ),

              // مربع الصورة وأدوات الالتقاط
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                                const Icon(Icons.eco_outlined, size: 38, color: TerraTheme.olive),
                                const SizedBox(height: 10),
                                Text(
                                  isAr
                                      ? 'صور الورقة عن قرب للحصول على أعلى دقة'
                                      : 'Take a close-up photo of the leaf for best accuracy',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _image = null;
                                        _diseaseResult = null;
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      color: Colors.white,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              visualDensity: VisualDensity.compact,
                              foregroundColor: const Color(0xFF2E7D32),
                              side: BorderSide(color: Colors.green.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isClassifying
                                ? null
                                : () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: Text(isAr ? 'كاميرا' : 'Camera'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              visualDensity: VisualDensity.compact,
                              foregroundColor: Colors.teal.shade800,
                              side: BorderSide(color: Colors.teal.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isClassifying
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: Text(isAr ? 'معرض الصور' : 'Gallery'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ملاحظة المزارع التفاعلية والذكية
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAr
                                    ? 'ملاحظة حالة النبات (تحليل ذكي)'
                                    : 'Plant State Note (AI Analysis)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAr
                                  ? 'اختياري · لزيادة الدقة'
                                  : 'Optional · Higher accuracy',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: isAr
                              ? 'مثال: "الها شهر نفس الحجم"، "بدأت منذ أسبوع"، "تساقط بالأزهار"...'
                              : 'e.g. "Stunted size for a month", "Infection started a week ago"...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FBF9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2E7D32),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          suffixIcon: _notesController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() => _notesController.clear());
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      // أزرار الاقتراحات السريعة التفاعلية
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickNoteChip(
                              isAr
                                  ? '⏳ الها شهر نفس الحجم'
                                  : '⏳ Same size for month',
                              'الها شهر نفس الحجم',
                            ),
                            const SizedBox(width: 6),
                            _buildQuickNoteChip(
                              isAr ? '⚡ بدأت منذ أسبوع' : '⚡ Started week ago',
                              'بدأت الإصابة منذ أسبوع وسريعة الانتشار',
                            ),
                            const SizedBox(width: 6),
                            _buildQuickNoteChip(
                              isAr ? '🍂 اصفرار من تحت' : '🍂 Lower yellowing',
                              'اصفرار الأوراق السفلية القديمة',
                            ),
                            const SizedBox(width: 6),
                            _buildQuickNoteChip(
                              isAr
                                  ? '💧 ري يومي والتربة رطبة'
                                  : '💧 Daily watering',
                              'الري يومي والتربة رطبة باستمرار',
                            ),
                            const SizedBox(width: 6),
                            _buildQuickNoteChip(
                              isAr ? '🌸 تساقط في الأزهار' : '🌸 Flower drop',
                              'تساقط الأزهار والعقد الصغير',
                            ),
                            const SizedBox(width: 6),
                            _buildQuickNoteChip(
                              isAr ? '🔥 احتراق في الحواف' : '🔥 Edge burning',
                              'احتراق والتفاف حواف الأوراق',
                            ),
                          ],
                        ),
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
                  onPressed: (_isClassifying || _image == null)
                      ? null
                      : _classifyAndDiagnose,
                  icon: _isClassifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isClassifying
                        ? (isAr ? 'جاري الفحص الدقيق...' : 'Diagnosing...')
                        : (isAr
                              ? 'تشخيص الحالة وإيجاد السماد المناسب'
                              : 'Diagnose & Get Fertilizer Plan'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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
                    color:
                        _statusMessage!.startsWith('فشل') ||
                            _statusMessage!.startsWith('Failed')
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          _statusMessage!.startsWith('فشل') ||
                              _statusMessage!.startsWith('Failed')
                          ? Colors.red.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _statusMessage!.startsWith('فشل') ||
                              _statusMessage!.startsWith('Failed')
                          ? Colors.red.shade800
                          : Colors.orange.shade900,
                    ),
                  ),
                ),

              // 4. بطاقة نتائج التشخيص المتكاملة
              if (_diseaseResult != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TerraTheme.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TerraTheme.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.offline_bolt_rounded, color: TerraTheme.forest),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'نتيجة النموذج محلية واستدلالية؛ راجع مختصًا قبل اتخاذ قرار علاجي.'
                              : 'This is a local model estimate. Consult an agronomist before treatment decisions.',
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
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
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber.shade800,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr
                                    ? 'تنبيه: درجة مطابقة النموذج منخفضة (${(_confidence! * 100).toStringAsFixed(1)}%)'
                                    : 'Notice: Low model score (${(_confidence! * 100).toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAr
                                    ? 'النموذج مدرب أساساً على أوراق النبات المقربة. تم الاستناد لملاحظاتك لإعطاء أفضل توصية سمادية.'
                                    : 'The vision model is trained on close leaf images. Symptoms notes were used to provide optimal nutrition advice.',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                                _diseaseResult!['name'] ??
                                    (isAr ? 'تشخيص نباتي' : 'Diagnosis Result'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            if (_confidence != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isLowConfidence
                                      ? Colors.orange.shade100
                                      : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${isAr ? 'درجة النموذج' : 'Model score'}: ${(_confidence! * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isLowConfidence
                                        ? Colors.orange.shade900
                                        : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),

                        Text(
                          isAr
                              ? '📖 الوصف والأعراض:'
                              : '📖 Disease Overview & Symptoms:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _diseaseResult!['description'] ??
                              (isAr
                                  ? 'لا يوجد وصف متاح.'
                                  : 'No description available.'),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        if (_symptomAnalysisNote != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F7FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF90CAF9),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1976D2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.psychology_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isAr
                                            ? 'تحليل ذكي لملاحظة المزارع'
                                            : 'AI Agronomist Note Insight',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF0D47A1),
                                        ),
                                      ),
                                    ),
                                    if (_symptomCategoryTitle != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE3F2FD),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF90CAF9),
                                          ),
                                        ),
                                        child: Text(
                                          _symptomCategoryTitle!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1565C0),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const Divider(
                                  height: 18,
                                  color: Color(0xFFBBDEFB),
                                ),
                                Text(
                                  _symptomAnalysisNote!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1A237E),
                                    height: 1.45,
                                  ),
                                ),
                                if (_symptomGuidance != null &&
                                    _symptomGuidance!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFBBDEFB),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '💡',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _symptomGuidance!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueGrey.shade800,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade50,
                                Colors.teal.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.eco,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAr
                                        ? '🌱 السماد والتغذية الموصى بها:'
                                        : '🌱 Recommended Fertilizer & Nutrition:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _customFertilizerAdvice ??
                                    (_diseaseResult!['fertilizer'] ??
                                        (isAr
                                            ? 'سماد متوازن NPK 20-20-20 لدعم حيوية النبات.'
                                            : 'Balanced NPK 20-20-20 to support vigor.')),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          isAr
                              ? '🛡️ الإجراءات العلاجية والمكافحة:'
                              : '🛡️ Actionable Treatment & Care:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTreatments(
                            _diseaseResult!['treatments'],
                            isAr,
                          ),
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
