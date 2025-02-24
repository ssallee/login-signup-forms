import 'package:flutter/material.dart';
import '../widgets/calendar_widget.dart';


class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        
      ),
      body: const CalendarWidget(),
    );
  }
}