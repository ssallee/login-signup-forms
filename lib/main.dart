import 'package:flutter/material.dart';
import 'package:login_signup/screens/welcome_screen.dart';
import 'package:login_signup/theme/theme_provider.dart';
import '../services/database_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:login_signup/screens/settings.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await ApiConfig.initialize();
    final dbHelper = DatabaseHelper();
    await dbHelper.initDatabase();
    
    if (!ApiConfig.isConfigured) {
      print('Warning: OpenAI API key not configured');
    }
    
    runApp(const MyApp());
  } catch (e) {
    print('Error during initialization: $e');
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child:
            Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
          return MaterialApp(
            theme: ThemeData(
                useMaterial3: true, colorScheme: themeProvider.lightScheme),
            darkTheme: ThemeData(
                useMaterial3: true, colorScheme: themeProvider.darkScheme),
            themeMode: themeProvider.themeMode,
            home: const WelcomeScreen(),
          );
        }));
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