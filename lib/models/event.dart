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
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
      'endTime': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
      'createdAt': createdAt.toIso8601String(),
      'isPriority': isPriority ? 1 : 0, // Add this field
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTimeOfDay(String? timeString) {
      if (timeString == null) return null;
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      startTime: parseTimeOfDay(map['startTime']),
      endTime: parseTimeOfDay(map['endTime']),
      createdAt: DateTime.parse(map['createdAt']),
      isPriority: map['isPriority'] == 1, // Add this field
    );
  }
}