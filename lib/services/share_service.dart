import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> generateSharingCode() async {
    final user = _auth.currentUser;
    print("User from share service: $user");

    final code = _generateRandomCode(8);

    final expiryTime = DateTime.now().add(const Duration(hours: 2));

    await _firestore.collection('shareCodes').doc(code).set({
      'userId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiryTime,
      'isActive': true,
    });

    return code;
  }

  Future<Map<String, dynamic>?> validateSharingCode(String code) async {
    final docRef = _firestore.collection('shareCodes').doc(code);
    final doc = await docRef.get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();

    if (expiresAt.isBefore(DateTime.now())) {
      await docRef.update({'isActive': false});
      return null;
    }

    if (data['isActive'] == false) return null;

    final currentUser = _auth.currentUser;

    final String ownerId = data['userId'];
    final String connectorId = currentUser?.uid ?? "";

    if (connectorId.isNotEmpty && connectorId != ownerId) {
      await docRef.update({
        'connectors': FieldValue.arrayUnion([connectorId]),
      });
    } else {
      return null;
    }

    return {'userId': ownerId, 'code': code};
  }

  Future<List<Map<String, dynamic>>> getTrackingConnections() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final querySnapshot = await _firestore
        .collection('shareCodes')
        .where('connectors', arrayContains: currentUser.uid)
        .where('isActive', isEqualTo: true)
        .get();

    List<Map<String, dynamic>> connections = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String;

      // Get user details from devices collection
      final deviceDoc = await _firestore
          .collection('devices')
          .doc(userId)
          .get();

      if (deviceDoc.exists) {
        final deviceData = deviceDoc.data()!;
        connections.add({
          'userId': userId,
          'code': doc.id,
          'deviceModel': deviceData['device_model'] ?? 'Unknown',
          'osVersion': deviceData['os_version'] ?? 'Unknown',
          'ipAddress': deviceData['ip_address'] ?? 'Unknown',
          'location': deviceData['location'] ?? {},
          'timestamp': deviceData['timestamp'],
        });
      }
    }

    return connections;
  }

  Future<List<Map<String, dynamic>>> displayAllGeneratedCodesDetails() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final querySnapshot = await _firestore
        .collection('shareCodes')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    final List<Map<String, dynamic>> results = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final code = doc.id;

      final expiresAt = data['expiresAt'];
      final isActive = data['isActive'];
      final connectors = List<String>.from(data['connectors'] ?? []);

      final List<Map<String, dynamic>> connectorDetails = [];

      for (final connectorId in connectors) {
        final connectorDoc = await _firestore
            .collection('users')
            .doc(connectorId)
            .get();

        if (connectorDoc.exists) {
          final connectorData = connectorDoc.data()!;
          connectorDetails.add({
            'uid': connectorId,
            'name': connectorData['name'],
            'email': connectorData['email'],
            'profileImageUrl': connectorData['profileImageUrl'],
          });
        }
      }

      results.add({
        'code': code,
        'expiresAt': expiresAt,
        'isActive': isActive,
        'connectors': connectorDetails,
      });
    }

    return results;
  }

  Future<void> deactivateCode(String code) async {
    await _firestore.collection('shareCodes').doc(code).update({
      'isActive': false,
    });
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
