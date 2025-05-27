import 'package:flutter/material.dart';
import '../services/APIService.dart';
import '../constants/colors.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfileScreen({super.key, required this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;

  String? selectedHeight;
  String? selectedWeight;
  String? selectedAge;
  String? gender;
  bool isSubmitting = false;
  String? error;

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

  @override
  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.initialData['name'] ?? '');
    selectedHeight = widget.initialData['height'];
    selectedWeight = widget.initialData['weight'];
    selectedAge = widget.initialData['age'];

    // Normalize gender (make it exactly match dropdown item)
    String? rawGender = widget.initialData['gender']?.toString().toLowerCase();
    if (rawGender == 'male') {
      gender = 'Male';
    } else if (rawGender == 'female') {
      gender = 'Female';
    } else if (rawGender == 'other') {
      gender = 'Other';
    } else {
      gender = '-';
    }

    // Fallback if height/weight/age is null or not in list
    final heightValues = heightOptions.map((e) => e['value']).toList();
    final weightValues = weightOptions.map((e) => e['value']).toList();
    final ageValues = ageOptions.map((e) => e['value']).toList();

    if (!heightValues.contains(selectedHeight)) {
      selectedHeight = heightValues.first;
    }
    if (!weightValues.contains(selectedWeight)) {
      selectedWeight = weightValues.first;
    }
    if (!ageValues.contains(selectedAge)) {
      selectedAge = ageValues.first;
    }
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
      error = null;
    });

    final result = await APIService.updateProfile(
      name: nameController.text.trim(),
      height: selectedHeight ?? '',
      weight: selectedWeight ?? '',
      gender: gender ?? '',
      age: selectedAge ?? '',
    );

    setState(() {
      isSubmitting = false;
    });

    if (result['status']) {
      Navigator.pop(context);
    } else {
      setState(() => error = result['detail'] ?? 'Failed to update profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                  onChanged: (_) => _formKey.currentState?.validate(),
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: selectedHeight,
                  decoration: const InputDecoration(labelText: 'Height'),
                  onChanged: (val) {
                    setState(() => selectedHeight = val);
                    _formKey.currentState?.validate();
                  },
                  items: heightOptions.map((item) {
                    return DropdownMenuItem(
                      value: item['value'],
                      child: Text(item['label']!),
                    );
                  }).toList(),
                  validator: (value) => value == null || value.isEmpty ? 'Select height' : null,
                ),


                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: selectedWeight,
                  decoration: const InputDecoration(labelText: 'Weight'),
                  onChanged: (val) {
                    setState(() => selectedWeight = val);
                    _formKey.currentState?.validate();
                  },
                  items: weightOptions.map((item) {
                    return DropdownMenuItem(
                      value: item['value'],
                      child: Text(item['label']!),
                    );
                  }).toList(),
                  validator: (value) => value == null || value.isEmpty ? 'Select weight' : null,
                ),


                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: selectedAge,
                  decoration: const InputDecoration(labelText: 'Age'),
                  onChanged: (val) {
                    setState(() => selectedAge = val);
                    _formKey.currentState?.validate();
                  },
                  items: ageOptions.map((item) {
                    return DropdownMenuItem(
                      value: item['value'],
                      child: Text(item['label']!),
                    );
                  }).toList(),
                  validator: (value) => value == null || value.isEmpty ? 'Select age' : null,
                ),


                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: gender,
                  onChanged: (val) {
                    setState(() => gender = val);
                    _formKey.currentState?.validate();
                  },
                  items: ['-', 'Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Gender'),
                  validator: (value) => value == null || value.isEmpty ? 'Select gender' : null,
                ),


                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity, // 🔁 full-width
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text("Update", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
