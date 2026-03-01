import 'package:flutter_background/flutter_background.dart';


Future<void> Startbackgroundservice() async {
  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Tracking Active",
    notificationText: "Your location is being tracked",
    notificationImportance: AndroidNotificationImportance.high,
    enableWifiLock: true,
  );

  bool hasPermissions = await FlutterBackground.hasPermissions;
  if (!hasPermissions) {
    await FlutterBackground.initialize(androidConfig: androidConfig);
  }

  await FlutterBackground.enableBackgroundExecution();
}
