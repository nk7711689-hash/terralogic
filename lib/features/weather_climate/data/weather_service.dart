//import 'import_helper.dart'; // سيتيح لنا استخدام الفايربيس أو الفلاتر لاحقاً إن احتجنا
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // 💡 استبدلي النص أدناه بالـ API Key الذي نسختيه من موقع الطقس
  final String apiKey = "0c469103e13474949579297ed07917ec";
  
  // 1. جلب الطقس الحالي الحقيقي باستخدام الإحداثيات
  Future<Map<String, dynamic>> fetchCurrentWeather(double lat, double lon) async {
    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ar';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load current weather');
    }
  }

  // 2. جلب توقعات 5 أيام للمنحنى البياني الحقيقي
  Future<Map<String, dynamic>> fetchWeatherForecast(double lat, double lon) async {
    final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ar';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load forecast data');
    }
  }
}