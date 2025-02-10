import 'package:flutter/material.dart';

class Event {
  final int? id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final DateTime createdAt;
  final bool isPriority; // Add this field

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.startTime,
    this.endTime,
    DateTime? createdAt,
    this.isPriority = false, // Add this parameter
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    String? timeToString(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour}:${time.minute}';
    }

    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': timeToString(startTime),
      'endTime': timeToString(endTime),
      'createdAt': createdAt.toIso8601String(),
      'isPriority': isPriority ? 1 : 0,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTimeOfDay(String? timeString) {
      if (timeString == null || timeString.isEmpty) return null;
      try {
        final parts = timeString.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        return null;
      }
    }

    return Event(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      startTime: parseTimeOfDay(map['startTime']?.toString()),
      endTime: parseTimeOfDay(map['endTime']?.toString()),
      createdAt: DateTime.parse(map['createdAt']),
      isPriority: map['isPriority'] == 1,
    );
  }
}