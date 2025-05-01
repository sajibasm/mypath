import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart'; // <-- import
import 'screens/welcome.dart';
import 'screens/login.dart';
import 'screens/reset_password.dart';
import 'screens/home.dart';
import 'constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiService.loadToken();
  final isValid = await AuthService.isAccessTokenValid(); // <-- use new service

  runApp(MyPathApp(initialRoute: isValid ? '/welcome' : '/'));
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
        scaffoldBackgroundColor: AppColors.white,
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
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/reset-password': (context) => ResetPasswordScreen(),
      },
    );
  }
}
