import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';

class LocationProvider with ChangeNotifier {
  Position? _position;
  bool _locationGranted = false;
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;

  Position? get position => _position;
  bool get locationGranted => _locationGranted;
  bool get isTracking => _isTracking;

  LocationProvider() {
    _authService = _getIt.get<AuthService>();
  }

  Future<void> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return;
    }

    _locationGranted = true;
    notifyListeners();

    // Start tracking immediately after permission is granted
    await startLocationTracking();
  }

  Future<void> fetchLocation() async {
    if (!_locationGranted) return;

    try {
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();

      // Update to database immediately
      await _updateLocationToDatabase();
    } catch (e) {
      debugPrint("Failed to fetch location: $e");
    }
  }

  Future<void> startLocationTracking() async {
    if (!_locationGranted || _isTracking) return;

    _isTracking = true;
    debugPrint('Starting continuous location tracking...');

    // Method 1: Timer for periodic updates (every 20 seconds)
    _locationTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      await _updateLocationPeriodically();
    });

    // Method 2: Position Stream for distance-based updates (5 meters)
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // Update when moved 5 meters
          ),
        ).listen((Position position) {
          _position = position;
          notifyListeners();
          _updateLocationToDatabase();
          debugPrint(
            'Location updated via distance filter: ${position.latitude}, ${position.longitude}',
          );
        });

    // Get initial location
    await fetchLocation();

    notifyListeners();
  }

  Future<void> _updateLocationPeriodically() async {
    if (!_locationGranted) return;

    try {
      debugPrint('Updating location via timer... ${DateTime.now()}');

      final newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _position = newPosition;
      notifyListeners();

      await _updateLocationToDatabase();

      debugPrint(
        'Location updated via timer: ${_position?.latitude}, ${_position?.longitude}',
      );
    } catch (e) {
      debugPrint("Failed to update location via timer: $e");
    }
  }

  Future<void> _updateLocationToDatabase() async {
    if (_position == null || _authService.user?.uid == null) return;

    try {
      final uid = _authService.user!.uid;

      await FirebaseFirestore.instance.collection('devices').doc(uid).update({
        'location': {'lat': _position!.latitude, 'lng': _position!.longitude},
        'timestamp': FieldValue.serverTimestamp(),
        'last_updated': DateTime.now().toIso8601String(),
      });

      debugPrint(
        'Location updated in database: ${_position!.latitude}, ${_position!.longitude}',
      );
    } catch (e) {
      debugPrint("Failed to update location in database: $e");
    }
  }

  void stopLocationTracking() {
    if (!_isTracking) return;

    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;

    _positionStream?.cancel();
    _positionStream = null;

    debugPrint('Location tracking stopped');
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}
