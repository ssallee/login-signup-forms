import 'package:flutter/material.dart';
import '../models/event.dart';
import '../dialogs/event_dialogs.dart';

class EventList extends StatelessWidget {
  final List<Event> events;
  final Function() onEventModified;

  const EventList({
    super.key,
    required this.events,
    required this.onEventModified,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text('No events for this day',
          style: TextStyle(fontSize: 14, color: Colors.grey)
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          event: event,
          onEventModified: onEventModified,
        );
      },
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final Function() onEventModified;

  const EventCard({
    super.key,
    required this.event,
    required this.onEventModified,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: InkWell(
        onLongPress: () => _showEventOptions(context),
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
          subtitle: event.description.isNotEmpty
              ? Text(
                  event.description,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: _buildTimeDisplay(context),
        ),
      ),
    );
  }

  Widget? _buildTimeDisplay(BuildContext context) {
    if (event.startTime == null) return null;
    
    return Text(
      '${event.startTime!.format(context)}${event.endTime != null ? '\n${event.endTime!.format(context)}' : ''}',
      style: const TextStyle(fontSize: 12),
      textAlign: TextAlign.right,
    );
  }

  void _showEventOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => EventOptionsSheet(
        event: event,
        onEventModified: onEventModified,
      ),
    );
  }
}
