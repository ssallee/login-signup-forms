import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/database_helper.dart';

class EventDialogs {
  static final DatabaseHelper _db = DatabaseHelper();

  static Future<void> showAddEventDialog(BuildContext context, DateTime selectedDate) async {
    // Move the add event dialog code here
  }

  static Future<void> showEditEventDialog(BuildContext context, Event event) async {
    // Move the edit event dialog code here
  }

  static Future<void> showDeleteConfirmation(BuildContext context, Event event) async {
    // Move the delete confirmation dialog code here
  }
}

class EventOptionsSheet extends StatelessWidget {
  final Event event;
  final Function() onEventModified;

  const EventOptionsSheet({
    super.key,
    required this.event,
    required this.onEventModified,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit Event'),
          onTap: () {
            Navigator.pop(context);
            EventDialogs.showEditEventDialog(context, event)
                .then((_) => onEventModified());
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Delete Event', 
            style: TextStyle(color: Colors.red),
          ),
          onTap: () {
            Navigator.pop(context);
            EventDialogs.showDeleteConfirmation(context, event)
                .then((_) => onEventModified());
          },
        ),
      ],
    );
  }
}
