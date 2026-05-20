import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_training/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final isLoading = false.obs;
  final userRole = 'user'.obs; // Default to user
  final userEmail = ''.obs;
  final location = ''.obs;
  final serviceType = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth changes to fetch role and handle session expiration
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        fetchUserRole(user.uid);
      } else {
        userRole.value = 'user';
        userEmail.value = '';
        location.value = '';
        serviceType.value = '';
        
        // Ensure navigation only happens after the app is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute != '/login' && Get.currentRoute != '/signup') {
            Get.offAllNamed('/login');
          }
        });
      }
    });
  }

  Future<void> fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        userRole.value = doc.data()?['role'] ?? 'user';
        userEmail.value = doc.data()?['email'] ?? '';
        location.value = doc.data()?['location'] ?? '';
        serviceType.value = doc.data()?['serviceType'] ?? '';
      }
    } catch (e) {
      print('Error fetching role: $e');
    }
  }

  // Fetch a fixer's profile data and their average rating
  Future<Map<String, dynamic>> getFixerProfile(String fixerId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(fixerId).get();
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('fixerId', isEqualTo: fixerId)
          .get();

      double avgRating = 0.0;
      if (reviewsSnapshot.docs.isNotEmpty) {
        double total = 0.0;
        for (var doc in reviewsSnapshot.docs) {
          total += (doc.data()['rating'] ?? 0.0);
        }
        avgRating = total / reviewsSnapshot.docs.length;
      }

      final userData = userDoc.data()!;
      userData['uid'] = userDoc.id; // Ensure UID is set in the map

      return {
        'user': UserModel.fromMap(userData),
        'avgRating': avgRating,
        'reviewCount': reviewsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error fetching fixer profile: $e');
      return {};
    }
  }

  Future<void> updateProfile({
    required String locationText,
    required String serviceTypeText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'location': locationText,
        'serviceType': serviceTypeText,
      });
      location.value = locationText;
      serviceType.value = serviceTypeText;
      Get.snackbar('Success', 'Profile updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Validation', 'Email and password cannot be empty');
      return;
    }
    isLoading.value = true;
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user role to Firestore
      final user = UserModel(uid: credential.user!.uid, email: email, role: role);
      await _firestore.collection('users').doc(user.uid).set(user.toMap());

      userRole.value = role;
      userEmail.value = email;

      Get.snackbar('Success', 'Account created successfully!');
      Get.offAllNamed('/home');
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _handleAuthError(e.code));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Validation', 'Email and password cannot be empty');
      return;
    }
    isLoading.value = true;
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch role
      await fetchUserRole(credential.user!.uid);

      Get.snackbar('Success', 'Logged in successfully!');
      Get.offAllNamed('/home');
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _handleAuthError(e.code));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout: $e');
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    if (email.isEmpty) {
      Get.snackbar('Validation', 'Please enter your email address');
      return;
    }

    isLoading.value = true;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      Get.snackbar(
        'Success',
        'Password reset email sent! Check your inbox & spam folder.',
      );
      Get.back();
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _handleAuthError(e.code));
    } finally {
      isLoading.value = false;
    }
  }

  String _handleAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
