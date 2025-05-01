import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/constants.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration, // Use your constant
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
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // 🔹 20% Top Header
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.mapPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reset Password',
                  style: AppTextStyles.header,
                ),
              ),
            ),
          ),

          // 🔹 80% Animated Form
          Expanded(
            flex: 8,
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
                padding: const EdgeInsets.all(AppConstants.mapPadding),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Your Email Address*',
                        style: AppTextStyles.label, // Use your label style
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'example@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement reset link logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: AppConstants.buttonVerticalPadding),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Send Password Reset Link',
                          style: AppTextStyles.primaryButton,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
