class CalendarUtils {
  static List<DateTime> getDaysInMonth(DateTime currentMonth) {
    final List<DateTime> days = [];
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    // Convert to 0-6 range where 0 is Sunday
    final firstWeekday = firstDayOfMonth.weekday % 7;
    
    // Add previous month's days
    for (int i = firstWeekday; i > 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i)));
    }
    
    // Add current month's days
    for (int i = 0; i < daysInMonth(currentMonth); i++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, i + 1));
    }
    
    // Add next month's days
    int remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(currentMonth.year, currentMonth.month + 1, i));
    }
    
    return days;
  }

  static int daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  static String getMonthName(int month) {
    return [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ][month - 1];
  }
}
