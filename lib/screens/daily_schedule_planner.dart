import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/event.dart';
import '../services/database_helper.dart';

class DailySchedulePlanner extends StatefulWidget {
  const DailySchedulePlanner({super.key});

  @override
  State<DailySchedulePlanner> createState() => _DailySchedulePlannerState();
}

class _DailySchedulePlannerState extends State<DailySchedulePlanner> {
  final DatabaseHelper _db = DatabaseHelper();
  List<TimeBlock> _timeBlocks = [];
  List<Routine> _routines = [];
  List<Event> _unscheduledEvents = [];
  DateTime _selectedDate = DateTime.now();
  bool _use24HourFormat = true;
  static const double timeSlotHeight = 60.0; // Increased from 30 to 60

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load routines for the selected day
    final routines = await _db.getRoutinesForDay(_selectedDate.weekday);
    final events = await _db.getEventsForDate(_selectedDate);
    
    // Sort routines by start time
    routines.sort((a, b) {
      int aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      int bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });

    setState(() {
      _routines = routines;
      _unscheduledEvents = events.where((e) => e.startTime == null).toList();
    });
  }

  void _addTimeBlock() {
    showDialog(
      context: context,
      builder: (context) => TimeBlockDialog(
        onSave: (startTime, duration) {
          setState(() {
            _timeBlocks.add(TimeBlock(
              startTime: startTime,
              durationMinutes: duration,
            ));
          });
        },
      ),
    );
  }

  String _formatHour(int hour) {
    if (_use24HourFormat) {
      if (hour == 0) return '0:00';
      return '$hour:00';
    } else {
      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour $period';
    }
  }

  Widget _buildRoutineBlock(Routine routine) {
    final startMinutes = routine.startTime.hour * 60 + routine.startTime.minute;
    
    return Positioned(
      top: startMinutes * (timeSlotHeight / 60), // Align with time slots
      left: 0,
      right: 0,
      height: _calculateDuration(routine.startTime, routine.endTime) * (timeSlotHeight / 60),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                routine.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              if (routine.description?.isNotEmpty == true)
                Text(
                  routine.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                '${routine.startTime.format(context)} - ${routine.endTime.format(context)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _loadData();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date and toggle header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('24h'),
                      Switch(
                        value: _use24HourFormat,
                        onChanged: (value) => setState(() => _use24HourFormat = value),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_selectedDate.month}-${_selectedDate.day}-${_selectedDate.year}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          // Main scrollable area
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 24 * timeSlotHeight, // 24 hours * height per slot
                child: Stack(
                  children: [
                    // Grid lines
                    Column(
                      children: List.generate(24, (index) => Container(
                        height: timeSlotHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                      )),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time markers
                        SizedBox(
                          width: 60,
                          child: Column(
                            children: List.generate(24, (hour) {
                              return SizedBox(
                                height: timeSlotHeight,
                                child: Center(
                                  child: Text(
                                    _formatHour(hour),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // Vertical divider
                        Container(
                          width: 1,
                          height: 24 * timeSlotHeight,
                          color: Theme.of(context).dividerColor.withOpacity(0.3),
                        ),
                        // Schedule area
                        Expanded(
                          child: Stack(
                            children: [
                              // Routine blocks
                              ..._routines.map(_buildRoutineBlock),
                              // Time blocks
                              ..._timeBlocks.map((block) => Positioned(
                                top: (block.startTime.hour * 60 + block.startTime.minute) * (timeSlotHeight / 60),
                                left: 0,
                                right: 0,
                                height: block.durationMinutes * (timeSlotHeight / 60),
                                child: DragTarget<Event>(
                                  onWillAccept: (event) => event != null && block.assignedEvent == null,
                                  onAccept: (event) {
                                    setState(() {
                                      block.assignedEvent = event;
                                      _unscheduledEvents.remove(event);
                                    });
                                  },
                                  builder: (context, candidates, rejects) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: block.assignedEvent != null
                                            ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                            : Theme.of(context).colorScheme.surface,
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: block.assignedEvent != null
                                          ? ListTile(
                                              title: Text(block.assignedEvent!.title),
                                              subtitle: Text(block.startTime.format(context)),
                                            )
                                          : const Center(child: Text('Drop task here')),
                                    );
                                  },
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Unscheduled events bar
          Container(
            height: 100,
            color: Theme.of(context).colorScheme.surface,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _unscheduledEvents.length,
              itemBuilder: (context, index) {
                final event = _unscheduledEvents[index];
                return Draggable<Event>(
                  data: event,
                  feedback: Material(
                    elevation: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Theme.of(context).colorScheme.primary,
                      child: Text(
                        event.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: 100,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        event.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTimeBlock,
        child: const Icon(Icons.add),
      ),
    );
  }

  double _calculateDuration(TimeOfDay start, TimeOfDay end) {
    return (end.hour * 60 + end.minute - (start.hour * 60 + start.minute)).toDouble();
  }
}

class TimeBlock {
  final TimeOfDay startTime;
  final int durationMinutes;
  Event? assignedEvent;

  TimeBlock({
    required this.startTime,
    required this.durationMinutes,
    this.assignedEvent,
  });
}

class TimeBlockDialog extends StatefulWidget {
  final Function(TimeOfDay startTime, int duration) onSave;

  const TimeBlockDialog({super.key, required this.onSave});

  @override
  State<TimeBlockDialog> createState() => _TimeBlockDialogState();
}

class _TimeBlockDialogState extends State<TimeBlockDialog> {
  TimeOfDay _startTime = TimeOfDay.now();
  int _duration = 60;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Time Block'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Start Time: ${_startTime.format(context)}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (time != null) {
                setState(() => _startTime = time);
              }
            },
          ),
          ListTile(
            title: Text('Duration: $_duration minutes'),
            trailing: const Icon(Icons.timer),
            onTap: () async {
              // Show duration picker or input
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_startTime, _duration);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
