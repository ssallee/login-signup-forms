import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/event.dart';
import '../models/routine.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';

class AIScheduleService {
  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<List<List<Event>>> generateScheduleOptions(List<Event> events, List<Routine> routines) async {
    if (!ApiConfig.isConfigured) {
      throw Exception('OpenAI API key not configured');
    }

    try {
      print('Making request to OpenAI...');
      print('Events count: ${events.length}');
      print('Routines count: ${routines.length}');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a scheduling assistant. Generate optimized schedules.'
            },
            {
              'role': 'user',
              'content': _createPrompt(events, routines),
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final choices = responseData['choices'];
        if (choices == null || choices.isEmpty) {
          throw Exception('No choices in response');
        }
        final content = choices[0]['message']['content'];
        return _parseAIResponse(content);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('OpenAI Error: ${error['error']['message']}');
      }
    } catch (e, stackTrace) {
      print('AI Service Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> suggestTimeForTask(Event task, List<Routine> routines, List<Event> existingEvents) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a scheduling assistant. Suggest the best time to work on a task.'
            },
            {
              'role': 'user',
              'content': _createTaskPrompt(task, routines, existingEvents),
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final suggestion = jsonDecode(response.body)['choices'][0]['message']['content'];
        return _parseTaskSuggestion(suggestion);
      } else {
        throw Exception('OpenAI Error: ${jsonDecode(response.body)['error']['message']}');
      }
    } catch (e) {
      print('AI Service Error: $e');
      rethrow;
    }
  }

  String _createPrompt(List<Event> events, List<Routine> routines) {
    return '''
Create an optimized schedule considering these inputs:

ROUTINES (Fixed times that cannot be changed):
${_formatRoutines(routines)}

TASKS TO SCHEDULE:
${_formatEvents(events)}

Generate three different schedule variations:
1. Morning-focused schedule
2. Afternoon-focused schedule
3. Balanced schedule

FORMAT:
Each schedule must be a JSON array. Use this exact format and separate schedules with "---":
[
  {
    "title": string,
    "date": "YYYY-MM-DDT00:00:00.000Z",
    "startTime": "HH:mm",
    "endTime": "HH:mm",
    "description": string
  }
]

RULES:
- Never schedule during routine times
- Include 15-30 minute breaks between tasks
- Only schedule between 8 AM and 8 PM
- Group similar tasks when possible
- Prioritize tasks marked as high priority
- Each schedule must be a valid JSON array
''';
  }

  String _createTaskPrompt(Event task, List<Routine> routines, List<Event> existingEvents) {
    return '''
Task to schedule:
${task.title}
Due date: ${task.date.toString().split(' ')[0]}
Priority: ${task.isPriority ? 'High' : 'Normal'}
Description: ${task.description}

Daily routines:
${_formatRoutines(routines)}

Already scheduled events:
${_formatEvents(existingEvents)}

Please suggest the best time to work on this task.
Consider:
1. Task due date
2. Priority level
3. Never scheduling during routine times
4. Avoiding conflicts with existing events
5. Scheduling during reasonable hours (8 AM - 8 PM)
6. Allow enough time based on task complexity
7. Never schedule for past dates

Respond in this JSON format only:
{
  "suggestedDate": "YYYY-MM-DD",
  "startTime": "HH:mm",
  "duration": "number of minutes",
  "reason": "brief explanation of why this time was chosen"
}
''';
  }

  String _formatRoutines(List<Routine> routines) {
    return routines.map((r) => 
      '- ${r.title}: ${r.daysOfWeek.map((d) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d-1]).join(", ")} at ${_formatTime(r.startTime)}-${_formatTime(r.endTime)}'
    ).join('\n');
  }

  String _formatEvents(List<Event> events) {
    return events.map((e) => 
      '- ${e.title}: Due ${e.date.toIso8601String()}'
    ).join('\n');
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  List<List<Event>> _parseAIResponse(String response) {
    try {
      List<List<Event>> schedules = [];
      final scheduleTexts = response.split('---');
      
      for (var scheduleText in scheduleTexts) {
        try {
          // Extract JSON array from text
          final match = RegExp(r'\[[\s\S]*\]').firstMatch(scheduleText);
          if (match == null) continue;
          
          final jsonStr = match.group(0)!;
          final List<dynamic> scheduleJson = jsonDecode(jsonStr);
          
          schedules.add(
            scheduleJson.map<Event>((e) => Event.fromMap({
              ...e,
              'startTime': e['startTime'],
              'endTime': e['endTime'],
              'description': e['description'] ?? '',
              'isPriority': false,
            })).toList()
          );
        } catch (e) {
          print('Error parsing schedule: $e');
        }
      }
      return schedules;
    } catch (e) {
      print('Error parsing AI response: $e');
      return [];
    }
  }

  Map<String, dynamic> _parseTaskSuggestion(String response) {
    try {
      // Extract JSON from response
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (match == null) throw Exception('Invalid response format');
      
      final suggestion = jsonDecode(match.group(0)!);
      return {
        'suggestedDate': DateTime.parse(suggestion['suggestedDate']),
        'startTime': _parseTimeString(suggestion['startTime']),
        'duration': int.parse(suggestion['duration'].toString()),
        'reason': suggestion['reason'],
      };
    } catch (e) {
      print('Error parsing suggestion: $e');
      throw Exception('Failed to parse AI suggestion');
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}