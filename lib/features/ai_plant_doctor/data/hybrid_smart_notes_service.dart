import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HybridNoteResult {
  final bool online;
  final String recommendation;

  const HybridNoteResult({required this.online, required this.recommendation});
}

class HybridSmartNotesService {
  static const _historyKey = 'hybrid_smart_notes_history';
  static const _connectivityUri = 'https://www.google.com/generate_204';
  static const supportedCrops = {
    'Citrus',
    'Olive',
    'Potato',
    'Tomato',
    'Wheat',
  };
  static const supportedDiseaseKeys = {
    'citrus_Sooty Mould',
    'citrus_citrus_canker',
    'citrus_healthy',
    'olive_healthy',
    'olive_peacock_spot',
    'potato_Early_Blight',
    'potato_Late_blight',
    'potato_healthy',
    'tomato_early_blight',
    'tomato_healthy',
    'tomato_late_blight',
    'wheat_Brown_Rust',
    'wheat_healthy',
    'wheat_yellow_rust',
  };

  static Future<HybridNoteResult> analyze({
    required String note,
    required String localAnalysis,
    required String language,
    required String crop,
    required String diseaseKey,
  }) async {
    if (note.trim().isEmpty) {
      return const HybridNoteResult(online: false, recommendation: '');
    }
    if (!supportedCrops.contains(crop) ||
        !_isSupportedDiseaseKey(diseaseKey, crop)) {
      return HybridNoteResult(online: false, recommendation: localAnalysis);
    }

    final online = await _hasInternet();
    if (!online) {
      return HybridNoteResult(online: false, recommendation: localAnalysis);
    }

    try {
      final prompt = language == 'ar'
          ? 'أنت مساعد زراعي للمزارعين في الأردن. '
                'حلل ملاحظة المزارع التالية باختصار وقدم توصية عملية آمنة. '
                'لا تجزم بالتشخيص ولا تذكر جرعات مبيدات. '
                'المحصول المعتمد: $crop\nالمرض المعتمد: $diseaseKey\n'
                'الملاحظة: $note\nالتحليل المحلي: $localAnalysis'
          : 'You are an agricultural assistant for farmers in Jordan. '
                'Analyze this farmer note briefly and give a safe practical recommendation. '
                'Do not claim certainty or provide pesticide dosages. '
                'Approved crop: $crop\nApproved disease: $diseaseKey\n'
                'Note: $note\nLocal analysis: $localAnalysis';
      final uri = Uri.https(
        'text.pollinations.ai',
        '/${Uri.encodeComponent(prompt)}',
        {'model': 'openai', 'seed': '42'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final text = response.body.trim();
        if (text.isNotEmpty) {
          return HybridNoteResult(online: true, recommendation: text);
        }
      }
    } catch (_) {
      // Offline/local analysis remains the safe fallback.
    }

    return HybridNoteResult(online: false, recommendation: localAnalysis);
  }

  static bool _isSupportedDiseaseKey(String key, String crop) {
    return supportedDiseaseKeys.contains(key) &&
        key.toLowerCase().startsWith('${crop.toLowerCase()}_');
  }

  static Future<bool> _hasInternet() async {
    try {
      final response = await http
          .get(Uri.parse(_connectivityUri))
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      try {
        final result = await InternetAddress.lookup(
          'text.pollinations.ai',
        ).timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  static Future<void> saveLocal({required Map<String, dynamic> record}) async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getStringList(_historyKey) ?? <String>[];
    final values = existing
        .map((item) => jsonDecode(item))
        .whereType<Map<String, dynamic>>()
        .toList();
    values.insert(0, record);
    if (values.length > 100) {
      values.removeRange(100, values.length);
    }
    await preferences.setStringList(
      _historyKey,
      values.map(jsonEncode).toList(),
    );
  }

  static Future<List<Map<String, dynamic>>> loadLocal({String? userUid}) async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_historyKey) ?? <String>[];
    return values
        .map((item) {
          try {
            return jsonDecode(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .where(
          (record) =>
              userUid == null || record['user_uid']?.toString() == userUid,
        )
        .toList();
  }
}
