import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapViewPage extends StatelessWidget {
  final double lat;
  final double lng;
  final String deviceName;

  const MapViewPage({
    super.key,
    required this.lat,
    required this.lng,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking: $deviceName'),
        backgroundColor: Colors.amber,
      ),
      body: FlutterMap(
        options: MapOptions(initialCenter: point, initialZoom: 15),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.map_tracker',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
