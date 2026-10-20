import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:terralogic/core/farm_session_service.dart';
import 'package:terralogic/core/notification_service.dart';
import 'package:terralogic/core/terra_theme.dart';
import 'package:terralogic/features/weather_climate/data/weather_service.dart';
import 'package:terralogic/features/weather_climate/data/market_service.dart';

class WeatherClimateHomeScreen extends StatefulWidget {
  final bool isArabic;
  const WeatherClimateHomeScreen({super.key, this.isArabic = true});

  @override
  State<WeatherClimateHomeScreen> createState() =>
      _WeatherClimateHomeScreenState();
}

class _WeatherClimateHomeScreenState extends State<WeatherClimateHomeScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? weatherData;
  bool isLoading = true;

  String selectedCityKey = "Amman";
  double currentLat = 31.95;
  double currentLon = 35.91;
  List<FlSpot> tempSpots = [];
  List<FlSpot> humiditySpots = [];
  List<FlSpot> windSpots = [];
  List<DateTime> forecastDates = [];

  List<Map<String, String>> _marketNews = [];
  bool _isMarketLoading = true;

  final Map<String, ({String nameAr, String nameEn, double lat, double lon})>
  _governorates = {
    'Amman': (nameAr: 'عمان', nameEn: 'Amman', lat: 31.95, lon: 35.91),
    'Irbid': (nameAr: 'إربد', nameEn: 'Irbid', lat: 32.55, lon: 35.85),
    'Ajloun': (nameAr: 'عجلون', nameEn: 'Ajloun', lat: 32.33, lon: 35.75),
    'Mafraq': (nameAr: 'المفرق', nameEn: 'Mafraq', lat: 32.34, lon: 36.21),
    'Zarqa': (nameAr: 'الزرقاء', nameEn: 'Zarqa', lat: 32.07, lon: 36.08),
    'Balqa': (nameAr: 'البلقاء', nameEn: 'Balqa', lat: 32.03, lon: 35.73),
    'Madaba': (nameAr: 'مأدبا', nameEn: 'Madaba', lat: 31.72, lon: 35.79),
    'Karak': (nameAr: 'الكرك', nameEn: 'Karak', lat: 31.18, lon: 35.70),
    'Tafilah': (nameAr: 'الطفيلة', nameEn: 'Tafilah', lat: 30.84, lon: 35.61),
    'Maan': (nameAr: 'معان', nameEn: 'Maan', lat: 30.19, lon: 36.22),
    'Aqaba': (nameAr: 'العقبة', nameEn: 'Aqaba', lat: 29.53, lon: 35.01),
    'Jerash': (nameAr: 'جرش', nameEn: 'Jerash', lat: 32.27, lon: 35.89),
  };

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
    _loadMarketNews();
  }

  Future<void> _loadMarketNews() async {
    final service = MarketService();
    final news = await service.fetchMarketNews();
    if (mounted) {
      setState(() {
        _marketNews = news;
        _isMarketLoading = false;
      });
    }
  }

  Future<void> _loadWeatherData() async {
    setState(() => isLoading = true);

    try {
      final currentData = await _weatherService.fetchCurrentWeather(
        currentLat,
        currentLon,
      );
      final fData = await _weatherService.fetchWeatherForecast(
        currentLat,
        currentLon,
      );

      List<dynamic> list = fData['list'];
      List<FlSpot> tSpots = [];
      List<FlSpot> hSpots = [];
      List<FlSpot> wSpots = [];
      List<DateTime> dates = [];

      for (int i = 0; i < 7; i++) {
        if (i * 8 < list.length) {
          var item = list[i * 8];
          final date =
              DateTime.tryParse(item['dt_txt']?.toString() ?? '') ??
              DateTime.now().add(Duration(days: i));
          dates.add(date);
          tSpots.add(
            FlSpot(i.toDouble(), double.parse(item['main']['temp'].toString())),
          );
          hSpots.add(
            FlSpot(
              i.toDouble(),
              double.parse(item['main']['humidity'].toString()),
            ),
          );
          wSpots.add(
            FlSpot(
              i.toDouble(),
              double.parse(item['wind']['speed'].toString()),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          weatherData = currentData;
          tempSpots = tSpots;
          humiditySpots = hSpots;
          windSpots = wSpots;
          forecastDates = dates;
          isLoading = false;
        });

        // فحص الصقيع وإرسال إشعار إذا كانت الحرارة متدنية
        final double? curTemp = double.tryParse(
          currentData['main']['temp'].toString(),
        );
        if (curTemp != null) {
          final farmCode = FarmSessionService.currentFarmCode;
          final cName = widget.isArabic
              ? _governorates[selectedCityKey]!.nameAr
              : _governorates[selectedCityKey]!.nameEn;
          if (farmCode.isNotEmpty) {
            FarmNotificationService.checkWeatherFrostRisk(
              curTemp,
              cName,
              farmCode,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    String cityName = isAr
        ? _governorates[selectedCityKey]!.nameAr
        : _governorates[selectedCityKey]!.nameEn;

    String temp = weatherData != null
        ? "${weatherData!['main']['temp'].toStringAsFixed(1)}°"
        : "24°";
    String humidity = weatherData != null
        ? "${weatherData!['main']['humidity']}%"
        : "45%";
    String windSpeed = weatherData != null
        ? "${weatherData!['wind']['speed']} ${isAr ? 'م/ث' : 'm/s'}"
        : "12 ${isAr ? 'كم/س' : 'km/h'}";
    final chartSpots = tempSpots;
    final chartValues = chartSpots.map((spot) => spot.y).toList();
    final chartMin = chartValues.isEmpty
        ? 0.0
        : chartValues.reduce((a, b) => a < b ? a : b);
    final chartMax = chartValues.isEmpty
        ? 30.0
        : chartValues.reduce((a, b) => a > b ? a : b);
    final chartPadding = ((chartMax - chartMin) * 0.15)
        .clamp(1.0, 10.0)
        .toDouble();
    final chartMinY = chartMin - chartPadding;
    final chartMaxY = chartMax + chartPadding;
    final chartMaxX = forecastDates.length > 1
        ? (forecastDates.length - 1).toDouble()
        : 6.0;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: TerraTheme.mist,
        appBar: AppBar(
          title: Text(
            isAr ? "الطقس وأسعار السوق" : "Weather & Market Prices",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButton<String>(
                value: selectedCityKey,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF2E7D32),
                  size: 16,
                ),
                items: _governorates.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      isAr ? entry.value.nameAr : entry.value.nameEn,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newKey) {
                  if (newKey != null) {
                    setState(() {
                      selectedCityKey = newKey;
                      currentLat = _governorates[newKey]!.lat;
                      currentLon = _governorates[newKey]!.lon;
                    });
                    _loadWeatherData();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                children: [
                  // 1. كرت الطقس الرئيسي الناعم
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [TerraTheme.forest, TerraTheme.ink],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: TerraTheme.forest.withValues(alpha: 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr
                                      ? "طقس محافظة $cityName"
                                      : "$cityName Province Weather",
                                  style: TextStyle(
                                    color: Colors.green.shade100,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  temp,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.wb_sunny_rounded,
                              color: Colors.amber,
                              size: 56,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWeatherMetric(
                                Icons.water_drop_outlined,
                                isAr ? "الرطوبة" : "Humidity",
                                humidity,
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.white24,
                              ),
                              _buildWeatherMetric(
                                Icons.air_rounded,
                                isAr ? "الرياح" : "Wind",
                                windSpeed,
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.white24,
                              ),
                              _buildWeatherMetric(
                                Icons.thermostat_outlined,
                                isAr ? "الحالة" : "Condition",
                                isAr ? "معتدل" : "Fair",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. كرت المنحنى البياني لتوقعات الأسبوع
                  Card(
                    elevation: 1,
                    shadowColor: TerraTheme.ink.withValues(alpha: 0.07),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAr
                                    ? '📊 درجات الحرارة خلال الأسبوع'
                                    : '📊 Weekly temperatures',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              Text(
                                isAr ? '°م' : '°C',
                                style: const TextStyle(
                                  color: TerraTheme.olive,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 184,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey.shade100,
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: AxisTitles(
                                    axisNameWidget: Text(
                                      isAr ? '°م' : '°C',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: TerraTheme.blue.withValues(
                                          alpha: 0.72,
                                        ),
                                      ),
                                    ),
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 38,
                                      interval: ((chartMaxY - chartMinY) / 4)
                                          .clamp(1.0, double.infinity)
                                          .toDouble(),
                                      getTitlesWidget: (value, meta) => Text(
                                        value.toStringAsFixed(0),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: TerraTheme.blue.withValues(
                                            alpha: 0.72,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      reservedSize: 34,
                                      getTitlesWidget: (value, meta) {
                                        int idx = value.toInt();
                                        if (idx >= 0 &&
                                            idx < forecastDates.length) {
                                          final date = forecastDates[idx];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6.0,
                                            ),
                                            child: Text(
                                              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: TerraTheme.blue
                                                    .withValues(alpha: 0.72),
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                clipData: const FlClipData.all(),
                                minX: 0,
                                maxX: chartMaxX,
                                minY: chartMinY,
                                maxY: chartMaxY,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: chartSpots,
                                    isCurved: true,
                                    color: TerraTheme.olive,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: TerraTheme.olive.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. قسم أسعار السوق المركزي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr
                            ? "🏪 أخبار وأسعار السوق المركزي"
                            : "🏪 Central Market News & Prices",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      if (_isMarketLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_marketNews.isEmpty && !_isMarketLoading)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          isAr
                              ? "لا توجد أخبار سوق حالية، يتم التحديث دورياً"
                              : "No live market news at the moment, updating periodically",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._marketNews.map((news) {
                      final title = news['title']?.trim() ?? '';
                      final source = news['source']?.trim() ?? '';
                      return Card(
                        elevation: 0,
                        shadowColor: TerraTheme.ink.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onLongPress: () => _copyNews(
                            title: title,
                            source: source,
                            isAr: isAr,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatNewsDate(news['published_at'], isAr),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.newspaper_rounded,
                                        color: Color(0xFF2E7D32),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.45,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _buildWeatherMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.green.shade100, fontSize: 10),
        ),
      ],
    );
  }

  String _formatNewsDate(String? rawDate, bool isAr) {
    final date = rawDate == null ? null : DateTime.tryParse(rawDate);
    if (date == null) return isAr ? 'تاريخ غير متوفر' : 'Date unavailable';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} • '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _copyNews({
    required String title,
    required String source,
    required bool isAr,
  }) async {
    final text = '$title\n${isAr ? 'المصدر' : 'Source'}: $source';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تم نسخ الخبر والمصدر' : 'News and source copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
