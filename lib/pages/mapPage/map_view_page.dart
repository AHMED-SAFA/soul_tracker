import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MapViewPage extends StatefulWidget {
  final double lat;
  final double lng;
  final String deviceName;
  final String name;
  final String userId;
  final String profileImageUrl;

  const MapViewPage({
    super.key,
    required this.lat,
    required this.lng,
    required this.deviceName,
    required this.name,
    required this.userId,
    required this.profileImageUrl,
  });

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  late MapController _mapController;
  late LatLng _currentPosition;
  StreamSubscription<DocumentSnapshot>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentPosition = LatLng(widget.lat, widget.lng);
    _setupLocationListener();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _setupLocationListener() {
    _locationSubscription = FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            final data = snapshot.data()!;
            final location = data['location'] as Map<String, dynamic>?;
            final timestamp = data['timestamp'] as Timestamp?;

            if (location != null &&
                location['lat'] != null &&
                location['lng'] != null) {
              final newPosition = LatLng(
                location['lat'].toDouble(),
                location['lng'].toDouble(),
              );

              setState(() {
                _currentPosition = newPosition;
              });

              _mapController.move(_currentPosition, 15.0);
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Tracking ${widget.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.black),
            onPressed: () {
              _mapController.move(_currentPosition, 15.0);
            },
            tooltip: 'Center on location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.map_tracker',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    child: Container(
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Color(0xFF1565C0),
                        size: 45,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Status Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            (widget.profileImageUrl.trim().isNotEmpty)
                            ? NetworkImage(widget.profileImageUrl)
                            : const AssetImage(
                                    'assets/images/default_avatar.png',
                                  )
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF212121),
                              ),
                            ),
                            Text(
                              widget.deviceName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_currentPosition.latitude.toStringAsFixed(6)}, '
                          'Lng: ${_currentPosition.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Zoom Controls
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(_currentPosition, zoom);
                  },
                  child: const Icon(Icons.add, color: Color(0xFF1565C0)),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(_currentPosition, zoom);
                  },
                  child: const Icon(Icons.remove, color: Color(0xFF1565C0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
