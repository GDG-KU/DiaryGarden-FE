
/// Information about a specific week
class WeekInfo {
  const WeekInfo({
    required this.year,
    required this.month,
    required this.weekOfMonth,
    required this.startDate,
    required this.endDate,
  });

  final int year;
  final int month;
  final int weekOfMonth;
  final DateTime startDate; // Sunday
  final DateTime endDate; // Saturday

  /// Returns a unique identifier for this week
  String get weekId => '${year}_${month}_$weekOfMonth';

  /// Returns display label like "12월 3주차"
  String get displayLabel => '$month월 ${weekOfMonth}주차';

  /// Check if a date falls within this week
  bool containsDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return !normalizedDate.isBefore(startDate) &&
        !normalizedDate.isAfter(endDate);
  }

  @override
  String toString() => 'WeekInfo($displayLabel: ${_formatDate(startDate)} - ${_formatDate(endDate)})';

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Utility class for week calculations
class WeekCalculator {
  const WeekCalculator._();

  /// Get week information for a date
  /// 
  /// Uses majority rule: week belongs to whichever month/year contains
  /// 4 or more days of that week.
  /// Week starts on SUNDAY and ends on SATURDAY.
  static WeekInfo getWeekInfo(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    
    // Find Sunday of this week (weekday: 1=Mon, 7=Sun)
    // For Sunday, daysToSunday = 0; for Monday, daysToSunday = 1, etc.
    final daysToSunday = normalized.weekday % 7;
    final sunday = normalized.subtract(Duration(days: daysToSunday));
    final saturday = sunday.add(const Duration(days: 6));

    // Count days in each month
    final daysPerMonth = <int, int>{};
    for (var i = 0; i < 7; i++) {
      final day = sunday.add(Duration(days: i));
      daysPerMonth[day.month] = (daysPerMonth[day.month] ?? 0) + 1;
    }

    // Find month with most days (majority rule)
    int owningMonth = sunday.month;
    int maxDays = 0;
    for (final entry in daysPerMonth.entries) {
      if (entry.value > maxDays) {
        maxDays = entry.value;
        owningMonth = entry.key;
      }
    }

    // Determine year based on owning month
    int owningYear = sunday.year;
    if (owningMonth == 12 && sunday.month == 1) {
      owningYear = sunday.year - 1;
    } else if (owningMonth == 1 && sunday.month == 12) {
      owningYear = sunday.year + 1;
    } else {
      // For same-month or normal cases, check which year has more days
      final daysInFirstYear = _countDaysInYear(sunday, saturday, sunday.year);
      final daysInSecondYear = _countDaysInYear(sunday, saturday, sunday.year + 1);
      owningYear = daysInFirstYear >= daysInSecondYear ? sunday.year : sunday.year + 1;
    }

    // Calculate week number within the owning month
    final weekOfMonth = _calculateWeekOfMonth(owningYear, owningMonth, sunday);

    return WeekInfo(
      year: owningYear,
      month: owningMonth,
      weekOfMonth: weekOfMonth,
      startDate: sunday,
      endDate: saturday,
    );
  }

  /// Count how many days of the week fall in the specified year
  static int _countDaysInYear(DateTime monday, DateTime sunday, int year) {
    int count = 0;
    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      if (day.year == year) count++;
    }
    return count;
  }

  /// Calculate which week of the month this is
  /// 
  /// Counts complete Sunday-Saturday weeks starting from the first Sunday
  /// in or before the 1st of the month.
  static int _calculateWeekOfMonth(int year, int month, DateTime sunday) {
    // Find the first day of the owning month
    final firstDayOfMonth = DateTime(year, month, 1);
    
    // Find the Sunday on or before the 1st of the month
    // weekday: 1=Mon, 7=Sun
    final daysToSunday = firstDayOfMonth.weekday % 7;
    final firstSunday = firstDayOfMonth.subtract(Duration(days: daysToSunday));

    // Calculate week number by counting Sundays
    final daysDiff = sunday.difference(firstSunday).inDays;
    final weekNumber = (daysDiff  ~/ 7) + 1;

    return weekNumber;
  }

  /// Get the week before the given week
  static WeekInfo getPreviousWeek(WeekInfo current) {
    final previousSunday = current.startDate.subtract(const Duration(days: 7));
    return getWeekInfo(previousSunday);
  }

  /// Get the week after the given week
  static WeekInfo getNextWeek(WeekInfo current) {
    final nextSunday = current.startDate.add(const Duration(days: 7));
    return getWeekInfo(nextSunday);
  }

  /// Get the current week (for today's date)
  static WeekInfo getCurrentWeek() {
    return getWeekInfo(DateTime.now());
  }

  /// Generate a list of 7 dates for the week (Sunday to Saturday)
  static List<DateTime> getWeekDates(WeekInfo week) {
    return List.generate(
      7,
      (index) => week.startDate.add(Duration(days: index)),
    );
  }
}
