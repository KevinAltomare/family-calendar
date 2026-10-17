import 'package:flutter/material.dart';

import 'services/calendar_service.dart';
import 'services/planner_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CalendarService.instance.load();
  await PlannerService.instance.load();
  runApp(const CalendarDisplayApp());
}

class CalendarDisplayApp extends StatelessWidget {
  const CalendarDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5476A8),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F7F9),
          foregroundColor: Color(0xFF202A38),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF202A38),
          ),
          bodyLarge: TextStyle(fontSize: 18, color: Color(0xFF202A38)),
        ),
      ),
    );
  }
}
