import 'package:flutter/material.dart';
import 'package:login_signup/screens/welcome_screen.dart';
import 'package:login_signup/theme/theme.dart';
import '../services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final dbHelper = DatabaseHelper();
  await dbHelper.initDatabase();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: lightMode,
      home: const WelcomeScreen(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app. Please restart.'),
        ),
      ),
    );
  }
}