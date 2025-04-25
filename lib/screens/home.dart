import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/constants.dart';
import '../services/api_service.dart';
import '../widgets/summary_chart.dart'; // Chart widget
import '../widgets/turn_by_turn_navigation.dart'; // Chart widget

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  int _selectedIndex = 0;
  bool _isMapReady = false;

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _startDataCollection() async {
    final location = Location();
    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied || permission == PermissionStatus.deniedForever) {
      permission = await location.requestPermission();
    }

    if (permission == PermissionStatus.granted) {
      final loc = await location.getLocation();
      final currentLatLng = LatLng(loc.latitude!, loc.longitude!);

      if (_isMapReady) {
        await Future.delayed(const Duration(milliseconds: 200));
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(currentLatLng, 16),
        );
      }

      location.onLocationChanged.listen((newLoc) {
        print('📍 Updated: Lat: ${newLoc.latitude}, Lng: ${newLoc.longitude}');
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required to start data collection')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Path'),
        centerTitle: false,
        backgroundColor: AppColors.primary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      drawer: _buildDrawer(),

      body: _buildBody(), // 👈 call a method to handle switching tabs

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        backgroundColor: AppColors.white,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Data Summary'),
          BottomNavigationBarItem(icon: Icon(Icons.navigation), label: 'TurnByTurn'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 1) {
      return _buildDataSummary();
    } else if (_selectedIndex == 2) {
      return _buildMap(); // 👈 This shows your turn-by-turn screen
    } else {
      return _buildMap();
    }
  }


  Widget _buildMap() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: AppConstants.homeLatLng,
            zoom: AppConstants.defaultZoom,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            setState(() {
              _isMapReady = true;
            });
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        Positioned(
          bottom: 5,
          left: 0,
          right: 0,
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 7,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _startDataCollection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '"Start" Data Collection',
                    style: AppTextStyles.primaryButton,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataSummary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Data Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.7,
            child: SummaryChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("asmsajib"),
            accountEmail: Text(""),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text("A", style: TextStyle(fontSize: 24.0, color: Colors.green)),
            ),
            decoration: BoxDecoration(color: AppColors.primary),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/home');
            },
          ),
          const Divider(),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Sign Out"),
            onTap: () async {
              Navigator.pop(context);
              await ApiService.clearToken();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}

