import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/database_helper.dart';
import 'home_screen.dart';

class UpcomingTasksScreen extends StatefulWidget {
  const UpcomingTasksScreen({super.key});

  @override
  State<UpcomingTasksScreen> createState() => _UpcomingTasksScreenState();
}

class _UpcomingTasksScreenState extends State<UpcomingTasksScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Map<String, List<Event>> _groupedEvents = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final allEvents = await _db.getFutureEvents();
    final now = DateTime.now();
    
    // Calculate the start and end of the current week (Sunday to Saturday)
    final startOfWeek = now.subtract(Duration(days: now.weekday));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    // Initialize empty lists for each category
    final grouped = {
      'Urgent': <Event>[],
      'Today': <Event>[],
      'This Week': <Event>[],
      'This Month': <Event>[],
      'Later': <Event>[],
    };

    for (var event in allEvents) {
      // Add high priority tasks to Urgent
      if (event.isPriority) {
        grouped['Urgent']!.add(event);
        continue;
      }

      // Categorize by time
      if (event.date.year == now.year && 
          event.date.month == now.month && 
          event.date.day == now.day) {
        grouped['Today']!.add(event);
      } 
      // Check if the event falls within the current calendar week
      else if (event.date.isAfter(startOfWeek) && 
               event.date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
        grouped['This Week']!.add(event);
      }
      // Check if event is within the current month
      else if (event.date.year == now.year && 
               event.date.month == now.month) {
        grouped['This Month']!.add(event);
      }
      // Everything else goes to Later
      else {
        grouped['Later']!.add(event);
      }
    }

    // Sort each category by date and time
    grouped.forEach((key, list) {
      list.sort((a, b) {
        int dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) return dateComparison;
        
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        
        int hourComparison = a.startTime!.hour.compareTo(b.startTime!.hour);
        if (hourComparison != 0) return hourComparison;
        
        return a.startTime!.minute.compareTo(b.startTime!.minute);
      });
    });

    setState(() {
      _groupedEvents = grouped;
    });
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      if (date.day == now.day) {
        return 'Today';
      }
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks';
    } else {
      return '${(difference.inDays / 30).floor()} months';
    }
  }

  Widget _buildTaskCard(Event event) {
    final timeLeft = _getRelativeTime(event.date);
    
    return Card(
      elevation: event.isPriority ? 3 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 4,
          color: event.isPriority ? Colors.red : Colors.blue,
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: event.isPriority ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          event.description.isEmpty ? 'No description' : event.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeLeft,
              style: TextStyle(
                color: event.isPriority ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (event.startTime != null)
              Text(
                event.startTime!.format(context),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        onTap: () {
          // Show task details or edit dialog
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Event> events) {
    if (events.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: title == 'Urgent' ? Colors.red[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  events.length.toString(),
                  style: TextStyle(
                    color: title == 'Urgent' ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...events.map(_buildTaskCard).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView(
          children: [
            _buildSection('Urgent', _groupedEvents['Urgent'] ?? []),
            _buildSection('Today', _groupedEvents['Today'] ?? []),
            _buildSection('This Week', _groupedEvents['This Week'] ?? []),
            _buildSection('This Month', _groupedEvents['This Month'] ?? []),
            _buildSection('Later', _groupedEvents['Later'] ?? []),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Home(),
              ),
            );
          }
        },
      ),
    );
  }
}
