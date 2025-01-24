import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/event.dart';
import 'dart:math' show min;

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}


class _CalendarWidgetState extends State<CalendarWidget> {
  final DatabaseHelper _db = DatabaseHelper();
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  List<Event> _events = [];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

Future<void> _refreshEvents() async {
    final events = await _db.getEventsForDate(_selectedDate);
    setState(() {
      _events = events;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _refreshEvents();
  }

  List<DateTime> _getDaysInMonth() {
    final List<DateTime> days = [];
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i)));
    }
    
    for (int i = 0; i < _daysInMonth(_currentMonth); i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i + 1));
    }
    
    int remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month + 1, i));
    }
    
    return days;
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  String _getMonthName(int month) {
    return [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ][month - 1];
  }

  void _addEvent() {
    DateTime eventDate = _selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    String title = '';
    String description = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                onChanged: (value) {
                  title = value;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Date: ${eventDate.year}-${eventDate.month}-${eventDate.day}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: eventDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    eventDate = picked;
                    setState(() {});
                  }
                },
              ),
              ListTile(
                title: Text('Start Time: ${startTime?.format(context) ?? 'Not set'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (startTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            startTime = null;
                            endTime = null; // Clear end time if start time is cleared
                          });
                        },
                      ),
                    const Icon(Icons.access_time),
                  ],
                ),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 0, minute: 0),
                    initialEntryMode: TimePickerEntryMode.input, // sets default to keyboard input mode
                  );
                  if (picked != null) {
                    setState(() {
                      startTime = picked;
                    });
                  }
                },
              ),
              if (startTime != null) // Only show end time if start time is set
                ListTile(
                  title: Text('End Time: ${endTime?.format(context) ?? 'Not set'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (endTime != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              endTime = null;
                            });
                          },
                        ),
                      const Icon(Icons.access_time),
                    ],
                  ),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 0, minute: 0),
                      initialEntryMode: TimePickerEntryMode.input, // sets default to keyboard input mode
                    );
                    if (picked != null) {
                      setState(() {
                        endTime = picked;
                      });
                    }
                  },
                ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                onChanged: (value) {
                  description = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final DateTime fullDateTime = DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                );
                
                final event = Event(
                  title: title,
                  description: description,
                  date: fullDateTime,
                  startTime: startTime,
                  endTime: endTime,
                );
                await _db.insertEvent(event);
                
                Navigator.pop(context);
                await _refreshEvents();
                // Refresh events list
                _loadEvents(_selectedDate).then((events) {
                  setState(() {
                    _events = events;
                  });
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Event>> _loadEvents(DateTime date) async {
    return await _db.getEventsForDate(date);
  }

  void _showMonthPicker() {
  int selectedYear = _currentMonth.year;
  int selectedMonthTemp = _currentMonth.month;
  
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Select Month'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setDialogState(() {
                      selectedYear--;
                    });
                  },
                ),
                Text(selectedYear.toString()),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    setDialogState(() {
                      selectedYear++;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  setDialogState(() {
                    selectedMonthTemp = index + 1;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selectedMonthTemp == index + 1 ? Colors.blue.withOpacity(0.1) : null,
                    border: Border.all(
                      color: selectedMonthTemp == index + 1 ? Colors.blue : Colors.grey,
                      width: selectedMonthTemp == index + 1 ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getMonthName(index + 1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selectedMonthTemp == index + 1 ? Colors.blue : Colors.black,
                      fontWeight: selectedMonthTemp == index + 1 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              final newDate = DateTime(selectedYear, selectedMonthTemp);
              Navigator.pop(context);
              setState(() {
                _currentMonth = newDate;
                _selectedDate = DateTime(
                  selectedYear,
                  selectedMonthTemp,
                  min(_selectedDate.day, _daysInMonth(newDate))
                );
              });
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildEventList() {
  return FutureBuilder<List<Event>>(
    future: _loadEvents(_selectedDate),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(
          child: Text('No events for this day', 
            style: TextStyle(fontSize: 16, color: Colors.grey)
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final event = snapshot.data![index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(event.title),
              subtitle: event.description?.isNotEmpty == true 
                ? Text(event.description!) 
                : null,
              trailing: event.startTime != null 
                ? Text('${event.startTime!.format(context)}${event.endTime != null ? ' - ${event.endTime!.format(context)}' : ''}')
                : null,
            ),
          );
        },
      );
    },
  );
}

/* DEBUGGING FUNCTION - UNCOMMENT TO USE
Future<void> _debugDatabase() async {
  try {
 
    // Test retrieve
    final events = await _db.getEvents();
    print('All events in database:');
    for (var event in events) {
      print('ID: ${event.id}, Title: ${event.title}, Description: ${event.description}, Date: ${event.date}');
    }
    
    // Test date specific retrieval
    final todayEvents = await _db.getEventsForDate(DateTime.now());
    print('Events for today:');
    for (var event in todayEvents) {
      print('ID: ${event.id}, Title: ${event.title}');
    }
    
  } catch (e) {
    print('Database error: $e');
  }
}
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Existing calendar header and grid
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                InkWell(
                  onTap: _showMonthPicker,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekDays.map((day) => Text(
                day,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF616161), // grey[700]
                ),
              )).toList(),
            ),
          ),
          // Calendar grid
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: 42,
                itemBuilder: (context, index) {
                  final days = _getDaysInMonth();
                  final day = days[index];
                  final isCurrentMonth = day.month == _currentMonth.month;
                  final isSelected = day.year == _selectedDate.year &&
                      day.month == _selectedDate.month &&
                      day.day == _selectedDate.day;
                  
                  final hasEvents = _events.any((event) =>
                    event.date.year == day.year &&
                    event.date.month == day.month &&
                    event.date.day == day.day);
                  
                  final isToday = DateTime.now().year == day.year &&
                      DateTime.now().month == day.month &&
                      DateTime.now().day == day.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = day;
                      });
                    },
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // New event list
          Expanded(
            flex: 1,
            child: _buildEventList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          /* DEBUGGING BUTTONS - UNCOMMENT TO USE
          FloatingActionButton(
            onPressed: _debugDatabase,
            heroTag: 'debug',
            child: const Icon(Icons.bug_report),
          ),
          const SizedBox(height: 8),
          */
          FloatingActionButton(
            onPressed: _addEvent,
            heroTag: 'add',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}