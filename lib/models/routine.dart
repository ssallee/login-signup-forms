import 'package:flutter/material.dart';

class Routine {
  final int? id;
  final String title;
  final String? description;
  final List<int> daysOfWeek; // 1-7 for Monday-Sunday
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isActive;

  Routine({
    this.id,
    required this.title,
    this.description,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'daysOfWeek': daysOfWeek.join(','),
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    TimeOfDay _parseTimeOfDay(String timeString) {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return Routine(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      daysOfWeek: (map['daysOfWeek'] as String)
          .split(',')
          .map((e) => int.parse(e))
          .toList(),
      startTime: _parseTimeOfDay(map['startTime']),
      endTime: _parseTimeOfDay(map['endTime']),
      isActive: map['isActive'] == 1,
    );
  }
}
