import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/constants.dart'; // Added because you use animationDuration and padding constants.

class WelcomeScreen extends StatefulWidget {
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration, // ⬅️ Use constant
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // 🔹 Logo Section (60% height)
          Container(
            height: screenHeight * 0.6,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/logo.png',
              width: 280,
              fit: BoxFit.contain,
            ),
          ),

          // 🔹 Animated Bottom Section
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _opacityAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.mapPadding), // ⬅️ Use constant
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MyPath',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We Generate Accessible Routes Together',
                      style: AppTextStyles.subtitle, // ⬅️ Use subtitle instead of label (it's a headline)
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: AppTextStyles.primaryButton,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
