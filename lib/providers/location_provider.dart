import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider with ChangeNotifier {
  Position? _position;
  bool _locationGranted = false;

  Position? get position => _position;
  bool get locationGranted => _locationGranted;

  Future<void> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    _locationGranted =
        (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse);
    notifyListeners();
  }

  Future<void> fetchLocation() async {
    if (!_locationGranted) {
      await requestPermission();
    }
    if (_locationGranted) {
      _position = await Geolocator.getCurrentPosition();
      notifyListeners();
    }
  }
}
