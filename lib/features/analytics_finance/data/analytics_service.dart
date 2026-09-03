class AnalyticsService {
  // دالة تحسب الربحية بناءً على بيانات الإنتاج والتكاليف
  double calculateProfitability(double revenue, double costs) {
    return revenue - costs;
  }

  // دالة ذكية تقترح قراراً زراعياً
  String suggestAgriculturalAction(double temperature) {
    if (temperature > 35) {
      return "تحذير: إجهاد حراري عالٍ! يُنصح بزيادة الري في المساء.";
    } else if (temperature < 5) {
      return "تحذير: خطر الصقيع! يُنصح بتغطية المحاصيل الحساسة.";
    } else {
      return "الظروف المناخية مثالية للنمو.";
    }
  }
}
