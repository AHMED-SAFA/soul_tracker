import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../services/share_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late NavigationService _navigationService;
  late AuthService _authService;
  final GetIt _getIt = GetIt.instance;
  List<Map<String, dynamic>> _trackingConnections = [];

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStartupTasks();
      _buildCardToTrack();
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

  Future<void> _showGenerateCodeDialog() async {
    final shareService = ShareService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning'),
        content: const Text(
          'By sharing this code, others will be able to track your location.\n\n'
          'You can stop or modify tracking anytime later from the settings or tracking management screen.\n\n'
          'Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    try {
      final code = await shareService.generateSharingCode();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sharing Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this code with others to track your location:'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      code,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy Code',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Valid for 2 hours'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error generating code: ${e.toString()}')),
      );
    }
  }

  Future<void> _showEnterCodeDialog() async {
    final shareService = ShareService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Sharing Code'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter 6-digit code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final code = textController.text.trim();
              if (code.isEmpty) return;

              final validation = await shareService.validateSharingCode(code);
              if (!mounted) return;

              if (validation == null) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Invalid or expired code')),
                );
                return;
              }
              Navigator.pop(context);

              ToastWidget.show(
                context: context,
                title: "Code connected successfully!",
                icon: Icons.done_all,
                backgroundColor: Colors.greenAccent,
                iconColor: Colors.black,
              );
            },
            child: const Text('Track'),
          ),
        ],
      ),
    );
  }

  Future<void> _buildCardToTrack() async {
    final shareService = ShareService();
    final connections = await shareService.getTrackingConnections();

    setState(() {
      _trackingConnections = connections;
    });
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
                      'Track: ${connection['deviceModel']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(connection['osVersion']),
                if (location != null &&
                    location['lat'] != null &&
                    location['lng'] != null)
                  Text('Location: ${location['lat']}, ${location['lng']}'),
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
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
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Enter tracking code',
            onPressed: _showEnterCodeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Create location tracker code',
            onPressed: _showGenerateCodeDialog,
          ),
        ],
      ),
      drawer: const NavigationDrawerWidget(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tracking connections section
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
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _buildCardToTrack,
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
    );
  }
}
