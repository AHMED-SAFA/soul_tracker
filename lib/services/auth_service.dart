import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:map_tracker/providers/location_provider.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  User? get user {
    return _user;
  }

  AuthService() {
    _firebaseAuth.authStateChanges().listen(authListener);
  }

  void authListener(User? user) {
    if (user != null) {
      _user = user;
      // Start location tracking when user logs in
      _startLocationTrackingForUser();
    } else {
      _user = null;
      // Stop location tracking when user logs out
      _stopLocationTrackingForUser();
    }
  }

  void _startLocationTrackingForUser() {
    try {
      final locationProvider = GetIt.instance.get<LocationProvider>();
      locationProvider.initializeForUser();
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  void _stopLocationTrackingForUser() {
    try {
      final locationProvider = GetIt.instance.get<LocationProvider>();
      locationProvider.cleanupForUser();
    } catch (e) {
      print('Error stopping location tracking: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _user = credential.user;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({
              'isActive': true,
              'lastLogin': FieldValue.serverTimestamp(),
            });

        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  Future<bool> logout(String uid) async {
    try {
      await _firebaseAuth.signOut();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isActive': false,
      });
      _user = null;
      return true;
    } catch (e) {
      print('Logout error: $e');
    }
    return false;
  }

  Future<UserCredential> register(
    String email,
    String password,
    String confirmPassword, {
    String? name,
    String? profileImageUrl,
    required bool isActive,
  }) async {
    if (password != confirmPassword) {
      throw FirebaseAuthException(
        code: 'passwords-do-not-match',
        message: 'Password and confirm password do not match.',
      );
    }

    if (password.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password should be at least 6 characters long.',
      );
    }

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _user = credential.user;

        if (name != null && name.isNotEmpty) {
          await credential.user!.updateDisplayName(name);
        }

        await _saveUserDataToFirestore(
          uid: credential.user!.uid,
          email: email,
          name: name,
          profileImageUrl: profileImageUrl,
          isActive: true,
        );

        return credential;
      } else {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'Failed to create user account.',
        );
      }
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected registration error: $e');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred during registration.',
      );
    }
  }

  Future<void> _saveUserDataToFirestore({
    required String uid,
    required String email,
    required String? name,
    String? profileImageUrl,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name ?? "Not Set",
        'dob': '' ?? "Not Set",
        'gender': '' ?? "Not Set",
        'address': '' ?? "Not Set",
        'profileImageUrl': profileImageUrl ?? "Not Set",
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': isActive,
      });
    } catch (e) {
      print('Error saving user data to Firestore: $e');
      throw e;
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? profileImageUrl,
    String? dob,
    String? gender,
    String? address,
  }) async {
    if (_user == null) return;

    try {
      if (name != null && name.isNotEmpty) {
        await _user!.updateDisplayName(name);
      }

      await _firestore.collection('users').doc(_user!.uid).update({
        if (name != null) 'name': name,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender,
        if (address != null) 'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  bool get isAuthenticated => _user != null;
  String? get currentUserId => _user?.uid;
  String? get currentUserEmail => _user?.email;

  Future<void> sendEmailVerification() async {
    if (_user != null && !_user!.emailVerified) {
      await _user!.sendEmailVerification();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }
}
