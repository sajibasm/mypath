import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/welcome.dart';
import 'screens/login.dart';
import 'screens/reset_password.dart';
import 'screens/home.dart';
import 'constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load token from secure storage before running the app
  await ApiService.loadToken();

  runApp(const MyPathApp());
}

class MyPathApp extends StatelessWidget {
  const MyPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyPath',
      debugShowCheckedModeBanner: false,

      // 🌍 Global Theme
      theme: ThemeData(
        primaryColor: AppColors.primary, // or AppColors.primary
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue, // or AppColors.primary
          centerTitle: false, // Align title to left
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

      // 🧭 Dynamic initial route based on token
      initialRoute: ApiService.hasToken ? '/home' : '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/reset-password': (context) => ResetPasswordScreen(),
      },
    );
  }
}
