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

    final expiryTime = DateTime.now().add(const Duration(minutes: 2));

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

    // Track connectors
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
