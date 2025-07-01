import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/services/navigation_service.dart';
import 'package:map_tracker/widgets/navigation_drawer.dart';
import 'package:map_tracker/widgets/toast_widget.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/device_record_provider.dart';
import '../../providers/location_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late NavigationService _navigationService;
  late AuthService _authService;
  final GetIt _getIt = GetIt.instance;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationPermissionDialog();
    });
  }

  Future<void> _showLocationPermissionDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Access"),
        content: const Text(
          "This app wants to access your location to track your device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Deny"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _initializeTracking();
            },
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeTracking() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    await deviceProvider.loadDeviceData();
    await locationProvider.requestPermission();
    await locationProvider.fetchLocation();

    final uid = _authService.user?.uid ?? "unknown";

    await FirebaseFirestore.instance.collection('devices').doc(uid).set({
      'device_model': deviceProvider.deviceModel,
      'os_version': deviceProvider.osVersion,
      'ip_address': deviceProvider.ipAddress,
      'location': {
        'lat': locationProvider.position?.latitude,
        'lng': locationProvider.position?.longitude,
      },
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final device = Provider.of<DeviceProvider>(context);
    final location = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Soul Tracker"),
        backgroundColor: Colors.amber,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              try {
                await _authService.logout();
                if (!mounted) return;
                ToastWidget.show(
                  context: context,
                  title: "Logged out successfully",
                  subtitle: "See you soon!",
                  iconColor: Colors.black,
                  backgroundColor: Colors.green,
                  icon: Icons.logout,
                );
                _navigationService.pushReplacementNamed("/login");
              } catch (e) {
                Fluttertoast.showToast(
                  msg: 'Logout failed: $e',
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 14.0,
                );
                debugPrint("Logout Error: $e");
              }
            },
          ),
        ],
      ),
      drawer: const NavigationDrawerWidget(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Device: ${device.deviceModel}"),
            Text("OS: ${device.osVersion}"),
            Text("IP: ${device.ipAddress}"),
            if (location.position != null)
              Text(
                "Location: ${location.position!.latitude}, ${location.position!.longitude}",
              ),
            if (!location.locationGranted)
              const Text("Location permission not granted"),
          ],
        ),
      ),
    );
  }
}
