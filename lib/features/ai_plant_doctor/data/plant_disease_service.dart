import 'package:cloud_firestore/cloud_firestore.dart';

/// نتيجة البحث عن تفاصيل المرض — من Firestore أو محلياً (Fallback).
class DiseaseLookupResult {
  const DiseaseLookupResult({
    required this.data,
    required this.fromFirestore,
    this.matchedDocumentId,
    this.isFallback = false,
  });

  final Map<String, dynamic> data;
  final bool fromFirestore;
  final String? matchedDocumentId;
  final bool isFallback;

  factory DiseaseLookupResult.fromFirestore(
    Map<String, dynamic> raw,
    String documentId,
  ) {
    return DiseaseLookupResult(
      data: Map<String, dynamic>.from(raw),
      fromFirestore: true,
      matchedDocumentId: documentId,
    );
  }

  factory DiseaseLookupResult.fallback(String predictedLabel) {
    final displayName = PlantDiseaseService.formatDisplayName(predictedLabel);
    return DiseaseLookupResult(
      data: {
        'name': displayName,
        'description':
            'تم تشخيص "$displayName" محلياً عبر الذكاء الاصطناعي. '
            'لا توجد تفاصيل إضافية في قاعدة البيانات حالياً، '
            'وسيتم إضافتها لاحقاً. يُنصح بمراجعة مختص زراعي عند الحاجة.',
        'treatments': <String>[],
      },
      fromFirestore: false,
      isFallback: true,
    );
  }
}

/// خدمة جلب تفاصيل الأمراض من Firestore مع مطابقة مرنة للأسماء.
class PlantDiseaseService {
  PlantDiseaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'plant_diseases';

  final FirebaseFirestore _firestore;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _cachedDocs;

  /// يحوّل اسم الفئة من النموذج إلى اسم عرض مقروء.
  static String formatDisplayName(String label) {
    return label
        .replaceAll('___', ' · ')
        .replaceAll('__', ' · ')
        .replaceAll('_', ' ')
        .trim();
  }

  /// يُ normalizes المفتاح للمقارنة المرنة (يتجاهل الشرطات والمسافات والحالة).
  static String normalizeKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[_\s\-\.,]+'), '')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]'), '');
  }

  /// يُولّد قائمة معرفات محتملة للمستند في Firestore.
  List<String> candidateDocumentIds(String diseaseName) {
    final candidates = <String>{
      diseaseName,
      diseaseName.replaceAll('___', '__'),
      diseaseName.replaceAll('__', '___'),
    };

    if (diseaseName == 'Healthy') {
      candidates.addAll([
        'Tomato___healthy',
        'Tomato__healthy',
        'healthy',
      ]);
    }

    return candidates.where((id) => id.isNotEmpty).toList();
  }

  Future<DiseaseLookupResult> lookup(String predictedLabel) async {
    if (predictedLabel.isEmpty) {
      return DiseaseLookupResult.fallback(predictedLabel);
    }

    try {
      // 1) مطابقة مباشرة بعدة أشكال للـ Document ID
      for (final docId in candidateDocumentIds(predictedLabel)) {
        final doc = await _firestore.collection(collectionName).doc(docId).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data.isNotEmpty) {
            return DiseaseLookupResult.fromFirestore(data, doc.id);
          }
        }
      }

      // 2) مطابقة مرنة على معرفات المستندات الموجودة
      final normalizedTarget = normalizeKey(predictedLabel);
      final allDocs = await _loadAllDiseaseDocs();

      QueryDocumentSnapshot<Map<String, dynamic>>? bestMatch;
      for (final doc in allDocs) {
        if (normalizeKey(doc.id) == normalizedTarget) {
          bestMatch = doc;
          break;
        }
      }

      // 3) مطابقة جزئية آمنة: نفس المحصول + نفس المرض
      if (bestMatch == null) {
        final targetParts = _splitLabelParts(predictedLabel);
        for (final doc in allDocs) {
          final docParts = _splitLabelParts(doc.id);
          if (targetParts.plant.isNotEmpty &&
              docParts.plant.isNotEmpty &&
              normalizeKey(targetParts.plant) == normalizeKey(docParts.plant) &&
              normalizeKey(targetParts.disease) ==
                  normalizeKey(docParts.disease)) {
            bestMatch = doc;
            break;
          }
        }
      }

      if (bestMatch != null) {
        return DiseaseLookupResult.fromFirestore(bestMatch.data(), bestMatch.id);
      }

      // 4) Fallback — عرض التشخيص المحلي بدون إيقاف التطبيق
      return DiseaseLookupResult.fallback(predictedLabel);
    } catch (_) {
      return DiseaseLookupResult.fallback(predictedLabel);
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _loadAllDiseaseDocs() async {
    _cachedDocs ??=
        (await _firestore.collection(collectionName).get()).docs;
    return _cachedDocs!;
  }

  /// يفصل اسم المحصول عن اسم المرض من معرف PlantVillage.
  ({String plant, String disease}) _splitLabelParts(String label) {
    for (final separator in ['___', '__']) {
      if (label.contains(separator)) {
        final parts = label.split(separator);
        if (parts.length >= 2) {
          return (
            plant: parts.first.trim(),
            disease: parts.sublist(1).join(separator).trim(),
          );
        }
      }
    }
    return (plant: '', disease: label.trim());
  }
}
