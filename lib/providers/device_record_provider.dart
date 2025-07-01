import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

class DeviceProvider with ChangeNotifier {
  String _deviceModel = '';
  String _osVersion = '';
  String _ipAddress = '';

  String get deviceModel => _deviceModel;
  String get osVersion => _osVersion;
  String get ipAddress => _ipAddress;

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
    notifyListeners();
  }

  Future<void> fetchIpAddress() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ipify.org?format=json'),
      );
      if (response.statusCode == 200) {
        _ipAddress = jsonDecode(response.body)['ip'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to fetch IP: $e");
    }
  }

  Future<void> loadDeviceData() async {
    await fetchDeviceInfo();
    await fetchIpAddress();
  }
}
