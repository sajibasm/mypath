import 'package:flutter/material.dart';
import '../services/ApiService.dart';
import '../constants/colors.dart';
import '../utils/CustomLoader.dart';
import 'ChangePasswordScreen.dart';
import 'EditProfileScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final result = await ApiService.getProfile();

    if (result['status'] == true) {
      setState(() {
        profile = result['profile'];
        isLoading = false;
      });
    } else if (result['detail'] == 'User profile not found.') {
      setState(() {
        // Provide an empty profile structure to enable editing
        profile = {
          'name': '',
          'email': '',
          'gender': '',
          'age': '',
          'height': '',
          'weight': ''
        };
        isLoading = false;
      });
    } else {
      setState(() {
        error = result['detail'];
        isLoading = false;
      });
    }
  }

  void _navigateToEdit() {
    if (profile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(initialData: profile!),
        ),
      ).then((_) => _loadProfile());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CustomLoader())
          : error != null
          ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
          : RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          children: [
            if ((profile?['name']?.isEmpty ?? true) &&
                (profile?['email']?.isEmpty ?? true))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    "No profile info found. Please update your profile.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            buildProfileCard(profile!, _navigateToEdit),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_reset),
                label: const Text("Change Password"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Profile Card with all fields
  Widget buildProfileCard(Map<String, dynamic> profile, VoidCallback onEdit) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Top Row (Name + Update)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                profile['name']?.toString().isNotEmpty == true
                    ? profile['name']
                    : "No Name",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: const Text(
                  "Update",
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _infoRow(Icons.wc, "Gender", profile['gender'], iconColor: Colors.orange),
          _infoRow(Icons.cake, "Age", profile['age'], iconColor: Colors.pink),
          _infoRow(Icons.height, "Height", profile['height'], iconColor: Colors.green),
          _infoRow(Icons.line_weight, "Weight", profile['weight'], iconColor: Colors.brown),
          _infoRow(Icons.email, "Email", profile['email'], iconColor: Colors.teal),
        ],
      ),
    );
  }

  // 🔹 Row with icon + label + value
  Widget _infoRow(IconData icon, String label, dynamic value,
      {Color iconColor = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : "-",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
