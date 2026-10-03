import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/farm_session_service.dart';
import '../../../../core/terra_theme.dart';

class AnalyticsFinanceScreen extends StatefulWidget {
  final bool isArabic;
  const AnalyticsFinanceScreen({super.key, this.isArabic = true});

  @override
  State<AnalyticsFinanceScreen> createState() => _AnalyticsFinanceScreenState();
}

class _AnalyticsFinanceScreenState extends State<AnalyticsFinanceScreen> {
  String viewType = 'شهر';
  DateTime selectedDate = DateTime.now();

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      String clean = val
          .replaceAll('٠', '0')
          .replaceAll('١', '1')
          .replaceAll('٢', '2')
          .replaceAll('٣', '3')
          .replaceAll('٤', '4')
          .replaceAll('٥', '5')
          .replaceAll('٦', '6')
          .replaceAll('٧', '7')
          .replaceAll('٨', '8')
          .replaceAll('٩', '9')
          .replaceAll('٫', '.')
          .replaceAll(',', '.')
          .trim();
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  static double _axisInterval(double range) {
    if (range <= 0) return 1;
    final raw = range / 4;
    final magnitude = _pow10(raw);
    final normalized = raw / magnitude;
    final step = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return step * magnitude;
  }

  static double _pow10(double value) {
    var result = 1.0;
    if (value >= 1) {
      while (result * 10 <= value) {
        result *= 10;
      }
    } else {
      while (result > value) {
        result /= 10;
      }
    }
    return result;
  }

