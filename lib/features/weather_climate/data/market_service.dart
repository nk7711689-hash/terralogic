import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class MarketService {
  // هذا رابط تجريبي، استبدليه برابط صفحة الأسعار الحقيقي عندما تختارينه
  final String url = 'https://petra.gov.jo/RSS/ArabicNews.xml';

  Future<List<Map<String, String>>> fetchMarketNews() async {
    try {
      // رابط بحث جوجل الإخباري عن الزراعة في الأردن
      final response = await http.get(
        Uri.parse(
          'https://news.google.com/rss/search?q=الزراعة+في+الأردن&hl=ar&gl=JO&ceid=JO:ar',
        ),
      );

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        // في RSS الخاص بجوجل، العناوين داخل وسم <title>
        var items = document.querySelectorAll('item');
        List<Map<String, String>> newsList = [];

        for (var item in items.take(7)) {
          // جلب أول 7 أخبار فقط
          final rawTitle = item.querySelector('title')?.text.trim() ?? 'خبر زراعي';
          final separator = rawTitle.lastIndexOf(' - ');
          final title = separator > 0
              ? rawTitle.substring(0, separator).trim()
              : rawTitle;
          final source = separator > 0
              ? rawTitle.substring(separator + 3).trim()
              : 'Google News';
          newsList.add({
            'title': title,
            'source': source,
            'published_at': item.querySelector('pubDate')?.text.trim() ?? '',
            'link': item.querySelector('link')?.text.trim() ?? '',
          });
        }
        return newsList;
      }
    } catch (e) {
      developer.log(
        'Failed to fetch market news',
        name: 'MarketService',
        error: e,
      );
    }
    return [];
  }
}
