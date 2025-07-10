import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:map_tracker/providers/device_record_provider.dart';
import 'package:map_tracker/providers/location_provider.dart';
import 'package:map_tracker/providers/user_provider.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/services/navigation_service.dart';
import 'package:map_tracker/utils.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await setup();
  runApp(MyApp());
}

Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupFirebase();
  await registerServices();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GetIt _getIt = GetIt.instance;
  late NavigationService _navigationService;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navigationService = _getIt.get<NavigationService>();
    _authService = _getIt.get<AuthService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStartupTasks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground
        if (_authService.user != null && !locationProvider.isTracking) {
          locationProvider.startLocationTracking();
        }
        break;
      case AppLifecycleState.paused:
        // App went to background - keep tracking
        if (_authService.user != null && !locationProvider.isTracking) {
          locationProvider.startLocationTracking();
        }
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        // locationProvider.stopLocationTracking();
        if (_authService.user != null && !locationProvider.isTracking) {
          locationProvider.startLocationTracking();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _handleStartupTasks() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    await deviceProvider.loadDeviceData();

    if (_authService.user != null) {
      await _initializeLocationTracking(deviceProvider, locationProvider);
    }
  }

  Future<void> _initializeLocationTracking(
    DeviceProvider deviceProvider,
    LocationProvider locationProvider,
  ) async {
    await locationProvider.requestPermission();

    if (locationProvider.locationGranted) {
      await _createOrUpdateDeviceRecord(deviceProvider);

      await locationProvider.startLocationTracking();
    } else {
      _showLocationPermissionError();
    }
  }

  Future<void> _createOrUpdateDeviceRecord(
    DeviceProvider deviceProvider,
  ) async {
    try {
      final uid = _authService.user?.uid ?? "unknown";

      final Map<String, dynamic> deviceData = {
        'device_model': deviceProvider.deviceModel,
        'os_version': deviceProvider.osVersion,
        'ip_address': deviceProvider.ipAddress,
        'timestamp': FieldValue.serverTimestamp(),
        'last_updated': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('devices')
          .doc(uid)
          .set(deviceData, SetOptions(merge: true));

      debugPrint('Device record created/updated successfully');
    } catch (e) {
      debugPrint('Failed to create/update device record: $e');
    }
  }

  void _showLocationPermissionError() {
    Fluttertoast.showToast(
      msg: "Location permission is required for tracking.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigationService.navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          useMaterial3: true,
        ),
        initialRoute: _authService.user != null ? "/home" : "/login",
        routes: _navigationService.routes,
      ),
    );
  }
}
