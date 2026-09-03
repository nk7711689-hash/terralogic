import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:shared_preferences/shared_preferences.dart';

class MarketService {
  // هذا رابط تجريبي، استبدليه برابط صفحة الأسعار الحقيقي عندما تختارينه
  final String url = 'https://petra.gov.jo/RSS/ArabicNews.xml';

  
Future<List<Map<String, String>>> fetchMarketNews() async {
  try {
    // رابط بحث جوجل الإخباري عن الزراعة في الأردن
    final response = await http.get(Uri.parse('https://news.google.com/rss/search?q=الزراعة+في+الأردن&hl=ar&gl=JO&ceid=JO:ar'));
    
    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      // في RSS الخاص بجوجل، العناوين داخل وسم <title>
      var items = document.querySelectorAll('item');
      List<Map<String, String>> newsList = [];

      for (var item in items.take(7)) { // جلب أول 7 أخبار فقط
        newsList.add({
          'title': item.querySelector('title')?.text ?? 'خبر زراعي',
        });
      }
      return newsList;
    }
  } catch (e) {
    print("Error: $e");
  }
  return [];
}
}