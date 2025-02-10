import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/database_helper.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<DateTime> days;
  final Function(DateTime) onDaySelected;
  final DatabaseHelper db;

  const CalendarGrid({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.days,
    required this.onDaySelected,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final day = days[index];
        final isCurrentMonth = day.month == currentMonth.month;
        final isSelected = day.year == selectedDate.year &&
            day.month == selectedDate.month &&
            day.day == selectedDate.day;
        
        final isToday = DateTime.now().year == day.year &&
            DateTime.now().month == day.month &&
            DateTime.now().day == day.day;

        return DayCell(
          day: day,
          isCurrentMonth: isCurrentMonth,
          isSelected: isSelected,
          isToday: isToday,
          onTap: () => onDaySelected(day),
          db: db,
        );
      },
    );
  }
}

class DayCell extends StatelessWidget {
  final DateTime day;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;
  final DatabaseHelper db;

  const DayCell({
    super.key,
    required this.day,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : null,
          border: isToday ? Border.all(color: Colors.black, width: 1) : null,
          shape: isToday ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isToday ? null : BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isCurrentMonth
                      ? (isSelected ? Colors.white : Colors.black)
                      : Colors.grey,
                ),
              ),
            ),
            EventIndicator(
              date: day,
              isSelected: isSelected,
              db: db,
            ),
          ],
        ),
      ),
    );
  }
}

class EventIndicator extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final DatabaseHelper db;

  const EventIndicator({
    super.key,
    required this.date,
    required this.isSelected,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Event>>(
      future: db.getEventsForDate(date),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Container();
        
        final hasPriorityEvent = snapshot.data!.any((event) => event.isPriority);
        
        return Positioned(
          bottom: 4,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : (hasPriorityEvent ? Colors.red : Colors.blue),
                  shape: hasPriorityEvent ? BoxShape.rectangle : BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
