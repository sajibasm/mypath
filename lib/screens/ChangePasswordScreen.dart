import 'package:MyPath/constants/colors.dart';
import 'package:flutter/material.dart';
import '../services/APIService.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await APIService.changePassword(
        currentPassword: currentController.text.trim(),
        newPassword: newController.text.trim(),
      );

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['detail'] ?? "Password change failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 12),
              TextFormField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Current Password"),
                validator: (val) =>
                val == null || val.trim().isEmpty ? 'Current password is required' : null,
                onChanged: (_) => _formKey.currentState?.validate(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'New password is required';
                  }
                  if (val.length < 6) {
                    return 'New password must be at least 6 characters';
                  }
                  return null;
                },
                onChanged: (_) => _formKey.currentState?.validate(),
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm New Password"),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (val != newController.text.trim()) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onChanged: (_) => _formKey.currentState?.validate(),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
