import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/constants.dart';
import '../services/ApiService.dart';
import 'NewResetPasswordScreen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({required this.email, super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String otp = '';

  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  bool isResendDisabled = true;
  int countdown = 60;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration,
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
    startCountdown();
  }

  void startCountdown() {
    setState(() {
      isResendDisabled = true;
      countdown = 60;
    });
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (countdown > 1) {
          countdown--;
        } else {
          timer.cancel();
          isResendDisabled = false;
        }
      });
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ApiService.verifyOtp(widget.email, otp);
    final success = result['status'] == true;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['detail']),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewPasswordScreen(email: widget.email, code: otp)),
    );
  }

  Future<void> handleResendCode() async {
    final result = await ApiService.sendPasswordResetCode(widget.email);
    final success = result['status'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['detail']),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      startCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.mapPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Verify OTP', style: AppTextStyles.header),
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => FadeTransition(
                opacity: _opacityAnimation,
                child: SlideTransition(position: _slideAnimation, child: child),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.mapPadding),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enter the 6-digit code sent to ${widget.email}', style: AppTextStyles.label),
                      const SizedBox(height: 20),

                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        onChanged: (value) {
                          otp = value;
                          if (_formKey.currentState != null) {
                            _formKey.currentState!.validate();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'OTP is required';
                          if (value.length != 6) return 'OTP must be 6 digits';
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.fade,
                        enableActiveFill: true,
                        cursorColor: Colors.black,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(8),
                          fieldHeight: 50,
                          fieldWidth: 40,
                          activeFillColor: Colors.grey[200],
                          inactiveFillColor: Colors.grey[100],
                          selectedFillColor: AppColors.primary.withOpacity(0.1),
                          inactiveColor: Colors.grey,
                          selectedColor: AppColors.primary,
                          activeColor: AppColors.primary,
                        ),
                      ),


                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: handleVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.buttonVerticalPadding,
                          ),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Verify Code', style: AppTextStyles.primaryButton),
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: isResendDisabled ? null : handleResendCode,
                          child: Text(
                            isResendDisabled
                                ? 'Resend in ${countdown}s'
                                : 'Resend Code',
                            style: AppTextStyles.label.copyWith(
                              color: isResendDisabled ? Colors.grey : AppColors.primary,
                              decoration: isResendDisabled ? null : TextDecoration.underline,
                            ),
                          ),
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
