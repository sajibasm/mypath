import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../services/StorageService.dart';
import '../services/ApiService.dart';
import '../widgets/NavigationWidgets.dart';
import '../widgets/DataSummary.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/constants.dart';

import '../services/SensorDataService.dart';
import '../models/SensorData.dart';


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

  final SensorDataService _sensorService = SensorDataService();
  SensorData? _latestSensorData;

  double _totalDistance = 0.0;
  DateTime? _startTime;
  double _latestSpeed = 0.0;

  StreamSubscription<LocationData>? _locationSub;
  Map<String, dynamic>? _selectedWheelchair;

  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

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

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  Future<void> _loadUserInfo() async {
    final user = await StorageService.loadUserInfo();
    setState(() {
      userName = user['name'] ?? 'Guest';
      userEmail = user['email'] ?? '';
    });
  }

  Future<void> _showWheelchairSelectionDialog() async {
    try {
      final wheelchairs = await ApiService.getUserWheelchairs();
      if (!mounted) return;

      String? selectedId = wheelchairs
          .firstWhere((w) => w['is_default'] == true, orElse: () => wheelchairs.first)['id']
          .toString();

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Your Wheelchair'),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedId,
                        items: wheelchairs.map<DropdownMenuItem<String>>((w) {
                          return DropdownMenuItem<String>(
                            value: w['id'].toString(),
                            child: Row(
                              children: [
                                const Icon(Icons.accessible_forward, color: AppColors.primary), // wheelchair icon
                                const SizedBox(width: 8),
                                Text(w['identifier']),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedId = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Wheelchair Identifier',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cancel dialog
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  _selectedWheelchair = wheelchairs.firstWhere(
                        (w) => w['id'].toString() == selectedId,
                  );
                  await StorageService.saveSelectedWheelchair(_selectedWheelchair!);

                  setState(() {
                    _isCollecting = true; // Set collecting true immediately
                  });

                  Navigator.of(context).pop(); // Close dialog
                  _startDataCollection();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCollecting ? Colors.red : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Start Tracking',
                  style: AppTextStyles.primaryButton,
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session expired. Please login again."),
          backgroundColor: Colors.redAccent,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Future<void> _startDataCollection({bool isRetry = false}) async {
    if (_isCollecting) return;

    if (_selectedWheelchair == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wheelchair first.')),
      );
      return;
    }

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

      // ✅ Initial zoom to wheelchair-level location
      if (_isMapReady && _mapController != null) {
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLatLng,
              zoom: 18.5,
            ),
          ),
        );
      }

      double lastZoomLevel = 18.5;

      _locationSub = location.onLocationChanged.listen((newLoc) {
        final point = LatLng(newLoc.latitude!, newLoc.longitude!);
        final speed = newLoc.speed ?? 0;

        _latestSpeed = newLoc.speed ?? 0.0;
        if (_routePoints.isNotEmpty) {
          final last = _routePoints.last;
          final segment = Geolocator.distanceBetween(
            last.latitude, last.longitude,
            point.latitude, point.longitude,
          );
          _totalDistance += segment;
        }

        _routePoints.add(point);

        // ✅ Dynamic zoom logic
        double zoomLevel;
        if (speed < 1.0) {
          zoomLevel = 19.0;
        } else if (speed < 3.0) {
          zoomLevel = 18.5;
        } else {
          zoomLevel = 17.5;
        }

        // ✅ Only zoom if significant change
        if ((zoomLevel - lastZoomLevel).abs() > 0.2) {
          lastZoomLevel = zoomLevel;
          if (_isMapReady && _mapController != null) {
            _mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: point,
                  zoom: zoomLevel,
                ),
              ),
            );
          }
        } else {
          if (_isMapReady && _mapController != null) {
            _mapController.animateCamera(CameraUpdate.newLatLng(point));
          }
        }

        _routePoints.add(point);

        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId("live_route"),
          points: _routePoints,
          color: AppColors.primary,
          width: 5,
        ));

        _markers.removeWhere((m) => m.markerId.value == "current_location");
        _markers.add(Marker(
          markerId: const MarkerId("current_location"),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));

        setState(() {});
      });

      // ✅ Start sensor tracking
      _sensorService.onData = (data) {
        setState(() {
          _latestSensorData = data;
        });
      };
      await _sensorService.start();

      _totalDistance = 0.0;
      _latestSpeed = 0.0;
      _startTime = DateTime.now();

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

    _sensorService.stop();


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

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
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
              markers: _markers,
            ),

            // ✅ Real-time sensor data overlay
            if (_isCollecting && _latestSensorData != null)
              Positioned(
                top: 10,
                right: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🕒 Time: ${_latestSensorData!.timestamp.toIso8601String()}"),
                      const SizedBox(height: 4),

                      Text("📌 GPS: "
                          "Lat: ${_latestSensorData!.latitude.toStringAsFixed(5)}, "
                          "Lng: ${_latestSensorData!.longitude.toStringAsFixed(5)}"),

                      Text("💨 Speed: ${_latestSpeed.toStringAsFixed(2)} m/s"),
                      Text("📏 Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km"),
                      Text("⏱️ Duration: ${_startTime != null ? _formatDuration(DateTime.now().difference(_startTime!)) : '--:--'}"),

                      const Divider(height: 16),

                      Text("🎯 Accelerometer:\n"
                          "X=${_latestSensorData!.accX.toStringAsFixed(2)}, "
                          "Y=${_latestSensorData!.accY.toStringAsFixed(2)}, "
                          "Z=${_latestSensorData!.accZ.toStringAsFixed(2)}"),

                      Text("🎯 Gyroscope:\n"
                          "X=${_latestSensorData!.gyroX.toStringAsFixed(2)}, "
                          "Y=${_latestSensorData!.gyroY.toStringAsFixed(2)}, "
                          "Z=${_latestSensorData!.gyroZ.toStringAsFixed(2)}"),

                      Text("🎯 Magnetometer:\n"
                          "X=${_latestSensorData!.magX.toStringAsFixed(2)}, "
                          "Y=${_latestSensorData!.magY.toStringAsFixed(2)}, "
                          "Z=${_latestSensorData!.magZ.toStringAsFixed(2)}"),
                    ],
                  ),
                ),
              ),

            // ✅ Button: Start/Stop Collection
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
                          _showWheelchairSelectionDialog();
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
            ),
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
            UserAccountsDrawerHeader(
              accountName: Text(userName ?? ''),
              accountEmail: null,
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(userName),
                  style: const TextStyle(fontSize: 24.0, color: Colors.green),
                ),
              ),
              decoration: const BoxDecoration(color: AppColors.primary),
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
              leading: const Icon(Icons.accessible_forward),
              title: const Text("WheelChair"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/wheelchair');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
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
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sign Out"),
              onTap: () async {
                Navigator.pop(context);
                await StorageService.clearAll();
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
          BottomNavigationBarItem(icon: Icon(Icons.navigation), label: 'Navigation'),
        ],
      ),
    );
  }
}
