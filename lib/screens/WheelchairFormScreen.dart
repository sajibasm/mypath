import 'package:flutter/material.dart';
import '../services/APIService.dart';
import '../constants/colors.dart';
import '../utils/CustomLoader.dart';

class WheelchairFormScreen extends StatefulWidget {
  final Map<String, dynamic>? wheelchair;

  const WheelchairFormScreen({super.key, this.wheelchair});

  @override
  State<WheelchairFormScreen> createState() => _WheelchairFormScreenState();
}

class _WheelchairFormScreenState extends State<WheelchairFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController identifierController;
  late TextEditingController heightController;
  late TextEditingController widthController;
  late int wheelNumber;
  late bool isDefault;

  int? selectedTypeId;
  int? selectedDriveTypeId;
  int? selectedTireMaterialId;

  List<Map<String, dynamic>> typeOptions = [];
  List<Map<String, dynamic>> driveOptions = [];
  List<Map<String, dynamic>> tireOptions = [];

  bool isLoading = false;
  bool isDropdownLoading = true;

  @override
  void initState() {
    super.initState();
    identifierController = TextEditingController(text: widget.wheelchair?['identifier'] ?? '');
    heightController = TextEditingController(text: widget.wheelchair?['height'] ?? '');
    widthController = TextEditingController(text: widget.wheelchair?['width'] ?? '');
    wheelNumber = widget.wheelchair?['wheel_number'] ?? 2;
    isDefault = widget.wheelchair?['is_default'] ?? false;

    selectedTypeId = widget.wheelchair?['wheelchair_type']?['id'];
    selectedDriveTypeId = widget.wheelchair?['wheelchair_drive_type']?['id'];
    selectedTireMaterialId = widget.wheelchair?['wheelchair_tire_material']?['id'];

    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final types = await APIService.getWheelchairTypes();
      final drives = await APIService.getDriveTypes();
      final tires = await APIService.getTireMaterials();

      setState(() {
        typeOptions = List<Map<String, dynamic>>.from(types);
        driveOptions = List<Map<String, dynamic>>.from(drives);
        tireOptions = List<Map<String, dynamic>>.from(tires);
        isDropdownLoading = false;
      });
    } catch (e) {
      setState(() => isDropdownLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load dropdown data: $e")));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'identifier': identifierController.text,
      'wheel_number': wheelNumber,
      'wheelchair_type_id': selectedTypeId,
      'wheelchair_drive_type_id': selectedDriveTypeId,
      'wheelchair_tire_material_id': selectedTireMaterialId,
      'height': heightController.text,
      'width': widthController.text,
      'status': 'active',
      'is_default': isDefault,
    };

    setState(() => isLoading = true);

    try {
      if (widget.wheelchair == null) {
        await APIService.createWheelchair(data);
      } else {
        await APIService.updateWheelchair(widget.wheelchair!['id'], data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.wheelchair == null
                ? 'Wheelchair created successfully'
                : 'Wheelchair updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.wheelchair != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Wheelchair' : 'Add Wheelchair'),
        backgroundColor: AppColors.primary,
      ),
      body: isDropdownLoading
          ? const Center(child: CustomLoader())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: identifierController,
                decoration: const InputDecoration(labelText: 'Identifier'),
                validator: (val) => val == null || val.isEmpty ? 'Identifier is required' : null,
                onChanged: (_) => _formKey.currentState?.validate(),
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: wheelNumber,
                decoration: const InputDecoration(labelText: 'Number of Wheels'),
                items: [2, 3, 4, 5, 6]
                    .map((val) => DropdownMenuItem(value: val, child: Text('$val Wheels')))
                    .toList(),
                onChanged: (val) {
                  setState(() => wheelNumber = val ?? 2);
                  _formKey.currentState?.validate();
                },
                validator: (val) => val == null ? 'Select number of wheels' : null,
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedTypeId,
                decoration: const InputDecoration(labelText: 'Wheelchair Type'),
                onChanged: (val) {
                  setState(() => selectedTypeId = val);
                  _formKey.currentState?.validate();
                },
                items: typeOptions.map((type) {
                  return DropdownMenuItem<int>(
                    value: type['id'],
                    child: Text(type['name']),
                  );
                }).toList(),
                validator: (val) => val == null ? 'Please select a wheelchair type' : null,
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDriveTypeId,
                decoration: const InputDecoration(labelText: 'Drive Type'),
                onChanged: (val) {
                  setState(() => selectedDriveTypeId = val);
                  _formKey.currentState?.validate();
                },
                items: driveOptions.map((item) {
                  return DropdownMenuItem<int>(
                    value: item['id'],
                    child: Text(item['name']),
                  );
                }).toList(),
                validator: (val) => val == null ? 'Please select drive type' : null,
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedTireMaterialId,
                decoration: const InputDecoration(labelText: 'Tire Material'),
                onChanged: (val) {
                  setState(() => selectedTireMaterialId = val);
                  _formKey.currentState?.validate();
                },
                items: tireOptions.map((item) {
                  return DropdownMenuItem<int>(
                    value: item['id'],
                    child: Text(item['name']),
                  );
                }).toList(),
                validator: (val) => val == null ? 'Please select tire material' : null,
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (inches)',
                  counterText: '', // hides character counter
                ),
                keyboardType: TextInputType.number,
                maxLength: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter height';
                  if (val.length > 3) return 'Max 3 digits allowed';
                  final num? h = num.tryParse(val);
                  if (h == null || h <= 0) return 'Enter valid height';
                  return null;
                },
                onChanged: (_) => _formKey.currentState?.validate(),
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: widthController,
                decoration: const InputDecoration(
                  labelText: 'Width (inches)',
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter width';
                  if (val.length > 3) return 'Max 3 digits allowed';
                  final num? w = num.tryParse(val);
                  if (w == null || w <= 0) return 'Enter valid width';
                  return null;
                },
                onChanged: (_) => _formKey.currentState?.validate(),
              ),

              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is Default'),
                activeColor: Colors.green,
                value: isDefault,
                onChanged: (val) => setState(() => isDefault = val),
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
                    ? const CustomLoader()
                    : Text(
                  isEdit ? 'Update Wheelchair' : 'Create Wheelchair',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
