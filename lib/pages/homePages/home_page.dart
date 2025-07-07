import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:map_tracker/widgets/navigation_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../controllers/refresh_controller.dart';
import '../../services/share_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../mapPage/map_view_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _trackingConnections = [];
  final List<StreamSubscription> _locationSubscriptions = [];
  final RefreshController _refreshController = RefreshController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildCardToTrack();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _cancelLocationSubscriptions();
    _refreshController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _cancelLocationSubscriptions() {
    for (var subscription in _locationSubscriptions) {
      subscription.cancel();
    }
    _locationSubscriptions.clear();
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
        SnackBar(
          content: Text('Failed to refresh: ${e.toString()}'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Widget _buildTrackingCards() {
    if (_trackingConnections.isEmpty) {
      return AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF37474F).withOpacity(0.1),
                    const Color(0xFF455A64).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF37474F).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.location_searching_rounded,
                    size: 48,
                    color: const Color(0xFF37474F).withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Tracking Connections',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF37474F).withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking by sharing your location code',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF37474F).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: _trackingConnections.asMap().entries.map((entry) {
        final index = entry.key;
        final connection = entry.value;
        final location = connection['location'] as Map<String, dynamic>?;

        return AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, const Color(0xFFF8F9FA)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A237E).withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1A237E),
                                    Color(0xFF3949AB),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_pin_circle_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    connection['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    connection['deviceModel'] ??
                                        'Unknown Device',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(
                                        0xFF37474F,
                                      ).withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    location != null &&
                                        location['lat'] != null &&
                                        location['lng'] != null
                                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                                    : const Color(0xFFFF9800).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    location != null &&
                                            location['lat'] != null &&
                                            location['lng'] != null
                                        ? Icons.location_on
                                        : Icons.location_off,
                                    size: 16,
                                    color:
                                        location != null &&
                                            location['lat'] != null &&
                                            location['lng'] != null
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFF9800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF37474F).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.smartphone,
                                size: 16,
                                color: Color(0xFF37474F),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                connection['osVersion'] ?? 'Unknown OS',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF37474F),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
                                          connection['deviceModel'] ??
                                          'Unknown',
                                      name: connection['name'],
                                      userId: connection['userId'],
                                      profileImageUrl:
                                          connection['profileImageUrl'],
                                    ),
                                  ),
                                );
                              } else {
                                Fluttertoast.showToast(
                                  msg:
                                      "Location not available for this device.",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: const Color(0xFFFF9800),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.map_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              'View on Map',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(
        title: 'Soul Tracker',
        backgroundColor: Color(0xFF1A237E),
        showBackButton: false,
      ),
      drawer: const NavigationDrawerWidget(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFEDE7F6)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF1A237E),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A237E).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.track_changes_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tracking Connections',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Monitor your connected devices',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _buildTrackingCards(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
