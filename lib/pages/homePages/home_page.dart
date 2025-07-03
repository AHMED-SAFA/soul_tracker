import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/widgets/navigation_drawer.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../controllers/refresh_controller.dart';
import '../../providers/device_record_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/share_service.dart';
import '../../widgets/generate_code_widget.dart';
import '../mapPage/map_view_page.dart';
import '../../widgets/enter_code_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AuthService _authService;
  final GetIt _getIt = GetIt.instance;
  List<Map<String, dynamic>> _trackingConnections = [];
  final List<StreamSubscription> _locationSubscriptions = [];
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStartupTasks();
      _buildCardToTrack();
    });
  }

  @override
  void dispose() {
    _cancelLocationSubscriptions();
    _refreshController.dispose();
    super.dispose();
  }

  void _cancelLocationSubscriptions() {
    for (var subscription in _locationSubscriptions) {
      subscription.cancel();
    }
    _locationSubscriptions.clear();
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

  Future<void> _buildCardToTrack() async {
    final shareService = ShareService();
    final connections = await shareService.getTrackingConnections();

    _cancelLocationSubscriptions();

    setState(() {
      _trackingConnections = connections;
    });

    _setupRealTimeListeners();
  }

  void _setupRealTimeListeners() {
    for (int i = 0; i < _trackingConnections.length; i++) {
      final connection = _trackingConnections[i];
      final userId = connection['userId'] as String;

      final subscription = FirebaseFirestore.instance
          .collection('devices')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && mounted) {
              final data = snapshot.data()!;
              setState(() {
                _trackingConnections[i] = {
                  ..._trackingConnections[i],
                  'location': data['location'] ?? {},
                  'timestamp': data['timestamp'],
                };
              });
            }
          });

      _locationSubscriptions.add(subscription);
    }
  }

  Future<void> _refreshData() async {
    try {
      await _buildCardToTrack();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh: ${e.toString()}')),
      );
    }
  }

  Widget _buildTrackingCards() {
    if (_trackingConnections.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No active tracking connections',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: _trackingConnections.map((connection) {
        final location = connection['location'] as Map<String, dynamic>?;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Track: ${connection['name']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(connection['deviceModel']),
                Text(connection['osVersion']),
                if (location != null &&
                    location['lat'] != null &&
                    location['lng'] != null)
                  Text(
                    'Location: ${location['lat']}, ${location['lng']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (location != null &&
                            location['lat'] != null &&
                            location['lng'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapViewPage(
                                lat: location['lat'],
                                lng: location['lng'],
                                deviceName:
                                    connection['deviceModel'] ?? 'Unknown',
                                name: connection['name'],
                                userId: connection['userId'],
                                profileImageUrl: connection['profileImageUrl'],
                              ),

                            ),
                          );
                        } else {
                          Fluttertoast.showToast(
                            msg: "Location not available for this device.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        }
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('View on Map'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Soul Tracker"),
        backgroundColor: Colors.amber,
        centerTitle: true,
        actions: [
          const EnterCodeButton(),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Create location tracker code',
            onPressed: () {
              final shareService = ShareService();
              showGenerateCodeDialog(
                context: context,
                shareService: shareService,
              );
            },
          ),
        ],
      ),
      drawer: const NavigationDrawerWidget(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tracking Connections',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTrackingCards(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
