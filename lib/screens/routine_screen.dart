import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/database_helper.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Routine> _routines = [];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final routines = await _dbHelper.getRoutines();
    setState(() => _routines = routines);
  }

  void _showRoutineDialog([Routine? routine]) {
    final isEditing = routine != null;
    String title = routine?.title ?? '';
    String description = routine?.description ?? '';
    TimeOfDay startTime = routine?.startTime ?? TimeOfDay.now();
    TimeOfDay endTime = routine?.endTime ?? TimeOfDay.now();
    List<int> selectedDays = routine?.daysOfWeek ?? [];
    String? titleError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Routine' : 'Add Routine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: title),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    errorText: titleError,
                  ),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: description),
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (value) => description = value,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Start Time: ${startTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (time != null) {
                      setState(() => startTime = time);
                    }
                  },
                ),
                ListTile(
                  title: Text('End Time: ${endTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (time != null) {
                      setState(() => endTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Repeat on:', style: TextStyle(fontSize: 16)),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    return FilterChip(
                      label: Text(_weekDays[index]),
                      selected: selectedDays.contains(index + 1),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedDays.add(index + 1);
                          } else {
                            selectedDays.remove(index + 1);
                          }
                          selectedDays.sort();
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (title.isEmpty) {
                  setState(() => titleError = 'Title is required');
                  return;
                }
                if (selectedDays.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select at least one day')),
                  );
                  return;
                }

                final newRoutine = Routine(
                  id: routine?.id,
                  title: title,
                  description: description,
                  startTime: startTime,
                  endTime: endTime,
                  daysOfWeek: selectedDays,
                );

                if (isEditing) {
                  await _dbHelper.updateRoutine(newRoutine);
                } else {
                  await _dbHelper.insertRoutine(newRoutine);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _loadRoutines();
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Routines'),
      ),
      body: ListView.builder(
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return ListTile(
            title: Text(routine.title),
            subtitle: Text(
              '${routine.daysOfWeek.map((d) => _weekDays[d-1]).join(', ')}\n'
              '${routine.startTime.format(context)} - ${routine.endTime.format(context)}'
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showRoutineDialog(routine),
            ),
            onLongPress: () => _showDeleteDialog(routine),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoutineDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showDeleteDialog(Routine routine) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text('Delete "${routine.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _dbHelper.deleteRoutine(routine.id!);
              Navigator.pop(context);
              _loadRoutines();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
