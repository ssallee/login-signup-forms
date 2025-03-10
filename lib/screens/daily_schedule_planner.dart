import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/event.dart';
import '../services/database_helper.dart';
import 'dart:async';

// Define an enum for block types
enum TimeBlockType {
  work,     // Basic block for working on tasks
  rest,     // Block that allows for nothing (rest, break)
  overflow  // For urgent tasks that need immediate attention
}

// Simplify the enum for repetition options
enum RepeatOption {
  none,
  daily,
  weekly
}

class DailySchedulePlanner extends StatefulWidget {
  const DailySchedulePlanner({super.key});

  @override
  State<DailySchedulePlanner> createState() => _DailySchedulePlannerState();
}

class _DailySchedulePlannerState extends State<DailySchedulePlanner> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  List<TimeBlock> _timeBlocks = [];
  List<Routine> _routines = [];
  List<Event> _unscheduledEvents = [];
  DateTime _selectedDate = DateTime.now();
  bool _use24HourFormat = true;
  static const double timeSlotHeight = 120.0; // Doubled from 60 to 120

  // Add properties for tracking the selected time slot
  TimeOfDay? _selectedTimeSlot;
  int? _selectedHour;
  bool? _selectedIsHalfHour;

  // Add property to track all available events
  List<Event> _allEvents = [];

  // Add a ScrollController to properly manage scroll animations
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadData();
  }

  @override
  void dispose() {
    // Clean up controllers to prevent animation errors
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load routines for the selected day
    final routines = await _db.getRoutinesForDay(_selectedDate.weekday);
    
    // Load all events, not just unscheduled ones
    final events = await _db.getEvents();
    
    // Sort routines by start time
    routines.sort((a, b) {
      int aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      int bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });

    // Filter for unscheduled and future events
    final unscheduledEvents = events.where((e) => e.startTime == null).toList();
    final futureEvents = events.where((e) {
      // Get events that are in the future (today or later)
      final now = DateTime.now();
      return e.date.isAfter(now.subtract(const Duration(days: 1))) && e.startTime == null;
    }).toList();

    setState(() {
      _routines = routines;
      _unscheduledEvents = unscheduledEvents;
      _allEvents = futureEvents; // Store all future events
    });
  }

  // Update the time slot tap handler
  void _handleTimeSlotTap(int hour, bool isHalfHour) {
    setState(() {
      // Toggle selection if the same slot is tapped again
      if (_selectedHour == hour && _selectedIsHalfHour == isHalfHour) {
        _selectedHour = null;
        _selectedIsHalfHour = null;
        _selectedTimeSlot = null;
      } else {
        _selectedHour = hour;
        _selectedIsHalfHour = isHalfHour;
        _selectedTimeSlot = TimeOfDay(hour: hour, minute: isHalfHour ? 30 : 0);
      }
    });
  }
  
  // Updated to use the current selection if available
  void _showAddTimeBlockDialog() {
    final timeToUse = _selectedTimeSlot ?? _roundToNearestHalfHour(TimeOfDay.now());
    _showTimeBlockDialog(timeToUse);
  }

  // Modified to check for time slot availability
  void _showTimeBlockDialog(TimeOfDay initialStartTime) {
    // Check if this time slot is already occupied
    if (_isTimeSlotOccupied(initialStartTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A time block already exists at this time.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => TimeBlockDialog(
        initialStartTime: initialStartTime,
        selectedDate: _selectedDate,
        onSave: (startTime, duration, blockType, repeatOption) {
          // Check again before saving (in case user changed time in dialog)
          if (_isTimeSlotOccupied(startTime)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot create block: time slot overlap detected.'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          
          setState(() {
            _timeBlocks.add(TimeBlock(
              startTime: startTime,
              durationMinutes: duration,
              type: blockType,
              repeatOption: repeatOption,
              startDate: _selectedDate,
            ));
            
            // If this is a repeating block, create additional instances (for UI display)
            if (repeatOption != RepeatOption.none) {
              _createRepeatingBlocks(startTime, duration, blockType, repeatOption);
            }
          });
        },
      ),
    );
  }
  
  // Helper method to check if a time slot is already occupied
  bool _isTimeSlotOccupied(TimeOfDay startTime) {
    // Convert to minutes for easier comparison
    final startMinutes = startTime.hour * 60 + startTime.minute;
    
    // Check existing time blocks
    for (final block in _timeBlocks) {
      // Only check blocks for the current date
      if (!_isSameDay(block.startDate, _selectedDate)) continue;
      
      final blockStart = block.startTime.hour * 60 + block.startTime.minute;
      final blockEnd = blockStart + block.durationMinutes;
      
      // Check if new time overlaps with existing block
      if (startMinutes >= blockStart && startMinutes < blockEnd) {
        return true;
      }
    }
    
    // Check routine blocks too
    for (final routine in _routines) {
      final routineStart = routine.startTime.hour * 60 + routine.startTime.minute;
      final routineEnd = routine.endTime.hour * 60 + routine.endTime.minute;
      
      if (routineStart <= startMinutes && startMinutes < routineEnd) {
        return true;
      }
    }
    
    return false;
  }
  
  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  // Add method to create repeating blocks for preview purposes
  void _createRepeatingBlocks(
    TimeOfDay startTime, 
    int duration, 
    TimeBlockType blockType, 
    RepeatOption repeatOption
  ) {
    // Create a few instances for preview (won't actually be created in the database)
    DateTime currentDate = _selectedDate;
    
    // Show next 3 occurrences
    for (int i = 0; i < 3; i++) {
      // Calculate next date based on repeat option
      switch (repeatOption) {
        case RepeatOption.daily:
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case RepeatOption.weekly:
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case RepeatOption.none:
          return; // Should not happen
      }
      
      // Add a preview time block with the calculated date
      _timeBlocks.add(TimeBlock(
        startTime: startTime,
        durationMinutes: duration,
        type: blockType,
        repeatOption: repeatOption,
        startDate: currentDate,
      ));
    }
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

  Widget _buildTimeLabel(int hour) {
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 4.0),
      decoration: BoxDecoration(
        border: Border(
          top: hour > 0 ? BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 0.5,
          ) : BorderSide.none,
        ),
      ),
      child: Text(
        _formatHour(hour),
        style: TextStyle(
          fontSize: 16, // Increased from 12
          fontWeight: FontWeight.bold, // Changed from w500
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
        ),
      ),
    );
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

  // Add method to handle block tap
  void _handleBlockTap(TimeBlock block) {
    if (!block.canAcceptTasks()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rest blocks cannot have tasks assigned to them')),
      );
      return;
    }
    
    // If block already has an event, show options to remove it
    if (block.assignedEvent != null) {
      _showBlockEventOptions(block);
      return;
    }
    
    // Otherwise, show available events to assign
    _showEventSelectionDialog(block);
  }
  
  // Show dialog to select an event for a block
  void _showEventSelectionDialog(TimeBlock block) {
    // If no events are available, show message
    if (_allEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No events available. Add events in the Calendar tab.')),
      );
      return;
    }
    
    // Avoid animation errors by using this pattern
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text('Assign Event to ${block.startTime.format(context)} Block'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Events:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _allEvents.length,
                    itemBuilder: (context, index) {
                      final event = _allEvents[index];
                      return ListTile(
                        title: Text(event.title),
                        subtitle: Text('Due: ${_formatDate(event.date)}'),
                        trailing: event.isPriority 
                          ? const Icon(Icons.priority_high, color: Colors.red)
                          : null,
                        onTap: () {
                          _assignEventToBlock(event, block);
                          // Use the dialogContext to close safely
                          Navigator.of(dialogContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  // Show options for a block with an assigned event
  void _showBlockEventOptions(TimeBlock block) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text('Block: ${block.startTime.format(context)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event: ${block.assignedEvent!.title}', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Duration: ${block.durationMinutes} minutes'),
              const SizedBox(height: 16),
              const Text('Options:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Make the event available again
                  _allEvents.add(block.assignedEvent!);
                  block.assignedEvent = null;
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Remove Event'),
            ),
          ],
        ),
      );
    }
  }
  
  // Helper method to assign an event to a block
  void _assignEventToBlock(Event event, TimeBlock block) {
    setState(() {
      // Update event times based on block
      final updatedEvent = Event(
        id: event.id,
        title: event.title,
        description: event.description,
        date: _selectedDate,
        startTime: block.startTime,
        endTime: _getEndTime(block),
        isPriority: event.isPriority,
      );
      
      // Assign to block and update database
      block.assignedEvent = updatedEvent;
      
      // Remove from available events
      _allEvents.removeWhere((e) => e.id == event.id);
      
      // Update in database
      _db.updateEvent(updatedEvent);
    });
  }
  
  // Helper to get end time from a block
  TimeOfDay _getEndTime(TimeBlock block) {
    final int totalMinutes = block.startTime.hour * 60 + block.startTime.minute + block.durationMinutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  // Helper to format date
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Schedule'),
        actions: [
          // Add help button to explain block types
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Block Types',
            onPressed: () => _showHelpDialog(),
          ),
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
          // Date and toggle header (keep this)
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
          // Main scrollable area (keep this)
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController, // Add controller here
              physics: const ClampingScrollPhysics(), // Use more stable scroll physics
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 24 * timeSlotHeight, // 24 hours with doubled height
                child: Stack(
                  children: [
                    // Background grid lines
                    Column(
                      children: List.generate(24, (hour) {
                        return Container(
                          height: timeSlotHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: timeSlotHeight / 2,
                              ),
                              Container(
                                height: 1,
                                color: Theme.of(context).dividerColor.withOpacity(0.1),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time markers with updated sizing
                        Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(1, 0),
                              ),
                            ],
                          ),
                          child: Column(
                            children: List.generate(24, (hour) {
                              return SizedBox(
                                height: timeSlotHeight, // Doubled height
                                child: _buildTimeLabel(hour),
                              );
                            }),
                          ),
                        ),
                        // Vertical divider
                        Container(
                          width: 1,
                          height: 24 * timeSlotHeight, // Doubled height
                          color: Theme.of(context).dividerColor.withOpacity(0.3),
                        ),
                        // Interactive schedule area with selections
                        Expanded(
                          child: Stack(
                            children: [
                              // Interactive grid
                              Column(
                                children: List.generate(24, (hour) {
                                  return Column(
                                    children: [
                                      // Full hour slot
                                      InkWell(
                                        onTap: () => _handleTimeSlotTap(hour, false),
                                        child: Container(
                                          height: timeSlotHeight / 2,
                                          width: double.infinity,
                                          color: (_selectedHour == hour && _selectedIsHalfHour == false)
                                              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      // Half hour slot
                                      InkWell(
                                        onTap: () => _handleTimeSlotTap(hour, true),
                                        child: Container(
                                          height: timeSlotHeight / 2,
                                          width: double.infinity,
                                          color: (_selectedHour == hour && _selectedIsHalfHour == true)
                                              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                              
                              // Content (routine blocks and time blocks)
                              Stack(
                                children: [
                                  // Routine blocks
                                  ..._routines.map(_buildRoutineBlock),
                                  // Time blocks - modified to be tappable
                                  ..._timeBlocks.map((block) => Positioned(
                                    top: (block.startTime.hour * 60 + block.startTime.minute) * (timeSlotHeight / 60),
                                    left: 0,
                                    right: 0,
                                    height: block.durationMinutes * (timeSlotHeight / 60),
                                    child: GestureDetector(
                                      onTap: () => _handleBlockTap(block),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: block.assignedEvent != null
                                              ? block.getBlockColor(context).withOpacity(0.6)
                                              : block.getBlockColor(context),
                                          border: Border.all(
                                            color: block.getBorderColor(context),
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: block.assignedEvent != null
                                            ? ListTile(
                                                title: Text(block.assignedEvent!.title),
                                                subtitle: Text('${block.startTime.format(context)} - ${_getEndTime(block).format(context)}'),
                                                trailing: block.type == TimeBlockType.overflow
                                                    ? const Icon(Icons.warning_amber, color: Colors.orange)
                                                    : null,
                                              )
                                            : Center(
                                                child: block.type == TimeBlockType.rest 
                                                    ? const Text('Rest Time') 
                                                    : const Text('Tap to assign task'),
                                              ),
                                      ),
                                    ),
                                  )),
                                ],
                              ),
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
        ],
      ),
      // Update FAB to use selected time
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(_selectedTimeSlot != null 
          ? 'Add Block at ${_selectedTimeSlot!.format(context)}' 
          : 'Add Time Block'),
        onPressed: _showAddTimeBlockDialog,
      ),
    );
  }

  // Update help dialog to explain block types
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Block Types'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBlockTypeExplanation(
              'Work Block', 
              Theme.of(context).colorScheme.primary.withOpacity(0.3),
              'For focused work on tasks. Drag tasks into these blocks.'
            ),
            const SizedBox(height: 16),
            _buildBlockTypeExplanation(
              'Rest Block', 
              Colors.green.withOpacity(0.3),
              'Protected time for breaks. No tasks allowed.'
            ),
            const SizedBox(height: 16),
            _buildBlockTypeExplanation(
              'Overflow Block', 
              Colors.orange.withOpacity(0.3),
              'For urgent tasks that need immediate attention.'
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text('• Tap any time slot to select it'),
            const SizedBox(height: 8),
            const Text('• Use the + button to create a block'),
            const SizedBox(height: 8),
            const Text('• All blocks snap to half-hour marks'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // Helper widget to display block type with color and explanation
  Widget _buildBlockTypeExplanation(String title, Color color, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(right: 8, top: 2),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: color.withOpacity(0.8),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(description, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  // Add a quick selection dialog for creating blocks
  void _showQuickAddDialog() {
    final now = TimeOfDay.now();
    final roundedNow = _roundToNearestHalfHour(now);
    
    // Generate common times for selection
    List<TimeOfDay> quickTimes = [];
    
    // Add current time rounded to nearest half hour
    quickTimes.add(roundedNow);
    
    // Add next few half-hour slots
    for (int i = 1; i <= 4; i++) {
      int minutes = roundedNow.hour * 60 + roundedNow.minute + (i * 30);
      quickTimes.add(TimeOfDay(
        hour: (minutes ~/ 60) % 24,
        minute: minutes % 60,
      ));
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Time Block'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a start time:'),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quickTimes.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    onPressed: () => _showTimeBlockDialog(quickTimes[index]),
                    child: Text(quickTimes[index].format(context)),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.access_time),
              label: const Text('Choose Another Time'),
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: roundedNow,
                );
                if (time != null) {
                  Navigator.pop(context);
                  _showTimeBlockDialog(_roundToNearestHalfHour(time));
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  TimeOfDay _roundToNearestHalfHour(TimeOfDay time) {
    // Round minutes to either 0 or 30
    int minute = time.minute < 15 ? 0 : (time.minute < 45 ? 30 : 0);
    int hour = time.minute < 45 ? time.hour : (time.hour + 1) % 24;
    return TimeOfDay(hour: hour, minute: minute);
  }

  double _calculateDuration(TimeOfDay start, TimeOfDay end) {
    return (end.hour * 60 + end.minute - (start.hour * 60 + start.minute)).toDouble();
  }
}

// Update TimeBlock class to include type
class TimeBlock {
  final TimeOfDay startTime;
  final int durationMinutes;
  final TimeBlockType type;
  final RepeatOption repeatOption;  // Add repeat option
  final DateTime startDate;         // Starting date of the block

  // Add safety checks when setting/getting the assigned event
  Event? _assignedEvent;

  Event? get assignedEvent => _assignedEvent;

  set assignedEvent(Event? event) {
    _assignedEvent = event;
    // No animation controllers used here that could cause issues
  }

  TimeBlock({
    required this.startTime,
    required this.durationMinutes,
    Event? assignedEvent,
    required this.type, // Make type required
    this.repeatOption = RepeatOption.none,  // Default to no repeat
    DateTime? startDate,
  }) : 
    _assignedEvent = assignedEvent,
    startDate = startDate ?? DateTime.now();
  
  // Get the color based on block type
  Color getBlockColor(BuildContext context) {
    switch (type) {
      case TimeBlockType.work:
        return Theme.of(context).colorScheme.primary.withOpacity(0.3);
      case TimeBlockType.rest:
        return Colors.green.withOpacity(0.3);
      case TimeBlockType.overflow:
        return Colors.orange.withOpacity(0.3);
    }
  }
  
  // Get border color based on block type
  Color getBorderColor(BuildContext context) {
    switch (type) {
      case TimeBlockType.work:
        return Theme.of(context).colorScheme.primary;
      case TimeBlockType.rest:
        return Colors.green;
      case TimeBlockType.overflow:
        return Colors.orange;
    }
  }
  
  // Check if a block can accept tasks
  bool canAcceptTasks() {
    return type != TimeBlockType.rest;
  }
}

class TimeBlockDialog extends StatefulWidget {
  final Function(TimeOfDay startTime, int duration, TimeBlockType type, RepeatOption repeatOption) onSave; // Updated signature
  final TimeOfDay initialStartTime;
  final DateTime selectedDate;

  const TimeBlockDialog({
    super.key, 
    required this.onSave,
    required this.initialStartTime,
    required this.selectedDate,
  });

  @override
  State<TimeBlockDialog> createState() => _TimeBlockDialogState();
}

// Update TimeBlockDialog to limit duration to 2 hours max and simplify repetition UI
class _TimeBlockDialogState extends State<TimeBlockDialog> {
  late TimeOfDay _startTime;
  int _duration = 60; // Default to 60 minutes (1 hour)
  // Update duration options to max of 2 hours
  final List<int> _durationOptions = [30, 60, 90, 120]; // Max 120 minutes (2 hours)
  TimeBlockType _blockType = TimeBlockType.work;
  
  // Simplified repeat options
  bool _isRepeating = false;
  RepeatOption _repeatOption = RepeatOption.daily;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStartTime;
  }

  TimeOfDay _roundToNearestHalfHour(TimeOfDay time) {
    // Round minutes to either 0 or 30
    int minute = time.minute < 15 ? 0 : (time.minute < 45 ? 30 : 0);
    int hour = time.minute < 45 ? time.hour : (time.hour + 1) % 24;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Time Block'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the selected date
            Text(
              'Date: ${_formatDate(widget.selectedDate)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Existing start time selection
            ListTile(
              title: Text('Start Time: ${_startTime.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        alwaysUse24HourFormat: true,
                      ),
                      child: child!,
                    );
                  },
                );
                if (time != null) {
                  setState(() => _startTime = _roundToNearestHalfHour(time));
                }
              },
            ),

            // Block type selection
            const SizedBox(height: 16),
            const Text('Block Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<TimeBlockType>(
              segments: const [
                ButtonSegment<TimeBlockType>(
                  value: TimeBlockType.work,
                  label: Text('Work'),
                  icon: Icon(Icons.work),
                ),
                ButtonSegment<TimeBlockType>(
                  value: TimeBlockType.rest,
                  label: Text('Rest'),
                  icon: Icon(Icons.coffee),
                ),
                ButtonSegment<TimeBlockType>(
                  value: TimeBlockType.overflow,
                  label: Text('Overflow'),
                  icon: Icon(Icons.warning_amber),
                ),
              ],
              selected: {_blockType},
              onSelectionChanged: (Set<TimeBlockType> selection) {
                if (selection.isNotEmpty) {
                  setState(() => _blockType = selection.first);
                }
              },
            ),
            
            // Duration selection
            const SizedBox(height: 16),
            const Text('Duration (max 2 hours):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durationOptions.map((duration) {
                String label = duration < 60 
                    ? '$duration min' 
                    : '${duration ~/ 60}${duration % 60 > 0 ? '.5' : ''} hr';
                    
                return ChoiceChip(
                  label: Text(label),
                  selected: _duration == duration,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _duration = duration);
                    }
                  },
                );
              }).toList(),
            ),

            // Simplified repeat options
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // Simpler repeat section
            Row(
              children: [
                const Text('Repeat:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Switch(
                  value: _isRepeating,
                  onChanged: (value) => setState(() => _isRepeating = value),
                ),
              ],
            ),
            
            // Only show frequency options if repeating is enabled
            if (_isRepeating) ...[
              const SizedBox(height: 8),
              SegmentedButton<RepeatOption>(
                segments: const [
                  ButtonSegment<RepeatOption>(
                    value: RepeatOption.daily,
                    label: Text('Daily'),
                  ),
                  ButtonSegment<RepeatOption>(
                    value: RepeatOption.weekly,
                    label: Text('Weekly'),
                  ),
                ],
                selected: {_repeatOption},
                onSelectionChanged: (Set<RepeatOption> selection) {
                  if (selection.isNotEmpty) {
                    setState(() => _repeatOption = selection.first);
                  }
                },
              ),
            ],
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
            final repeatOption = _isRepeating ? _repeatOption : RepeatOption.none;
            widget.onSave(_startTime, _duration, _blockType, repeatOption);
            Navigator.pop(context);
          },
          child: const Text('Create Block'),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
