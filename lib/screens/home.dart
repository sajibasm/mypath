import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../widgets/turn_by_turn_map.dart';
import '../widgets/data-summary.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/constants.dart';
import '../services/api_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  int _selectedIndex = 0;
  bool _isMapReady = false;
  bool _isCollecting = false;

  final List<LatLng> _routePoints = [];
  final Set<Polyline> _polylines = {};
  Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId("current_location"),
      position: LatLng(0.0, 0.0),
    ),
  };

  StreamSubscription<LocationData>? _locationSub;

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_selectedIndex == 0 && index != 0 && _isCollecting) {
      _stopDataCollection();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _startDataCollection({bool isRetry = false}) async {
    if (_isCollecting) return;

    final location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied || permission == PermissionStatus.deniedForever) {
      permission = await location.requestPermission();
    }

    if (permission == PermissionStatus.granted) {
      await Future.delayed(const Duration(milliseconds: 500));

      final loc = await location.getLocation();
      final currentLatLng = LatLng(loc.latitude!, loc.longitude!);

      if (_isMapReady) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(currentLatLng, AppConstants.defaultZoom),
        );
      }

      _locationSub = location.onLocationChanged.listen((newLoc) {
        final point = LatLng(newLoc.latitude!, newLoc.longitude!);

        _routePoints.add(point);

        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId("live_route"),
          points: _routePoints,
          color: AppColors.primary, // Use your primary color instead of hard blue
          width: 5,
        ));

        _markers.removeWhere((m) => m.markerId.value == "current_location");
        _markers.add(Marker(
          markerId: const MarkerId("current_location"),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));

        if (_isMapReady) {
          _mapController.animateCamera(CameraUpdate.newLatLng(point));
        }

        setState(() {});
      });

      setState(() {
        _isCollecting = true;
      });

    } else {
      if (!isRetry) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waiting for location permission...')),
        );
      }
      Future.delayed(const Duration(seconds: 2), () {
        _startDataCollection(isRetry: true);
      });
    }
  }

  void _stopDataCollection() {
    _locationSub?.cancel();
    _locationSub = null;

    setState(() {
      _isCollecting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.pause_circle_filled, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Tracking has been stopped'),
          ],
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(AppConstants.mapPadding),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: AppConstants.homeLatLng,
                zoom: AppConstants.defaultZoomHome,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                setState(() {
                  _isMapReady = true;
                });
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              polylines: _polylines,
              //markers: _markers,
            ),
            Positioned(
              bottom: 5,
              left: 0,
              right: 0,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.mapPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 7,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isCollecting) {
                          _stopDataCollection();
                        } else {
                          _startDataCollection();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCollecting ? Colors.red : AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isCollecting ? 'Stop Data Collection' : 'Start Data Collection',
                        style: AppTextStyles.primaryButton,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      case 1:
        return const DataSummaryWidget();
      case 2:
        return TurnByTurnMapWidget();
      default:
        return const Center(child: Text("Invalid tab"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyPath'),
        backgroundColor: AppColors.primary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
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
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Data Summary'),
          BottomNavigationBarItem(icon: Icon(Icons.navigation), label: 'TurnByTurn'),
        ],
      ),
    );
  }
}
