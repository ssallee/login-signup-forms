import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/event.dart';
import '../services/database_helper.dart';

class DailyPlannerScreen extends StatefulWidget {
  const DailyPlannerScreen({super.key});

  @override
  State<DailyPlannerScreen> createState() => _DailyPlannerScreenState();
}

class _DailyPlannerScreenState extends State<DailyPlannerScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final ScrollController _timelineController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  List<Routine> _routines = [];
  List<Event> _events = [];
  List<TimeBlock> _timeBlocks = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
    // Start timeline at 8 AM
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timelineController.jumpTo(8 * 60.0); // 8 hours * 60 pixels per hour
    });
  }

  Future<void> _loadData() async {
    final routines = await _db.getRoutinesForDay(_selectedDate.weekday);
    final events = await _db.getEventsForDate(_selectedDate);
    setState(() {
      _routines = routines;
      _events = events;
    });
  }

  void _addTimeBlock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Time Block'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create a time block for task scheduling'),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Start Time: ${TimeOfDay.now().format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    // Handle time selection
                  }
                },
              ),
              ListTile(
                title: Text('Duration: 1 hour'),
                trailing: const Icon(Icons.timer),
                onTap: () {
                  // Show duration picker
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add time block
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadData();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // Timeline
          Expanded(
            child: SingleChildScrollView(
              controller: _timelineController,
              child: Stack(
                children: [
                  // Time markers
                  for (int hour = 0; hour < 24; hour++)
                    Positioned(
                      left: 0,
                      top: hour * 60.0,
                      child: SizedBox(
                        height: 60,
                        width: 50,
                        child: Center(
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  // Routine blocks
                  ..._routines.map((routine) => Positioned(
                    left: 60,
                    top: (routine.startTime.hour * 60 + routine.startTime.minute).toDouble(),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 70,
                      height: _calculateDuration(routine.startTime, routine.endTime),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          routine.title,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  )),
                  // Draggable time blocks for events
                  // Will be implemented in the next iteration
                ],
              ),
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
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return (endMinutes - startMinutes).toDouble();
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
