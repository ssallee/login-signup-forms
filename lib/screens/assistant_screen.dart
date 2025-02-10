import 'package:flutter/material.dart';
import '../services/ai_helper.dart';
import '../services/database_helper.dart';
import '../models/event.dart';
import 'routine_screen.dart';
import '../config/api_config.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final AIScheduleService _aiService = AIScheduleService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  List<List<Event>>? _scheduleOptions;

  @override
  void dispose() {
    _isLoading = false;
    super.dispose();
  }

  Future<void> _generateSchedules() async {
    if (!mounted) return;
    
    // Check if there are any events to schedule
    final events = await _dbHelper.getEvents();
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks to schedule. Please add some tasks first.')),
      );
      return;
    }

    // Check if there are any routines
    final routines = await _dbHelper.getRoutines();
    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No routines found. Consider adding routines for better scheduling.'),
          duration: Duration(seconds: 4),
        ),
      );
    }

    setState(() => _isLoading = true);
    
    try {
      final schedules = await _aiService.generateScheduleOptions(events, routines);
      
      if (!mounted) return;
      
      if (schedules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate any valid schedules. Please try again.')),
        );
        return;
      }

      setState(() => _scheduleOptions = schedules);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating schedules: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applySchedule(List<Event> schedule) async {
    try {
      await _dbHelper.deleteAllEvents();
      for (var event in schedule) {
        await _dbHelper.insertEvent(event);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule applied successfully!')),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying schedule: $e')),
      );
    }
  }

  Future<void> _suggestTimeForTask(Event task) async {
    setState(() => _isLoading = true);
    
    try {
      if (!ApiConfig.isConfigured) {
        throw Exception('OpenAI API key not configured. Please check your .env file.');
      }

      final routines = await _dbHelper.getRoutines();
      final existingEvents = await _dbHelper.getEvents();
      
      print('Suggesting time for task: ${task.title}');
      print('Found ${routines.length} routines and ${existingEvents.length} events');

      final suggestion = await _aiService.suggestTimeForTask(task, routines, existingEvents);
      
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Suggested Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Task: ${task.title}'),
              const SizedBox(height: 8),
              Text('Suggested Date: ${suggestion['suggestedDate'].toString().split(' ')[0]}'),
              Text('Start Time: ${suggestion['startTime'].format(context)}'),
              Text('Duration: ${suggestion['duration']} minutes'),
              const SizedBox(height: 8),
              Text('Reason: ${suggestion['reason']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final suggestedDate = suggestion['suggestedDate'] as DateTime;
                final startTime = suggestion['startTime'] as TimeOfDay;
                final duration = suggestion['duration'] as int;
                
                final endTime = TimeOfDay(
                  hour: (startTime.hour * 60 + startTime.minute + duration) ~/ 60 % 24,
                  minute: (startTime.hour * 60 + startTime.minute + duration) % 60,
                );

                final updatedTask = Event(
                  id: task.id,
                  title: task.title,
                  description: task.description,
                  date: suggestedDate,
                  startTime: startTime,
                  endTime: endTime,
                  isPriority: task.isPriority,
                );

                await _dbHelper.updateEvent(updatedTask);
                if (!mounted) return;
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task scheduled successfully!')),
                );
              },
              child: const Text('Apply Suggestion'),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('Error suggesting time: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating schedule options...'),
          ],
        ),
      );
    }

    if (_scheduleOptions == null) {
      return const Center(
        child: Text('Click the button above to generate schedule options'),
      );
    }

    if (_scheduleOptions!.isEmpty) {
      return const Center(
        child: Text('No valid schedules could be generated. Please try again.'),
      );
    }

    return ListView.builder(
      itemCount: _scheduleOptions!.length,
      itemBuilder: (context, index) {
        final schedule = _scheduleOptions![index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  'Schedule Option ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: ElevatedButton(
                  onPressed: () => _applySchedule(schedule),
                  child: const Text('Apply'),
                ),
              ),
              const Divider(),
              ...schedule.map((event) => ListTile(
                dense: true,
                title: Text(event.title),
                subtitle: Text(
                  '${event.date.toString().split(' ')[0]} at '
                  '${event.startTime?.format(context)} - ${event.endTime?.format(context)}',
                ),
                trailing: event.isPriority ? const Icon(Icons.priority_high, color: Colors.red) : null,
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoutineScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select a task to get scheduling suggestions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _dbHelper.getEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No tasks found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final task = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Text('Due: ${task.date.toString().split(' ')[0]}'),
                        trailing: ElevatedButton(
                          onPressed: _isLoading ? null : () => _suggestTimeForTask(task),
                          child: const Text('Suggest Time'),
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
    );
  }
}
