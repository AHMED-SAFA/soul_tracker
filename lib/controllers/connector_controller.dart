import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectorController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> displayAllGeneratedCodesDetails() async {
    final currentUser = _auth.currentUser;
    final List<Map<String, dynamic>> connectorDetails = [];
    final List<Map<String, dynamic>> results = [];
    if (currentUser == null) return [];

    final querySnapshot = await _firestore
        .collection('shareCodes')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final code = doc.id;

      final expiresAt = data['expiresAt'];
      final isActive = data['isActive'];
      final connectors = List<String>.from(data['connectors'] ?? []);

      // Clear connectorDetails for each code to avoid duplicates
      connectorDetails.clear();

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
        'connectors': List.from(
          connectorDetails,
        ), // Create a new list to avoid reference issues
      });
    }

    print("result for connectors: $results");
    return results;
  }

  Future<void> deleteConnector({
    required String code,
    required String connectorId,
  }) async {
    try {
      await _firestore.collection('shareCodes').doc(code).update({
        'connectors': FieldValue.arrayRemove([connectorId]),
      });

    } catch (e) {
      print('Error deleting connector: $e');
      throw e;
    }
  }
}
