import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';

class DeviceTrackingService {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;

  // Device info
  String _deviceModel = '';
  String _osVersion = '';
  String _ipAddress = '';

  // Location info
  Position? _position;
  bool _locationGranted = false;
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  DeviceTrackingService() {
    _authService = _getIt.get<AuthService>();
  }

  // Getters
  String get deviceModel => _deviceModel;
  String get osVersion => _osVersion;
  String get ipAddress => _ipAddress;
  Position? get position => _position;
  bool get locationGranted => _locationGranted;
  bool get isTracking => _isTracking;

  // Device methods
  Future<void> fetchDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfoPlugin.androidInfo;
      _deviceModel = '${info.manufacturer} ${info.model}';
      _osVersion = 'Android ${info.version.release}';
    } else if (Platform.isIOS) {
      final info = await deviceInfoPlugin.iosInfo;
      _deviceModel = '${info.name} ${info.model}';
      _osVersion = 'iOS ${info.systemVersion}';
    }
  }

  Future<void> fetchIpAddress() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ipify.org?format=json'),
      );
      if (response.statusCode == 200) {
        _ipAddress = jsonDecode(response.body)['ip'];
      }
    } catch (e) {
      debugPrint("Failed to fetch IP: $e");
    }
  }

  Future<void> loadDeviceData() async {
    await fetchDeviceInfo();
    await fetchIpAddress();
  }

  Future<void> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

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
  }

  Future<void> fetchLocation() async {
    if (!_locationGranted) return;

    try {
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _updateLocationToDatabase();
    } catch (e) {
      debugPrint("Failed to fetch location: $e");
    }
  }

  Future<void> startLocationTracking() async {
    if (!_locationGranted || _isTracking) return;

    _isTracking = true;
    debugPrint('Starting continuous location tracking...');

    // Timer for periodic updates
    _locationTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      await _updateLocationPeriodically();
    });

    // Position Stream for distance-based updates
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          _position = position;
          _updateLocationToDatabase();
          debugPrint(
            'Location updated via distance filter: ${position.latitude}, ${position.longitude}',
          );
        });

    await fetchLocation();
  }

  Future<void> _updateLocationPeriodically() async {
    if (!_locationGranted) return;

    try {
      debugPrint('Updating location via timer... ${DateTime.now()}');
      final newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _position = newPosition;
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
    }
  }

  Future<void> updateDeviceRecord() async {
    try {
      final uid = _authService.user?.uid ?? "unknown";

      final Map<String, dynamic> deviceData = {
        'device_model': _deviceModel,
        'os_version': _osVersion,
        'ip_address': _ipAddress,
        'timestamp': FieldValue.serverTimestamp(),
        'last_updated': DateTime.now().toIso8601String(),
      };

      if (_position != null) {
        deviceData['location'] = {
          'lat': _position!.latitude,
          'lng': _position!.longitude,
          'accuracy': _position!.accuracy,
          'speed': _position!.speed,
          'heading': _position!.heading,
        };
      }

      await FirebaseFirestore.instance
          .collection('devices')
          .doc(uid)
          .set(deviceData, SetOptions(merge: true));

      debugPrint('Device record updated successfully');
    } catch (e) {
      debugPrint('Failed to update device record: $e');
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
  }

  void dispose() {
    stopLocationTracking();
  }
}
