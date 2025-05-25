import 'package:flutter/material.dart';
import 'dart:convert';

import '../constants/colors.dart';
import '../constants/constants.dart';
import '../constants/styles.dart';
import '../services/ApiService.dart';
import '../services/StorageService.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();

  bool termsAccepted = false;
  String gender = '-';
  bool isLoading = false;

  String selectedHeight = '0_40';
  String selectedWeight = '0_100';
  String selectedAge = '0_20';

  final List<Map<String, String>> ageOptions = [
    {'label': 'Under 18', 'value': '0_20'},
    {'label': '18 - 40 years', 'value': '20_40'},
    {'label': '40 - 60 years', 'value': '40_60'},
    {'label': '60 - 80 years', 'value': '60_80'},
    {'label': '80+ years', 'value': '100_y'},
  ];

  final List<Map<String, String>> weightOptions = [
    {'label': '0 - 130 lbs', 'value': '0_100'},
    {'label': '130 - 160 lbs', 'value': '120_140'},
    {'label': '160 - 190 lbs', 'value': '140_160'},
    {'label': '190 - 220 lbs', 'value': '160_180'},
    {'label': '220+ lbs', 'value': '200+'},
  ];

  final List<Map<String, String>> heightOptions = [
    {'label': '0 - 40 inches', 'value': '0_40'},
    {'label': '40 - 50 inches', 'value': '40_50'},
    {'label': '50 - 60 inches', 'value': '50_60'},
    {'label': '60 - 70 inches', 'value': '60_70'},
    {'label': '70+ inches', 'value': '70_1000'},
  ];

  Future<void> handleSignup() async {
    if (!_formKey.currentState!.validate() || !termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields and accept the terms.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.signup(
      email: emailController.text.trim(),
      name: nameController.text.trim(),
      password: passwordController.text.trim(),
      height: selectedHeight,
      weight: selectedWeight,
      gender: gender,
      age: selectedAge,
      termsCondition: termsAccepted,
    );

    setState(() => isLoading = false);

    final bool success = result['status'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['detail']),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await StorageService.saveUserInfo(result['user']);
      await StorageService.saveTokens(
        accessToken: result['access_token'],
        refreshToken: result['refresh_token'],
        accessExpires: result['access_token_expires_at'],
        refreshExpires: result['refresh_token_expires_at'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.primary,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.mapPadding),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Create Account', style: AppTextStyles.header),
                ),
              ),
            ),
            Expanded(
              flex: 8,
              child: Container(
                padding: const EdgeInsets.all(AppConstants.mapPadding),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Email is required';
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,63}$');
                            if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
                            return null;
                          },
                          onChanged: (_) {
                            if (_formKey.currentState != null) _formKey.currentState!.validate();
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Full name is required' : null,
                          onChanged: (_) {
                            if (_formKey.currentState != null) _formKey.currentState!.validate();
                          },
                        ),

                        const SizedBox(height: 15),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password is required';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                          onChanged: (_) {
                            if (_formKey.currentState != null) _formKey.currentState!.validate();
                          },
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          value: selectedHeight,
                          decoration: const InputDecoration(
                            labelText: 'Height',
                            prefixIcon: Icon(Icons.height),
                          ),
                          onChanged: (val) {
                            setState(() => selectedHeight = val ?? '0_40');
                            if (_formKey.currentState != null) _formKey.currentState!.validate();
                          },
                          items: heightOptions.map((item) {
                            return DropdownMenuItem(value: item['value'], child: Text(item['label']!));
                          }).toList(),
                          validator: (value) => value == null ? 'Select height' : null,
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          value: selectedWeight,
                          decoration: const InputDecoration(
                            labelText: 'Weight',
                            prefixIcon: Icon(Icons.fitness_center),
                          ),
                          onChanged: (val) {
                            setState(() => selectedWeight = val ?? '0_100');
                            if (_formKey.currentState != null) _formKey.currentState!.validate();
                          },
                          items: weightOptions.map((item) {
                            return DropdownMenuItem(value: item['value'], child: Text(item['label']!));
                          }).toList(),
                          validator: (value) => value == null ? 'Select weight' : null,
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          value: selectedAge,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          onChanged: (val) {
                            setState(() => selectedAge = val ?? '0_20');
                            if (_formKey.currentState != null) _formKey.currentState!.validate();
                          },
                          items: ageOptions.map((item) {
                            return DropdownMenuItem(value: item['value'], child: Text(item['label']!));
                          }).toList(),
                          validator: (value) => value == null ? 'Select age' : null,
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          value: gender,
                          onChanged: (val) {
                            setState(() => gender = val ?? '-');
                            if (_formKey.currentState != null) _formKey.currentState!.validate();
                          },
                          items: ['-', 'Male', 'Female', 'Other']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.wc),
                          ),
                          validator: (value) => value == null || value == '-' ? 'Select gender' : null,
                        ),
                        const SizedBox(height: 15),

                        FormField<bool>(
                          initialValue: termsAccepted,
                          validator: (value) {
                            if (!termsAccepted) return 'You must accept the terms';
                            return null;
                          },
                          builder: (formState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        checkboxTheme: CheckboxThemeData(
                                          fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                            if (states.contains(MaterialState.selected)) {
                                              return AppColors.primary;
                                            }
                                            return Colors.white;
                                          }),
                                          checkColor: MaterialStateProperty.all(Colors.white),
                                        ),
                                      ),
                                      child: Checkbox(
                                        value: termsAccepted,
                                        onChanged: (value) {
                                          setState(() => termsAccepted = value ?? false);
                                          formState.didChange(value);
                                          _formKey.currentState?.validate(); // trigger revalidation
                                        },
                                      ),
                                    ),
                                    const Expanded(child: Text('I accept the terms and conditions')),
                                  ],
                                ),
                                if (formState.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0, top: 4),
                                    child: Text(
                                      formState.errorText ?? '',
                                      style: const TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),


                        const SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: isLoading ? null : handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppConstants.buttonVerticalPadding),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Sign Up', style: AppTextStyles.primaryButton),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}