  static String _formatAxisValue(double value) {
    final absolute = value.abs();
    if (absolute >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (absolute >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }

  static DateTime? _cropDate(Map<String, dynamic> data) {
    final harvestDate = data['harvestDate'];
    if (harvestDate is Timestamp) return harvestDate.toDate();
    if (harvestDate is DateTime) return harvestDate;
    final parsedHarvestDate = DateTime.tryParse(harvestDate?.toString() ?? '');
    if (parsedHarvestDate != null) return parsedHarvestDate;

    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();
    if (createdAt is DateTime) return createdAt;
    return DateTime.tryParse(createdAt?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: TerraTheme.mist,
        appBar: AppBar(
          title: Text(
            isAr ? "التحليل المالي والإنتاجي" : "Financial & Yield Analytics",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            // 1. بطاقة الرسمة الأولى: التكلفة مقابل المبيعات
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
                        Expanded(
                          child: Text(
                            isAr
                                ? "📊 التكلفة مقابل المبيعات لكل محصول"
                                : "📊 Cost vs Sales per Crop",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _buildLegendBadge(
                              Colors.blueGrey.shade400,
                              isAr ? "التكلفة" : "Cost",
                            ),
                            const SizedBox(width: 8),
                            _buildLegendBadge(
                              const Color(0xFF2E7D32),
                              isAr ? "المبيعات" : "Sales",
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 240,
                      child: _buildProfitProductionBarChart(isAr),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. بطاقة الرسمة الثانية: اتجاه الربحية عبر الزمن
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
                              ? "📈 منحنى صافي الأرباح"
                              : "📈 Net Profit Trend",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: viewType,
                            underline: const SizedBox(),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF2E7D32),
                              size: 18,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'شهر',
                                child: Text(
                                  isAr ? 'عرض شهري' : 'Monthly View',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'سنة',
                                child: Text(
                                  isAr ? 'عرض سنوي' : 'Yearly View',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => viewType = val);
                                if (val == 'سنة') {
                                  _showYearPicker(context, isAr);
                                }
                                if (val == 'شهر') {
                                  _showMonthPicker(context);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: 220, child: _buildCropTypeChart(isAr)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. بطاقة الرسمة الثالثة: توزيع الإنتاج
            Card(
              elevation: 1,
              shadowColor: TerraTheme.ink.withValues(alpha: 0.07),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildCropDistributionChart(isAr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBadge(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // الرسمة الأولى: الأعمدة البيانية
  Widget _buildProfitProductionBarChart(bool isAr) {
    final farmCode = FarmSessionService.currentFarmCode;
    return StreamBuilder<QuerySnapshot>(
      stream: farmCode.isEmpty
          ? FirebaseFirestore.instance.collection('crops').limit(0).snapshots()
          : FirebaseFirestore.instance
                .collection('crops')
                .where('farm_code', isEqualTo: farmCode)
                .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isAr
                  ? 'لا توجد بيانات محاصيل للمقارنة المالية'
                  : 'No crop data available for financial comparison',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          );
        }
        var crops = snapshot.data!.docs;

        double maxVal = 0;
        for (var doc in crops) {
          var data = doc.data() as Map<String, dynamic>;
          double cost = _toDouble(data['cost']);
          double sales = _toDouble(data['sales']);
          if (cost > maxVal) maxVal = cost;
          if (sales > maxVal) maxVal = sales;
        }
        double finalMaxY = (maxVal == 0) ? 100 : (maxVal * 1.25);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: (crops.length * 75.0).clamp(300.0, 2000.0),
            child: BarChart(
              BarChartData(
                maxY: finalMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: TerraTheme.line.withValues(alpha: 0.72),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: finalMaxY / 4,
                      getTitlesWidget: (value, meta) => Text(
                        value >= 1000
                            ? '${(value / 1000).toStringAsFixed(0)}k'
                            : value.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 9,
                          color: TerraTheme.blue.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < crops.length) {
                          var data =
                              crops[index].data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SizedBox(
                              width: 54,
                              child: Text(
                                data['name']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: TerraTheme.ink.withValues(alpha: 0.78),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                alignment: BarChartAlignment.spaceAround,
                barGroups: crops.asMap().entries.map((entry) {
                  int index = entry.key;
                  var data = entry.value.data() as Map<String, dynamic>;
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: _toDouble(data['cost']),
                        color: const Color(0xFFA4B0B5),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: _toDouble(data['sales']),
                        color: TerraTheme.forest,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  // الرسمة الثانية: الخطي
  Widget _buildCropTypeChart(bool isAr) {
    final farmCode = FarmSessionService.currentFarmCode;
    return StreamBuilder<QuerySnapshot>(
      stream: farmCode.isEmpty
          ? FirebaseFirestore.instance.collection('crops').limit(0).snapshots()
          : FirebaseFirestore.instance
                .collection('crops')
                .where('farm_code', isEqualTo: farmCode)
                .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }
        var crops = snapshot.hasData ? snapshot.data!.docs : [];

        final isYearView = viewType == 'سنة';
        final totalPoints = isYearView
            ? 12
            : DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

        List<FlSpot> spots = List.generate(totalPoints, (index) {
          final unit = index + 1;
          var matchedCrops = crops.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = _cropDate(data);
            if (date == null) return false;
            if (isYearView) {
              return date.year == selectedDate.year && date.month == unit;
            }
            return date.year == selectedDate.year &&
                date.month == selectedDate.month &&
                date.day == unit;
          });

          double totalProfit = 0.0;
          for (var doc in matchedCrops) {
            var d = doc.data() as Map<String, dynamic>;
            totalProfit += (_toDouble(d['sales']) - _toDouble(d['cost']));
          }
          return FlSpot(index.toDouble(), totalProfit);
        });

        final values = spots.map((spot) => spot.y).toList();
        final dataMin = values.isEmpty
            ? 0.0
            : values.reduce((a, b) => a < b ? a : b);
        final dataMax = values.isEmpty
            ? 0.0
            : values.reduce((a, b) => a > b ? a : b);
        final padding = ((dataMax - dataMin).abs() * 0.15)
            .clamp(10.0, double.infinity)
            .toDouble();
        final finalMinY = dataMin - padding;
        final finalMaxY = dataMax + padding;
        final interval = _axisInterval(finalMaxY - finalMinY);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: (totalPoints * 40.0).clamp(300.0, 2000.0),
            child: LineChart(
              LineChartData(
                minY: finalMinY,
                maxY: finalMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: TerraTheme.line.withValues(alpha: 0.72),
                    strokeWidth: 1,
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 0,
                      color: TerraTheme.ink.withValues(alpha: 0.55),
                      strokeWidth: 1.2,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(
                          fontSize: 9,
                          color: TerraTheme.ink.withValues(alpha: 0.7),
                        ),
                        labelResolver: (_) => isAr ? 'تعادل' : 'Break-even',
                      ),
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: interval,
                      getTitlesWidget: (value, meta) => Text(
                        _formatAxisValue(value),
                        style: TextStyle(
                          fontSize: 9,
                          color: TerraTheme.blue.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        int val = value.toInt() + 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            isYearView
                                ? (isAr ? 'ش$val' : 'M$val')
                                : '$val/${selectedDate.month}',
                            style: TextStyle(
                              fontSize: 10,
                              color: TerraTheme.blue.withValues(alpha: 0.70),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                clipData: const FlClipData.all(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: TerraTheme.forest,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: TerraTheme.sage.withValues(alpha: 0.30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showYearPicker(BuildContext context, bool isAr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAr ? "اختر السنة" : "Select Year",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SizedBox(
          height: 200,
          width: 300,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            selectedDate: selectedDate,
            onChanged: (DateTime dateTime) {
              setState(() {
                selectedDate = dateTime;
                viewType = 'سنة';
              });
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate != null) {
        setState(() {
          selectedDate = pickedDate;
          viewType = 'شهر';
        });
      }
    });
  }

  // الرسمة الثالثة: الدائرية
  Widget _buildCropDistributionChart(bool isAr) {
    final farmCode = FarmSessionService.currentFarmCode;
    return StreamBuilder<QuerySnapshot>(
      stream: farmCode.isEmpty
          ? FirebaseFirestore.instance.collection('crops').limit(0).snapshots()
          : FirebaseFirestore.instance
                .collection('crops')
                .where('farm_code', isEqualTo: farmCode)
                .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }

        var docs = snapshot.hasData ? snapshot.data!.docs : [];
        Map<String, double> dataMap = {};
        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          String name =
              data['name']?.toString() ?? (isAr ? 'غير معروف' : 'Unknown');
          double quantity = _toDouble(data['quantity']);
          dataMap[name] = (dataMap[name] ?? 0) + quantity;
        }

        double total = 0.0;
        for (var v in dataMap.values) {
          total += v;
        }

        if (dataMap.isEmpty || total <= 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                isAr
                    ? 'لا توجد بيانات محاصيل كافية لحساب التوزيع'
                    : 'Insufficient crop data to calculate distribution',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          );
        }

        List<Color> colors = [
          TerraTheme.forest,
          TerraTheme.blue,
          TerraTheme.amber,
          TerraTheme.olive,
          TerraTheme.coral,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? "🥧 توزيع الإنتاج حسب المحصول"
                  : "🥧 Yield Distribution by Crop",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 224,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 46,
                  centerSpaceColor: TerraTheme.paper,
                  sections: dataMap.entries.map((entry) {
                    int index = dataMap.keys.toList().indexOf(entry.key);
                    double percentage = (entry.value / total) * 100;
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${entry.key}\n${percentage.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      color: colors[index % colors.length],
                      radius: 60,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
