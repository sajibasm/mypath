import 'package:MyPath/screens/ChangePasswordScreen.dart';
import 'package:MyPath/screens/DataLogScreen.dart';
import 'package:MyPath/screens/ProfileScreen.dart';
import 'package:MyPath/screens/SessionDetailScreen.dart';
import 'package:MyPath/screens/SettingsScreen.dart';
import 'package:MyPath/screens/WheelChairScreen.dart';
import 'package:MyPath/screens/session_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/APIService.dart';
import 'screens/WelcomeScreen.dart';
import 'screens/LoginScreen.dart';
import 'screens/SignupScreen.dart';
import 'screens/ResetPasswordScreen.dart';
import 'screens/HomeScreen.dart';
import 'constants/colors.dart';

import 'models/sensor_data.dart';
import 'models/session_summary.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await APIService.loadToken();

  // Initialize Hive
  await Hive.initFlutter();

  Hive.registerAdapter(SensorDataAdapter());
  Hive.registerAdapter(SessionSummaryAdapter());

  await Hive.openBox<SensorData>('sensor_data');
  await Hive.openBox<SessionSummary>('session_summary');

  runApp(const MyPathApp(initialRoute: '/',));
}

class MyPathApp extends StatelessWidget {
  final String initialRoute;

  const MyPathApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyPath',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,

        // 👇 Set global text field cursor color
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black, // blinking caret color
        ),

        // 👇 Customize InputDecoration globally
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          labelStyle: TextStyle(
            color: Colors.black, // Label when inactive
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.black, // Label when field is focused
            fontWeight: FontWeight.w500,
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          centerTitle: false,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.white),
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),

      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => WelcomeScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/reset-password': (context) => ResetPasswordScreen(),
        '/profile': (context) =>  ProfileScreen(),
        '/data-log': (context) => DataLogScreen(), // ✅ Add this
        '/session-details': (context) => SessionDetailScreen(),
        '/session-map': (context) => SessionMapScreen(),

        '/wheelchair': (context) => WheelChairScreen(),
        '/change-password': (_) =>  ChangePasswordScreen(),
        '/settings': (context) =>  SettingsScreen(),

      },
    );
  }
}
