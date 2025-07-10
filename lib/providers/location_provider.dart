import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  bool _isInitialized = false;

  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;

  Position? get position => _position;
  bool get locationGranted => _locationGranted;
  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;

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
      Fluttertoast.showToast(
        msg: 'Location services are disabled.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      Fluttertoast.showToast(
        msg: 'Location services are disabled.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(
          msg: 'Location services are disabled.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      Fluttertoast.showToast(
        msg: 'Location permissions are permanently denied',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      await Geolocator.openAppSettings();
      return;
    }

    _locationGranted = true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> fetchLocation() async {
    if (!_locationGranted) return;

    try {
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      notifyListeners();
      await _updateLocationToDatabase();
    } catch (e) {
      debugPrint("Failed to fetch location: $e");
      // Try with lower accuracy as fallback
      try {
        _position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        );
        notifyListeners();
        await _updateLocationToDatabase();
      } catch (e) {
        debugPrint("Failed to fetch location with fallback: $e");
      }
    }
  }

  Future<void> startLocationTracking() async {
    if (!_locationGranted || _isTracking) return;

    _isTracking = true;
    debugPrint('Starting continuous location tracking...');

    // Get initial location first
    await fetchLocation();

    // Method 1: Timer for periodic updates (every 10 seconds for more frequent updates)
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _updateLocationPeriodically();
    });

    // Method 2: Position Stream for distance-based updates
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1, // Update when moved 1 meter
            timeLimit: Duration(seconds: 10),
          ),
        ).listen(
          (Position position) {
            _position = position;
            notifyListeners();
            _updateLocationToDatabase();
            debugPrint(
              'Location updated via distance filter: ${position.latitude}, ${position.longitude}',
            );
          },
          onError: (error) {
            debugPrint('Position stream error: $error');
            // Restart tracking if stream fails
            _restartTracking();
          },
        );

    notifyListeners();
  }

  Future<void> _updateLocationPeriodically() async {
    if (!_locationGranted || !_isTracking) return;

    try {
      debugPrint('Updating location via timer... ${DateTime.now()}');

      final newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
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
        'location': {
          'lat': _position!.latitude,
          'lng': _position!.longitude,
          'accuracy': _position!.accuracy,
          'speed': _position!.speed,
          'heading': _position!.heading,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'last_updated': DateTime.now().toIso8601String(),
      });

      debugPrint(
        'Location updated in database: ${_position!.latitude}, ${_position!.longitude}',
      );
    } catch (e) {
      debugPrint("Failed to update location in database: $e");
      // If document doesn't exist, create it
      await _createDeviceDocument();
    }
  }

  Future<void> _createDeviceDocument() async {
    if (_position == null || _authService.user?.uid == null) return;

    try {
      final uid = _authService.user!.uid;

      await FirebaseFirestore.instance.collection('devices').doc(uid).set({
        'location': {
          'lat': _position!.latitude,
          'lng': _position!.longitude,
          'accuracy': _position!.accuracy,
          'speed': _position!.speed,
          'heading': _position!.heading,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'last_updated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      debugPrint('Device document created with location');
    } catch (e) {
      debugPrint("Failed to create device document: $e");
    }
  }

  Future<void> _restartTracking() async {
    debugPrint('Restarting location tracking...');
    stopLocationTracking();
    await Future.delayed(const Duration(seconds: 2));
    await startLocationTracking();
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

  // Call this method when user logs in
  Future<void> initializeForUser() async {
    if (_locationGranted) {
      // If already have permission, just start tracking
      await startLocationTracking();
    } else {
      // If not initialized, request permissions first
      await requestPermission();
      if (_locationGranted) {
        await startLocationTracking();
      }
    }
  }

  // Call this method when user logs out
  void cleanupForUser() {
    stopLocationTracking();
    _position = null;
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}
