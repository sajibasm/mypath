import 'package:flutter/material.dart';
import '../services/APIService.dart';
import '../constants/colors.dart';
import '../utils/CustomLoader.dart';
import 'WheelchairFormScreen.dart';

class WheelChairScreen extends StatefulWidget {
  const WheelChairScreen({super.key});

  @override
  State<WheelChairScreen> createState() => _WheelChairScreenState();
}

class _WheelChairScreenState extends State<WheelChairScreen> {
  List<dynamic> wheelchairs = [];
  bool isLoading = true;
  String? error;
  int? updatingId;


  @override
  void initState() {
    super.initState();
    _loadWheelchairs();
  }

  Future<void> _loadWheelchairs() async {
    try {
      final result = await APIService.getUserWheelchairs();
      setState(() {
        wheelchairs = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _makeDefault(Map wc) async {
    setState(() => updatingId = wc['id']);

    try {
      final data = {
        'identifier': wc['identifier'],
        'wheel_number': wc['wheel_number'],
        'wheelchair_type_id': wc['wheelchair_type']?['id'],
        'wheelchair_drive_type_id': wc['wheelchair_drive_type']?['id'],
        'wheelchair_tire_material_id': wc['wheelchair_tire_material']?['id'],
        'height': wc['height'],
        'width': wc['width'],
        'status': wc['status'],
        'is_default': true,
      };

      await APIService.patchWheelchair(wc['id'], data);
      await _loadWheelchairs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to make default: $e')),
      );
    } finally {
      setState(() => updatingId = null);
    }
  }


  Widget _buildWheelchairCard(Map wc) {
    final isDefault = wc['is_default'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Top Row: Identifier + Default Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wc['identifier'] ?? '-',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text("Default", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )
            ],
          ),
          const SizedBox(height: 12),

          // 🔹 Type, Drive, Material
          Row(children: [
            const Icon(Icons.settings, size: 16, color: Colors.teal),
            const SizedBox(width: 6),
            Text("Type: ${wc['wheelchair_type']?['name'] ?? '-'}"),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.directions, size: 16, color: Colors.indigo),
            const SizedBox(width: 6),
            Text("Drive: ${wc['wheelchair_drive_type']?['name'] ?? '-'}"),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.blur_on, size: 16, color: Colors.brown),
            const SizedBox(width: 6),
            Text("Tire: ${wc['wheelchair_tire_material']?['name'] ?? '-'}"),
          ]),

          const SizedBox(height: 12),

          // 🔹 Height & Width
          Row(children: [
            const Icon(Icons.height, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text("Height: ${wc['height']} inches"),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.straighten, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text("Width: ${wc['width']} inches"),
          ]),

          const SizedBox(height: 12),

          // 🔹 Make Default button
          if (!isDefault)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: updatingId == wc['id'] ? null : () => _makeDefault(wc),
                icon: updatingId == wc['id']
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CustomLoader())
                    : const Icon(Icons.star, color: Colors.white),
                label: Text(
                  updatingId == wc['id'] ? "Updating..." : "Make Default",
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wheelchairs"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CustomLoader())
          : error != null
          ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
          : wheelchairs.isEmpty
          ? RefreshIndicator(
        onRefresh: _loadWheelchairs,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(
              child: Text(
                "No wheelchairs found.\nTap + to add your first wheelchair.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadWheelchairs,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: wheelchairs.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WheelchairFormScreen(wheelchair: wheelchairs[index]),
                  ),
                ).then((_) => _loadWheelchairs());
              },
              child: _buildWheelchairCard(wheelchairs[index]),
            );
          },
        ),
      ),



      // 🔧 FAB goes here inside Scaffold
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white, // 👈 makes the '+' icon white
        tooltip: 'Add Wheelchair',      // shows on long press / hover
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WheelchairFormScreen()),
          ).then((_) => _loadWheelchairs());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

}
