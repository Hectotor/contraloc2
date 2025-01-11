class CalculDate {
  static DateTime? tryParseDate(String date) {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return null;
    }
  }

  static int? calculateDurationInDays(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    return end.difference(start).inDays;
  }

  static double calculateTotalCost(int days, double dailyRate) {
    if (days <= 0 || dailyRate <= 0) return 0.0;
    return days * dailyRate;
  }
}
