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

class _MyAppState extends State<MyApp> {
  final GetIt _getIt = GetIt.instance;
  late NavigationService _navigationService;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _navigationService = _getIt.get<NavigationService>();
    _authService = _getIt.get<AuthService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStartupTasks();
    });
  }

  Future<void> _handleStartupTasks() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    await deviceProvider.loadDeviceData();
    await locationProvider.requestPermission();

    if (locationProvider.locationGranted) {
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
    } else {
      Fluttertoast.showToast(
        msg: "Location permission is required for tracking.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
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
