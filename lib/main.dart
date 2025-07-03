import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:map_tracker/providers/device_record_provider.dart';
import 'package:map_tracker/providers/location_provider.dart';
import 'package:map_tracker/providers/user_provider.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/services/navigation_service.dart';
import 'package:map_tracker/utils.dart';
import 'package:provider/provider.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await setup();
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  runApp(MyApp());
}

Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupFirebase();
  await registerServices();
}

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  final String taskId = task.taskId;
  final bool timeout = task.timeout;

  if (timeout) {
    BackgroundFetch.finish(taskId);
    return;
  }

  try {
    WidgetsFlutterBinding.ensureInitialized();

    final position = await Geolocator.getCurrentPosition();
    final uid = GetIt.I.get<AuthService>().user?.uid ?? "unknown";

    await FirebaseFirestore.instance.collection('devices').doc(uid).update({
      'location': {'lat': position.latitude, 'lng': position.longitude},
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print("Background fetch error: $e");
  }

  BackgroundFetch.finish(taskId);
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
    _configureBackgroundFetch();
  }

  void _configureBackgroundFetch() async {
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 5,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiredNetworkType: NetworkType.ANY,
      ),
      (String taskId) async {
        try {
          final position = await Geolocator.getCurrentPosition();
          final uid = _authService.user?.uid ?? "unknown";

          await FirebaseFirestore.instance
              .collection('devices')
              .doc(uid)
              .update({
                'location': {
                  'lat': position.latitude,
                  'lng': position.longitude,
                },
                'timestamp': FieldValue.serverTimestamp(),
              });
        } catch (e) {
          print("Foreground fetch error: $e");
        }

        BackgroundFetch.finish(taskId);
      },
      (String taskId) async {
        BackgroundFetch.finish(taskId);
      },
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
