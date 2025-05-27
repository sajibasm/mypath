import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import '../constants/constants.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/secrets.dart';
import '../services/APIService.dart';

class _ReportItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _ReportItem({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.lightGrey,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.asset(
                imagePath,
                height: 32,
                width: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.formHint,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class NavigationMapWidget extends StatefulWidget {
  const NavigationMapWidget({super.key});

  @override
  State<NavigationMapWidget> createState() => _NavigationMapWidgetState();
}

class _NavigationMapWidgetState extends State<NavigationMapWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _etaAnimationController;
  late Animation<Offset> _etaSlideAnimation;
  late Animation<double> _etaFadeAnimation;

  GoogleMapController? _mapController;

  late BitmapDescriptor _wheelchairIcon;
  String? _selectedPlaceDescription; // 🆕 To store selected place description
  bool _showPreviewCard = false; // 🆕 Control visibility
  double _currentZoom = AppConstants.defaultZoom;

  Set<Polyline> _polylines = {};
  List<dynamic> _placePredictions = [];
  Set<Marker> _markers = {};

  late AnimationController _stepAnimationController;
  late Animation<double> _stepFadeAnimation;
  late Animation<Offset> _stepSlideAnimation;

  // for the real time turn by turn navigation
  int _currentSegmentIndex = 0; // 🔥 Track which segment
  List<Map<String, dynamic>> _segments = []; // 🔥 Route Segments
  List<String> _searchHistory = []; // 🔥
  final String _searchHistoryKey = 'search_history'; // 🔥 Key for SharedPreferences


  bool _isNavigating = false; // 🔥 Start Navigation Mode

  StreamSubscription<Position>? _positionStream; // 🔥 Live tracking

  bool _showLegend = false; // ✅ Legend visibility
  bool _expandLegend = false; // ✅ Legend expand/collapse state

  final FocusNode _searchFocusNode = FocusNode(); // 🔥 Add this
  bool _isSearchFocused = false; // 🔥 Add this

  bool _showRecentSearches = false;
  String? _transitId;

  double _totalDistance = 0.0; // In meters
  double _totalDuration = 0.0; // In seconds

  //  Add this line!
  Position? _currentLocation;

  CameraPosition? _previousCameraPosition; // 🔥 Add this to your state

  Set<Marker> _reportedMarkers = {}; // ✅ New markers for barriers/facilities

  final List<Map<String, String>> _barriers = [
    {'label': 'Stairs', 'icon': 'assets/maps/stairs.png'},
    {'label': 'Steep Slope', 'icon': 'assets/maps/steep-slope.png'},
    {'label': 'Snow Pile', 'icon': 'assets/maps/snow-pile.png'},
    {'label': 'Construction', 'icon': 'assets/maps/construction.png'},
    {'label': 'Tree', 'icon': 'assets/maps/tree.png'},
    {'label': 'Broken Sidewalk', 'icon': 'assets/maps/broken-sidewalk.png'}, // ✅ Capital W
    {'label': 'No Curb Ramp', 'icon': 'assets/maps/no-curb-ramp.png'},
    {'label': 'Others', 'icon': 'assets/maps/others.png'},
  ];

  final List<Map<String, String>> _facilities = [
    {'label': 'Elevator', 'icon': 'assets/maps/elevator.png'},
    {'label': 'Curb Ramp', 'icon': 'assets/maps/curb-ramp.png'},
    {'label': 'Crosswalk', 'icon': 'assets/maps/crosswalk.png'},
    {'label': 'SideWalk', 'icon': 'assets/maps/sidewalk.png'}, // ✅ Capital W
    {'label': 'Others', 'icon': 'assets/maps/others.png'},
  ];

  bool _hideSearchBar = false;
  bool _showFloatingButton = false;

  double _currentBearing = 0.0; // 🔥 Track the last bearing value

  Icon _getInstructionIcon(String instruction) {
    final lowerInstruction = instruction.toLowerCase(); // 🔥 Make lowercase to avoid case issues

    if (lowerInstruction.contains('left')) {
      return const Icon(Icons.turn_left, color: AppColors.primary, size: 28);
    } else if (lowerInstruction.contains('right')) {
      return const Icon(Icons.turn_right, color: AppColors.primary, size: 28);
    } else if (lowerInstruction.contains('straight') || lowerInstruction.contains('continue')) {
      return const Icon(Icons.straight, color: AppColors.primary, size: 28);
    } else if (lowerInstruction.contains('destination')) {
      return const Icon(Icons.flag, color: AppColors.primary, size: 28);
    } else {
      return const Icon(Icons.navigation, color: AppColors.primary, size: 28);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose(); // 🔥 Dispose focus node
    _mapController?.dispose(); // ✅
    _searchController.dispose();
    _positionStream?.cancel();
    _stepAnimationController.dispose(); // 🔥
    _etaAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initialize();
    _loadSearchHistory(); // 🔥 Load saved history at startup

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;

        // 🔥 Only show Recent Searches when search bar is focused
        if (_isSearchFocused) {
          _showRecentSearches = true;
        }
      });
    });

    // 🔥 Fix: Delay unfocus after build
    Future.delayed(Duration(milliseconds: 100), () {
      FocusScope.of(context).unfocus();
    });

    _stepAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _stepFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _stepAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _stepSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _stepAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _etaAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _etaFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _etaAnimationController, curve: Curves.easeInOut),
    );

    _etaSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from below screen
      end: Offset.zero, // End at its normal position
    ).animate(
      CurvedAnimation(parent: _etaAnimationController, curve: Curves.easeInOut),
    );

  }

  Future<void> _initialize() async {
    await _loadCustomMarker();
  }

  double _smoothHeading(
    double oldHeading,
    double newHeading, [
    double factor = 0.2,
  ]) {
    // Normalize both headings
    double difference = (newHeading - oldHeading + 360) % 360;
    if (difference > 180) {
      difference -= 360;
    }
    return (oldHeading + difference * factor) % 360;
  }

  void _addToSearchHistory(String search) async {
    setState(() {
      // Remove if already exists
      _searchHistory.remove(search);

      // Insert at top
      _searchHistory.insert(0, search);

      // Keep only last 3
      if (_searchHistory.length > 3) {
        _searchHistory = _searchHistory.sublist(0, 3);
      }
    });

    print('🔥 Updated Search History: $_searchHistory'); // <<< Add this!

    // 🔥 Save updated history to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_searchHistoryKey, _searchHistory);
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final storedHistory = prefs.getStringList(_searchHistoryKey);

    if (storedHistory != null && storedHistory.isNotEmpty) {
      setState(() {
        _searchHistory = storedHistory;
      });
    }
  }



  void _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);

    setState(() {
      _searchHistory.clear();
    });
  }

  Future<void> _loadReportedMarkers() async {
    if (_segments.isEmpty) return;
    if (_currentSegmentIndex >= _segments.length) return;

    try {
      final firstSegment = _segments.first;

      final markers = await APIService.searchMarkers(
        marker_lat: firstSegment['start_location']['latitude'],
        marker_lng: firstSegment['start_location']['longitude'],
      );

      print('markers: $markers');

      if (markers.isNotEmpty) {
        Set<Marker> newMarkers = {};

        for (var marker in markers) {
          final markerType = marker['marker_type'] ?? '';
          final markerCategory = marker['marker_category'] ?? '';
          final lat = marker['latitude'];
          final lng = marker['longitude'];

          // 🛑 Null check
          if (lat == null || lng == null) {
            print('⚠️ Skipping marker with missing coordinates: $marker');
            continue;
          }

          final icon = await _getCustomMarkerIconFromIcon(
            iconData: markerCategory == 'Facility'
                ? Icons.check_circle
                : Icons.report_problem,
            color: markerCategory == 'Facility' ? Colors.green : Colors.red,
            size: _getIconSizeForZoom(_currentZoom),
          );


          newMarkers.add(
            Marker(
              markerId: MarkerId('reported_${lat}_${lng}'),
              position: LatLng(lat as double, lng as double), // 🛡️ cast after null check
              icon: icon,
              infoWindow: InfoWindow(
                title: markerType,
                snippet: marker['marker_category'] ?? '',
              ),
            ),
          );
        }

        setState(() {
          _reportedMarkers = newMarkers;
        });

        print('📍 Loaded ${newMarkers.length} reported markers');
      }
    } catch (e) {
      print('❌ Failed to load reported markers: $e');
    }
  }


  void _recenterMap() async {
    final position = await Geolocator.getCurrentPosition();
    await _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  void _handleReport(String type, String name) async {
    Navigator.pop(context); // Close the modal

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available.')),
      );
      return;
    }

    if (_transitId == null || _segments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active transit found.')),
      );
      return;
    }

    try {
      final currentSegment = _segments[_currentSegmentIndex];

      // 🔥 Fix marker_category: must be 'Barrier' or 'Facility' (capitalized)
      String markerCategory = type.toLowerCase() == 'barrier'
          ? 'Barrier'
          : 'Facility';

      await APIService.createTransitMarker(
        transitId: _transitId!,
        segmentNumber: currentSegment['segment_number'] ?? _currentSegmentIndex,
        markerCategory: markerCategory,
        markerType: name, // name is already correct ("SideWalk", "Stairs", etc.)
        markerLat: _currentLocation!.latitude,
        markerLng: _currentLocation!.longitude,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$markerCategory reported: $name')),
      );
      print('📌 Reported $markerCategory: $name at current location');
    } catch (e) {
      print('❌ Failed to report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to report')),
      );
    }
  }

  Future<BitmapDescriptor> _getCustomMarkerIconFromIcon({
    required IconData iconData,
    Color color = Colors.red,
    double size = 64,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(
      textPainter.width.ceil(),
      textPainter.height.ceil(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }


  Future<BitmapDescriptor> _getCustomMarkerIcon({
    required String markerType,
    required double iconSize,
  }) async {
    try {
      String cleanedType = markerType.toLowerCase()
          .replaceAll(' ', '-')
          .replaceAll('_', '-');

      String assetPath = 'assets/maps/$cleanedType.png';

      print('🔍 Loading asset: $assetPath');

      return await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(iconSize, iconSize)),
        assetPath,
      );
    } catch (e) {
      print('⚠️ Failed to load icon for $markerType: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }


  double _getIconSizeForZoom(double zoom) {
    if (zoom >= 18) {
      return 64; // Very close (walking) view 🔥
    } else if (zoom >= 16) {
      return 48; // Normal campus/street view
    } else if (zoom >= 14) {
      return 36; // Wider view
    } else {
      return 24; // Very zoomed-out (small icons)
    }
  }



  void _showReportModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.mapPadding,
            vertical: 40,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(AppConstants.mapPadding),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Barriers", style: AppTextStyles.subtitle),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children:
                          _barriers.map((item) {
                            return _ReportItem(
                              imagePath: item['icon']!,
                              label: item['label']!,
                              onTap:
                                  () =>
                                      _handleReport('barrier', item['label']!),
                            );
                          }).toList(),
                    ),
                    const Divider(),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children:
                          _facilities.map((item) {
                            return _ReportItem(
                              imagePath: item['icon']!,
                              label: item['label']!,
                              onTap:
                                  () =>
                                      _handleReport('facility', item['label']!),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleCameraMove(double zoom) {
    if ((zoom - _currentZoom).abs() >= 1) {
      // Only if zoom changed significantly
      _currentZoom = zoom;

      if (zoom >= 17) {
        _reloadWheelchairIcon(size: 64); // Zoomed-in view = bigger icon
      } else if (zoom >= 14) {
        _reloadWheelchairIcon(size: 48); // Medium zoom = medium icon
      } else {
        _reloadWheelchairIcon(size: 32); // Far zoom = small icon
      }
    }
  }

  void _triggerStepAnimation() {
    _stepAnimationController.forward(from: 0.0);
  }

  double _dynamicZoom(double speed) {
    if (speed <= 2) {
      return 19.5; // Walking, very zoomed in
    } else if (speed <= 8) {
      return 18.0; // Bicycle, medium zoom
    } else if (speed <= 20) {
      return 16.5; // City driving
    } else {
      return 15.5; // Highway, wide view
    }
  }

  Future<void> _moveSmoothly(
    LatLng newLatLng,
    double newBearing, {
    double speed = 0,
  }) async {
    if (_previousCameraPosition == null) {
      _previousCameraPosition = CameraPosition(
        target: newLatLng,
        zoom: _dynamicZoom(speed),
        tilt: 60,
        bearing: newBearing,
      );
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(_previousCameraPosition!),
      );
      return;
    }

    final oldTarget = _previousCameraPosition!.target;
    final oldBearing = _previousCameraPosition!.bearing;
    final oldZoom = _previousCameraPosition!.zoom;

    // 🔥 Dynamic steps based on speed
    int steps;
    if (speed <= 2) {
      steps = 10;
    } else if (speed <= 8) {
      steps = 6;
    } else {
      steps = 3;
    }

    double newZoom = _dynamicZoom(speed); // 🎯 Get target zoom

    for (int i = 1; i <= steps; i++) {
      final double lat =
          oldTarget.latitude +
          (newLatLng.latitude - oldTarget.latitude) * (i / steps);
      final double lng =
          oldTarget.longitude +
          (newLatLng.longitude - oldTarget.longitude) * (i / steps);
      final double bearing =
          oldBearing + (newBearing - oldBearing) * (i / steps);
      final double zoom =
          oldZoom + (newZoom - oldZoom) * (i / steps); // 🔥 Smooth zoom

      final intermediateCameraPosition = CameraPosition(
        target: LatLng(lat, lng),
        zoom: zoom,
        tilt: 60,
        bearing: bearing,
      );

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(intermediateCameraPosition),
      );

      await Future.delayed(
        Duration(
          milliseconds:
              (speed <= 2)
                  ? 40
                  : (speed <= 8)
                  ? 25
                  : 15,
        ),
      );
    }

    _previousCameraPosition = CameraPosition(
      target: newLatLng,
      zoom: newZoom,
      tilt: 60,
      bearing: newBearing,
    );
  }

  void _startLiveLocationTracking() {
    _positionStream?.cancel();

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      if (_currentLocation == null ||
          Geolocator.distanceBetween(
                _currentLocation!.latitude,
                _currentLocation!.longitude,
                position.latitude,
                position.longitude,
              ) >
              1) {
        _currentLocation = position;
        final currentLatLng = LatLng(position.latitude, position.longitude);

        if (_isNavigating) {
          double rawHeading = position.heading;
          if (rawHeading.isNaN) rawHeading = 0;

          _currentBearing = _smoothHeading(_currentBearing, rawHeading);

          await _moveSmoothly(
            currentLatLng,
            _currentBearing,
            speed: position.speed,
          );
        } else {
          await _mapController?.animateCamera(
            CameraUpdate.newLatLng(currentLatLng),
          );
        }

        if (_isNavigating && _segments.isNotEmpty) {
          _checkIfReachedNextStep(currentLatLng);
        }
      }
    });
  }

  void _cancelRoute() async {
    // ✅ Step 1: Animate hiding the bottom card
    await _etaAnimationController.reverse();

    // ✅ Step 2: Cancel the active transit on server
    if (_transitId != null) {
      try {
        await APIService.cancelTransit(
          transitId: _transitId!,
          distance: _totalDistance,
          duration: _totalDuration,
        );
        print('🚫 Transit canceled successfully');
      } catch (e) {
        print('❌ Failed to cancel transit: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel transit')),
        );
      }
    } else {
      print('⚠️ No transit_id found while trying to cancel transit');
    }

    // ✅ Step 3: Reset local UI state
    setState(() {
      _segments.clear();
      _polylines.clear();
      _markers.clear();
      _reportedMarkers.clear(); // ✅ CLEAR reported markers here
      _isNavigating = false;
      _currentSegmentIndex = 0;
      _hideSearchBar = false;
      _showFloatingButton = false;
      _currentBearing = 0;
      _showLegend = false;
      _expandLegend = false;
      _transitId = null; // 🔥 Reset transit ID after cancel
    });

    // ✅ Step 4: Recenter map
    if (_currentLocation != null) {
      final currentLatLng = LatLng(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLatLng,
            zoom: AppConstants.defaultZoom,
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    }
  }


  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error('Location permissions are denied.');
      }
    }

    final position = await Geolocator.getCurrentPosition();

    // 🔥 Update _currentLocation here!
    _currentLocation = position;

    await _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  Future<void> _loadCustomMarker() async {
    _wheelchairIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(32, 32)), // 🔥 smaller
      'assets/maps/wheelchair_marker.png',
    );
  }

  Future<void> _reloadWheelchairIcon({required double size}) async {
    final newIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(size, size)),
      'assets/maps/wheelchair_marker.png',
    );

    setState(() {
      _wheelchairIcon = newIcon;

      // Rebuild markers with new icon
      if (_markers.isNotEmpty) {
        final currentMarker = _markers.first;

        _markers.clear();
        _markers.add(
          Marker(
            markerId: currentMarker.markerId,
            position: currentMarker.position,
            icon: _wheelchairIcon,
            infoWindow: currentMarker.infoWindow,
          ),
        );
      }
    });
  }

  Future<void> _checkIfReachedNextStep(LatLng currentPos) async {
    if (_currentSegmentIndex >= _segments.length) {
      _isNavigating = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have reached your destination!')),
      );

      // ✅ Step 1: Complete Transit when arriving at destination
      if (_transitId != null) {
        try {
          // You can pass the overall distance and duration if you saved them
          // For now let's assume simple values
          await APIService.completeTransit(
            transitId: _transitId!,
            distance: _totalDistance,
            duration: _totalDuration,
          );
          print('🏁 Transit completed successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transit completed!')),
          );
        } catch (e) {
          print('❌ Failed to complete transit: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to complete transit')),
          );
        }
      } else {
        print('⚠️ No transit_id to complete.');
      }

      return;
    }


    final segment = _segments[_currentSegmentIndex];
    final endLocation = segment['end_location'];

    final distance = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      endLocation['latitude'],
      endLocation['longitude'],
    );

    // 🎯 Dynamic threshold based on walking or faster
    double threshold = 12; // Walking default
    if (_currentLocation != null && _currentLocation!.speed > 2) {
      threshold = 20; // Faster movement (bicycle, wheelchair fast push)
    }

    if (distance < threshold) {
      setState(() {
        // 🔥 Remove completed segment polyline
        _polylines.removeWhere((polyline) => polyline.polylineId.value == 'segment_${_currentSegmentIndex - 1}');
        _currentSegmentIndex++;
      });

      _triggerStepAnimation(); // 🔥 Smoothly update instruction card

      // 🧠 Debugging print
      if (_currentSegmentIndex < _segments.length) {
        final currentInstruction = _segments[_currentSegmentIndex]['instruction'] ?? 'No instruction';
        print('🧭 Now showing Step $_currentSegmentIndex: $currentInstruction');

        if (_currentSegmentIndex + 1 < _segments.length) {
          final nextInstruction = _segments[_currentSegmentIndex + 1]['instruction'] ?? 'No next step';
          print('➡️ Next Step: $nextInstruction');
        } else {
          print('🎯 Final step reached, no next instruction.');
        }
      } else {
        print('✅ Navigation Completed!');
      }
    }
  }

  Future<void> _findPlace(String inputText) async {
    if (inputText.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$inputText&key=${Secrets.GoogleMapsAPI}&components=country:us';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      if (decodedResponse['status'] == 'OK') {
        final predictions = decodedResponse['predictions'];
        setState(() {
          _placePredictions = predictions;
        });
      } else {
        print(
          'Google Places API Error: ${decodedResponse['status']} - ${decodedResponse['error_message']}',
        );
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
    }
  }

  Future<void> _moveToPlace(String placeId) async {

    // 🔥 Finally unfocus search bar to hide suggestions
    FocusScope.of(context).unfocus();

    setState(() {
      _placePredictions.clear(); // 🔥 Clear suggestions
    });

    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${Secrets.GoogleMapsAPI}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final location =
          jsonDecode(response.body)['result']['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];

      final newPosition = LatLng(lat, lng);

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 16),
        );
      }

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_place'),
            position: newPosition,
            icon: _wheelchairIcon,
            infoWindow: const InfoWindow(title: 'Selected Accessible Location'),
          ),
        );

        _placePredictions.clear();
        _searchController.clear();

        _selectedPlaceDescription =
            jsonDecode(response.body)['result']['name'] ?? "Selected Location";
        _showPreviewCard = true;
      });

      // 🔥 Save to Search History (MUST be here after getting name)
      if (_selectedPlaceDescription != null && _selectedPlaceDescription!.isNotEmpty) {
        _addToSearchHistory(_selectedPlaceDescription!);
      }

      await _callRouteApi(newPosition, startNavigation: false);

      _triggerStepAnimation(); // 🔥 <<<<<<<<<< add this line
    } else {
      print('Place Details API Error: ${response.body}');
    }
  }

  Future<void> _callRouteApi(
      LatLng destination, {
        bool startNavigation = false,
      }) async {
    try {
      if (_currentLocation == null) {
        throw Exception('Current location not available');
      }

      final originString =
          "${_currentLocation!.latitude},${_currentLocation!.longitude}";
      final destinationString =
          "${destination.latitude},${destination.longitude}";

      final routeResponse = await APIService.routes(
        origin: originString,
        destination: destinationString,
      );

      // ✅ Show neutral warning if source is not verified
      if (routeResponse['source'] == 'Google Routes') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ This route may not be fully accessible. Please proceed with caution.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // 🔥 Store transit_id from response
      _transitId = routeResponse['transit_id'];
      print('🆔 Stored Transit ID: $_transitId');

      _segments = List<Map<String, dynamic>>.from(routeResponse['segments']);
      _currentSegmentIndex = 0;

      // ✅ Initialize totals
      _totalDistance = 0.0;
      _totalDuration = 0.0;

      setState(() {
        _polylines.clear();
        _isNavigating = startNavigation; // 🔥 IMPORTANT (start only if true)
        _hideSearchBar = true;
        _etaAnimationController.forward(from: 0.0);
      });

      if (_segments.isNotEmpty) {
        for (var segment in _segments) {
          // ✅ Sum distance and duration
          final distanceValue = (segment['distance']?['value'] ?? 0).toDouble();
          final durationValue = (segment['duration']?['value'] ?? 0).toDouble();
          _totalDistance += distanceValue;
          _totalDuration += durationValue;

          // ✅ Build polyline
          final points = segment['points'] as List<dynamic>;
          final List<LatLng> segmentPoints = [];

          for (var point in points) {
            segmentPoints.add(LatLng(point['latitude'], point['longitude']));
          }

          Color segmentColor = AppColors.surfaceUnknown;
          String surface = (segment['surface'] ?? '').toLowerCase();

          if (surface == 'asphalt') {
            segmentColor = AppColors.surfaceAsphalt;
          } else if (surface == 'concrete') {
            segmentColor = AppColors.surfaceConcrete;
          } else if (surface == 'paving_stones') {
            segmentColor = AppColors.surfacePavingStones;
          } else if (surface == 'missing') {
            segmentColor = AppColors.surfaceMissing;
          }

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: PolylineId('segment_${segment['segment_number']}'),
                points: segmentPoints,
                width: 6,
                color: segmentColor,
              ),
            );
          });
        }

        print('🛣️ Total distance: $_totalDistance meters');
        print('⏱️ Total duration: $_totalDuration seconds');
      }

      await _loadReportedMarkers();


    } catch (e) {
      print('❌ Failed to call route API: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate route')));
    }
  }


  Future<void> _fitMapToPolyline() async {
    if (_polylines.isEmpty) return;

    List<LatLng> allPoints = [];
    for (var polyline in _polylines) {
      allPoints.addAll(polyline.points);
    }

    if (allPoints.length < 2) return;

    final southwestLat = allPoints
        .map((p) => p.latitude)
        .reduce((a, b) => a < b ? a : b);
    final southwestLng = allPoints
        .map((p) => p.longitude)
        .reduce((a, b) => a < b ? a : b);
    final northeastLat = allPoints
        .map((p) => p.latitude)
        .reduce((a, b) => a > b ? a : b);
    final northeastLng = allPoints
        .map((p) => p.longitude)
        .reduce((a, b) => a > b ? a : b);

    final bounds = LatLngBounds(
      southwest: LatLng(southwestLat, southwestLng),
      northeast: LatLng(northeastLat, northeastLng),
    );

    // 🔥 Step 1: Zoom out quickly
    await _mapController?.animateCamera(CameraUpdate.zoomTo(12));

    // 🔥 Step 2: Wait briefly for dramatic effect
    await Future.delayed(const Duration(milliseconds: 300));

    // 🔥 Step 3: Fit the route nicely
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _showRecentSearches = false;
        });
      },
      child: Stack(
        children: [
          GoogleMap(
            polylines: _polylines, // 🔥 Add this!
            initialCameraPosition: CameraPosition(
              target: AppConstants.homeLatLng,
              zoom: AppConstants.defaultZoom,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _determinePosition();
              _startLiveLocationTracking();
            },
            onCameraMove: (CameraPosition position) {
              _handleCameraMove(position.zoom);
            },
            compassEnabled: true, // ✅ ADD THIS
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            markers: {..._markers, ..._reportedMarkers},
          ),

          // if (_showLegend)
          //   Positioned(
          //     bottom: 120,
          //     left: 0,
          //     right: 0,
          //     child: _buildLegendCard(),
          //   ),

          // Search Bar
          if (!_hideSearchBar)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔥 Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      focusNode: _searchFocusNode, // 🔥 Attach here!
                      controller: _searchController,
                      onChanged: _findPlace,
                      decoration: InputDecoration(
                        hintText: 'Search for a place',
                        hintStyle: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                        border: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _placePredictions.clear();
                              FocusScope.of(context).unfocus();
                            });
                          },
                        )
                            : const Icon(
                          Icons.search,
                          size: 28,
                          color: Colors.black54,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10), // 🔥 Add a little spacing

                  // 🔥 Recent Searches (if any)
                  if (_isSearchFocused && _searchHistory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Recent Searches",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _clearSearchHistory,
                                child: const Text(
                                  "Clear",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._searchHistory.map((history) {
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), // 🔥 Reduced horizontal & vertical space
                              leading: const Icon(Icons.history, size: 18, color: Colors.black54),
                              title: Text(
                                history,
                                style: AppTextStyles.label.copyWith(fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                // 🔥 Here's the main fix:
                                FocusScope.of(context).requestFocus(_searchFocusNode); // 1. Refocus Search Bar
                                _searchController.text = history;                      // 2. Fill text
                                _findPlace(history);

                                setState(() {
                                  _showRecentSearches = false; // 🔥 Hide Recent Searches immediately!
                                });// 3. Trigger search immediately
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10), // 🔥 Small space between sections

                  // 🔥 Google Places Predictions (if any)
                  if (_isSearchFocused && _placePredictions.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _placePredictions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final prediction = _placePredictions[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                            title: Text(
                              prediction['description'],
                              style: AppTextStyles.label.copyWith(fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              _moveToPlace(prediction['place_id']);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

          if (_showFloatingButton)
            _buildCompass(), // 👉 Add this here!
          // Recenter + Report Buttons
          if (_showFloatingButton)
            Positioned(
              top: 80,
              right: 20,
              child: Column(
                children: [
                  _buildMapButton(
                    icon: Icons.my_location,
                    onPressed: _recenterMap,
                  ),
                  const SizedBox(height: 12),
                  _buildMapButton(
                    icon: Icons.report_problem,
                    iconColor: Colors.red,
                    onPressed: _showReportModal,
                  ),
                ],
              ),
            ),

          // Top Instruction Card
          if (_segments.isNotEmpty &&
              _currentSegmentIndex < _segments.length &&
              _isNavigating)
            Positioned(top: 0, left: 0, right: 0, child: _buildInstructionCard()),

          // Bottom Distance/ETA Card
          if (_segments.isNotEmpty && _currentSegmentIndex < _segments.length)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child:
              (_segments.isNotEmpty &&
                  _currentSegmentIndex < _segments.length)
                  ? _buildDistanceEtaCard()
                  : const SizedBox(), // ➔ This keeps widget alive for animation
            ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    return AnimatedOpacity(
      opacity: _showLegend ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Surface Legend",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _expandLegend = !_expandLegend;
                    });
                  },
                  icon: Icon(
                    _expandLegend
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 28,
                  ),
                ),
              ],
            ),
            if (_expandLegend)
              const SizedBox(height: 8),
            if (_expandLegend)
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _buildLegendItem(AppColors.surfaceAsphalt, 'Asphalt'),
                  _buildLegendItem(AppColors.surfaceConcrete, 'Concrete'),
                  _buildLegendItem(AppColors.surfacePavingStones, 'Paving Stones'),
                  _buildLegendItem(AppColors.surfaceMissing, 'Missing'),
                  _buildLegendItem(AppColors.surfaceUnknown, 'Other'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass() {
    if (_currentBearing.abs() < 5) {
      return const SizedBox.shrink(); // Hide compass if almost facing North
    }
    return Positioned(
      top: 200,
      right: 20,
      child: AnimatedRotation(
        turns: (_currentBearing) / 360,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: 48, // Match your recenter/report button size
          height: 48,
          child: FloatingActionButton(
            heroTag: 'compass',
            backgroundColor: Colors.white,
            onPressed: () async {
              if (_mapController != null) {
                await _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _currentLocation != null
                          ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
                          : AppConstants.homeLatLng,
                      zoom: await _mapController!.getZoomLevel(),
                      bearing: 0,
                      tilt: 0,
                    ),
                  ),
                );
              }
            },
            child: const Icon(Icons.navigation, color: Colors.black, size: 28), // You can adjust icon size too
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    final currentSegment = _segments[_currentSegmentIndex];
    final currentInstruction = currentSegment['instruction'] ?? "Proceed on the route";

    String? nextInstruction;
    if (_currentSegmentIndex + 1 < _segments.length) {
      final nextSegment = _segments[_currentSegmentIndex + 1];
      nextInstruction = nextSegment['instruction'];
    }

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getInstructionIcon(currentInstruction),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentInstruction,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // 🔥 Only show "Then" if nextInstruction is not null/empty
            if (nextInstruction != null && nextInstruction.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 38, top: 6),
                child: Text(
                  "Then: $nextInstruction",
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceEtaCard() {
    final segment = _segments.isNotEmpty ? _segments[_currentSegmentIndex] : null;
    final distance = segment != null ? (segment['distance']['text'] ?? "") : "";
    final duration = segment != null ? (segment['duration']['text'] ?? "") : "";

    return FadeTransition(
      opacity: _etaFadeAnimation,
      child: SlideTransition(
        position: _etaSlideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Distance Row
              Row(
                children: [
                  const Icon(Icons.straighten, size: 20, color: Colors.black87),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      distance,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ✅ Duration Row
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.black87),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      duration,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ✅ Surface Legend Toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandLegend = !_expandLegend;
                  });
                },
                child: Row(
                  children: [
                    const Icon(Icons.legend_toggle, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Surface Legend',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _expandLegend
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                    ),
                  ],
                ),
              ),

              if (_expandLegend) const SizedBox(height: 6),

              if (_expandLegend)
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _buildLegendItem(AppColors.surfaceAsphalt, 'Asphalt'),
                    _buildLegendItem(AppColors.surfaceConcrete, 'Concrete'),
                    _buildLegendItem(AppColors.surfacePavingStones, 'Paving Stones'),
                    _buildLegendItem(AppColors.surfaceMissing, 'Missing'),
                    _buildLegendItem(AppColors.surfaceUnknown, 'Other'),
                  ],
                ),

              const SizedBox(height: 12),

              // ✅ Bottom Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isNavigating) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.play_arrow,
                          size: 30,
                          color: AppColors.primary,
                        ),
                        onPressed: () async {
                          setState(() {
                            _isNavigating = true;
                            _currentSegmentIndex = 0;
                            _showFloatingButton = true;
                            _showLegend = true;
                            _expandLegend = false;
                          });

                          if (_transitId != null) {
                            try {
                              await APIService.createTransit(
                                transitId: _transitId!,
                                wheelChair: 1,
                              );
                              print('🚀 Transit created successfully');
                            } catch (e) {
                              print('❌ Failed to create transit: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to create transit')),
                              );
                            }
                          }

                          await _fitMapToPolyline();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 24, color: Colors.white),
                        onPressed: _cancelRoute,
                      ),
                    ),
                  ],
                  if (_isNavigating)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 24, color: Colors.white),
                        onPressed: _cancelRoute,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.black,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: FloatingActionButton(
        heroTag: icon.toString(),
        backgroundColor: Colors.white,
        onPressed: onPressed,
        child: Icon(icon, color: iconColor, size: 30),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
