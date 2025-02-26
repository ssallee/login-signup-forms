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
  final List<String> _weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

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
    // Convert weekday to 0-6 range where 0 is Sunday
    final firstWeekday = firstDayOfMonth.weekday % 7;
    
    // Add previous month's days
    for (int i = firstWeekday; i > 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i)));
    }
    
    // Add current month's days
    for (int i = 0; i < _daysInMonth(_currentMonth); i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i + 1));
    }
    
    // Fill remaining days until we have 42 days (6 weeks)
    while (days.length < 42) {
      days.add(days.last.add(const Duration(days: 1)));
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
    String? titleError; // Add this for error handling
    bool isPriority = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dialog from closing when tapping outside
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => PopScope(
          canPop: false, // Prevents dialog from closing when back button is pressed
          child: Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text('Add Event'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Title',
                              border: const OutlineInputBorder(),
                              errorText: titleError, // Add error text
                            ),
                            onChanged: (value) {
                              title = value;
                              if (titleError != null) {
                                setState(() => titleError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: ListTile(
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
                                  setState(() => eventDate = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              title: Text('Start Time: ${startTime?.format(context) ?? 'Not set'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (startTime != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(() {
                                        startTime = null;
                                        endTime = null;
                                      }),
                                    ),
                                  const Icon(Icons.access_time),
                                ],
                              ),
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: startTime ?? TimeOfDay.now(),
                                  initialEntryMode: TimePickerEntryMode.input,
                                );
                                if (picked != null) {
                                  setState(() => startTime = picked);
                                }
                              },
                            ),
                          ),
                          if (startTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Card(
                                child: ListTile(
                                  title: Text('End Time: ${endTime?.format(context) ?? 'Not set'}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (endTime != null)
                                        IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () => setState(() => endTime = null),
                                        ),
                                      const Icon(Icons.access_time),
                                    ],
                                  ),
                                  onTap: () async {
                                    final TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: endTime ?? startTime ?? TimeOfDay.now(),
                                      initialEntryMode: TimePickerEntryMode.input,
                                    );
                                    if (picked != null) {
                                      setState(() => endTime = picked);
                                    }
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            onChanged: (value) => description = value,
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('High Priority'),
                            value: isPriority,
                            onChanged: (bool value) {
                              setState(() => isPriority = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              if (title.trim().isEmpty) {
                                setState(() => titleError = 'Title is required');
                                return;
                              }
                              
                              final event = Event(
                                title: title.trim(),
                                description: description,
                                date: eventDate,
                                startTime: startTime,
                                endTime: endTime,
                                isPriority: isPriority,
                              );
                              await _db.insertEvent(event);
                              if (mounted) {
                                Navigator.pop(context);
                              }
                              await _refreshEvents();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('Save Event'),
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
        ),
      ),
    );
  }

  void _editEvent(Event event) {
    DateTime eventDate = event.date;
    TimeOfDay? startTime = event.startTime;
    TimeOfDay? endTime = event.endTime;
    String title = event.title;
    String description = event.description;
    bool isPriority = event.isPriority; // Add this line
    String? titleError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => PopScope(
          canPop: false,
          child: Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text('Edit Event'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Title',
                              border: const OutlineInputBorder(),
                              errorText: titleError,
                            ),
                            controller: TextEditingController(text: title),
                            onChanged: (value) {
                              title = value;
                              if (titleError != null) {
                                setState(() => titleError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: ListTile(
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
                                  setState(() => eventDate = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              title: Text('Start Time: ${startTime?.format(context) ?? 'Not set'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (startTime != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(() {
                                        startTime = null;
                                        endTime = null;
                                      }),
                                    ),
                                  const Icon(Icons.access_time),
                                ],
                              ),
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: startTime ?? TimeOfDay.now(),
                                  initialEntryMode: TimePickerEntryMode.input,
                                );
                                if (picked != null) {
                                  setState(() => startTime = picked);
                                }
                              },
                            ),
                          ),
                          if (startTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Card(
                                child: ListTile(
                                  title: Text('End Time: ${endTime?.format(context) ?? 'Not set'}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (endTime != null)
                                        IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () => setState(() => endTime = null),
                                        ),
                                      const Icon(Icons.access_time),
                                    ],
                                  ),
                                  onTap: () async {
                                    final TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: endTime ?? startTime ?? TimeOfDay.now(),
                                      initialEntryMode: TimePickerEntryMode.input,
                                    );
                                    if (picked != null) {
                                      setState(() => endTime = picked);
                                    }
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            controller: TextEditingController(text: description),
                            maxLines: 3,
                            onChanged: (value) => description = value,
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile( // Add this widget
                            title: const Text('High Priority'),
                            value: isPriority,
                            onChanged: (bool value) {
                              setState(() => isPriority = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              if (title.trim().isEmpty) {
                                setState(() => titleError = 'Title is required');
                                return;
                              }
                              
                              final updatedEvent = Event(
                                id: event.id,
                                title: title.trim(),
                                description: description.trim(),
                                date: eventDate,
                                startTime: startTime,
                                endTime: endTime,
                                isPriority: isPriority, // Add this field
                              );
                              await _db.updateEvent(updatedEvent);
                              Navigator.pop(context);
                              await _refreshEvents();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('Update Event'),
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
        ),
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _db.deleteEvent(event.id!);
              Navigator.pop(context);
              await _refreshEvents();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
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
          contentPadding: const EdgeInsets.all(8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Date', style: TextStyle(fontSize: 16)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () {
                      setDialogState(() => selectedYear--);
                    },
                  ),
                  Text(selectedYear.toString()),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    onPressed: () {
                      setDialogState(() => selectedYear++);
                    },
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.3,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
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
              style: TextStyle(fontSize: 14, color: Colors.grey)
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final event = snapshot.data![index];
            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: InkWell( // Wrap ListTile with InkWell
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit Event'),
                          onTap: () {
                            Navigator.pop(context);
                            _editEvent(event);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Delete Event', 
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteEvent(event);
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: ListTile(
                  dense: true,
                  leading: event.isPriority
                    ? const Icon(Icons.priority_high, color: Colors.red, size: 20)
                    : null,
                  title: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: event.isPriority ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: event.description?.isNotEmpty == true 
                    ? Text(
                        event.description!,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                  trailing: event.startTime != null 
                    ? Text(
                        '${event.startTime!.format(context)}${event.endTime != null ? '\n${event.endTime!.format(context)}' : ''}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.right,
                      )
                    : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final calendarHeight = screenSize.height * 0.6; // Increased to 60% of screen height
    
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Calendar header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              // Weekday headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekDays.map((day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF616161),
                      ),
                    ),
                  )).toList(),
                ),
              ),
              // Calendar grid
              SizedBox(
                height: calendarHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final days = _getDaysInMonth();
                    final day = days[index];
                    final isCurrentMonth = day.month == _currentMonth.month;
                    final isSelected = day.year == _selectedDate.year &&
                        day.month == _selectedDate.month &&
                        day.day == _selectedDate.day;
                    
                    final isToday = DateTime.now().year == day.year &&
                        DateTime.now().month == day.month &&
                        DateTime.now().day == day.day;

                    return FutureBuilder<List<Event>>(
                      future: _db.getEventsForDate(day),
                      builder: (context, snapshot) {
                        bool hasHighPriority = false;
                        bool hasEvents = false;
                        
                        if (snapshot.hasData) {
                          hasHighPriority = snapshot.data!.any((event) => event.isPriority);
                          hasEvents = snapshot.data!.isNotEmpty;
                        }

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = day;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary 
                                  : hasHighPriority 
                                      ? Theme.of(context).colorScheme.error.withOpacity(0.2)
                                      : hasEvents 
                                          ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
                                          : null,
                              border: isToday 
                                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1)
                                  : hasHighPriority
                                      ? Border.all(color: Theme.of(context).colorScheme.error, width: 1)
                                      : hasEvents
                                          ? Border.all(color: Theme.of(context).colorScheme.secondary, width: 1)
                                          : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color: !isCurrentMonth 
                                          ? Theme.of(context).colorScheme.onBackground.withOpacity(0.5)
                                          : isSelected
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : hasHighPriority
                                                  ? Theme.of(context).colorScheme.error
                                                  : Theme.of(context).colorScheme.onBackground,
                                      fontWeight: hasHighPriority || hasEvents || isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (hasHighPriority || hasEvents)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: hasHighPriority
                                        ? Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              
                                              shape: BoxShape.rectangle, 
                                              
                                            ),
                                          )
                                        : Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Sliding Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Drag handle
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outline,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Events header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Events for ${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Events list
                    FutureBuilder<List<Event>>(
                      future: _loadEvents(_selectedDate),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SliverFillRemaining(
                            child: Center(
                              child: Text('No events for this day',
                                style: TextStyle(fontSize: 14, color: Colors.grey)
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: InkWell(
                                onLongPress: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.edit),
                                          title: const Text('Edit Event'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _editEvent(snapshot.data![index]);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.delete, color: Colors.red),
                                          title: const Text('Delete Event', 
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _deleteEvent(snapshot.data![index]);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: snapshot.data![index].isPriority
                                    ? const Icon(Icons.priority_high, color: Colors.red)
                                    : null,
                                  title: Text(
                                    snapshot.data![index].title,
                                    style: TextStyle(
                                      fontWeight: snapshot.data![index].isPriority ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(snapshot.data![index].description),
                                  trailing: snapshot.data![index].startTime != null
                                    ? Text(snapshot.data![index].startTime!.format(context))
                                    : null,
                                ),
                              ),
                            ),
                            childCount: snapshot.data!.length,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      
      ),
    );
  }
}