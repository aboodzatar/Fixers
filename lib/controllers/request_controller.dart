import 'dart:ui';

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_training/models/bid_model.dart';
import 'package:firebase_training/models/request_model.dart';
import 'package:firebase_training/models/review_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class RequestController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final isLoading = false.obs;

  // Upload Images to Firebase Storage
  Future<List<String>> uploadImages(List<XFile> files) async {
    List<String> urls = [];
    for (var file in files) {
      try {
        // Correcting the bucket URL to match your Project ID: fir-training-app-32cbf
        final storageRef = _storage.refFromURL('gs://fir-training-app-32cbf.appspot.com');
        final fileRef = storageRef.child('requests/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
        
        print('Starting upload to: ${fileRef.fullPath}');
        
        final uploadTask = fileRef.putFile(File(file.path));
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        
        print('Upload successful! URL: $url');
        urls.add(url);
      } catch (e) {
        print('Error uploading image: $e');
        // We catch the error here so the request can still be submitted even if one image fails
      }
    }
    return urls;
  }

  // Submit Request with Images
  Future<void> submitRequest({
    required String deviceType,
    required String issue,
    List<String> imageUrls = const [],
  }) async {
    if (deviceType.isEmpty || issue.isEmpty) {
      Get.snackbar('Validation', 'Both fields are required');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'You must be logged in');
      return;
    }

    isLoading.value = true;
    try {
      final request = RequestModel(
        deviceType: deviceType.trim(),
        issueDescription: issue.trim(),
        userId: user.uid,
        userEmail: user.email ?? 'No email',
        createdAt: DateTime.now(),
        imageUrls: imageUrls,
      );

      await _firestore.collection('requests').add(request.toMap());

      // Show Lottie success dialog
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.network(
                  'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json', // Stable fallback animation
                  repeat: false,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.check_circle, size: 100, color: Colors.green),
                ),
                const Text(
                  'Request Submitted!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Fixers will start bidding soon.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/home'),
                  child: const Text('Back to Home'),
                )
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error submitting request: $e');
      Get.snackbar('Error', 'Failed to save request: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fixer Submits a Bid
  Future<void> submitBid({
    required String requestId,
    required double price,
    required String message,
    required bool canComeToYou,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final bid = BidModel(
        fixerId: user.uid,
        fixerName: user.email?.split('@')[0] ?? 'Fixer', // Using email prefix as name for now
        price: price,
        message: message,
        canComeToYou: canComeToYou,
        createdAt: DateTime.now(),
      );

      // Add bid to the 'bids' sub-collection of the request
      await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('bids')
          .doc(user.uid) // One bid per fixer per request
          .set(bid.toMap());

      Get.snackbar('Success', 'Bid submitted successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit bid: $e');
    }
  }

  // User Accepts a Bid
  Future<void> acceptBid(String requestId, BidModel bid) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'accepted',
        'acceptedBidId': bid.id,
        'acceptedFixerId': bid.fixerId,
        'acceptedFixerName': bid.fixerName,
        'finalPrice': bid.price,
      });

      // Update the bid status to accepted
      await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('bids')
          .doc(bid.fixerId)
          .update({'status': 'accepted'});

      Get.snackbar('Success', 'You have accepted the bid from ${bid.fixerName}!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept bid: $e');
    }
  }

  // Stream of bids for a specific request
  Stream<List<BidModel>> getBids(String requestId) {
    return _firestore
        .collection('requests')
        .doc(requestId)
        .collection('bids')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BidModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Stream of all bids submitted by a specific fixer (across all requests)
  Stream<List<Map<String, dynamic>>> getFixerBids(String fixerId) {
    return _firestore
        .collectionGroup('bids')
        .where('fixerId', isEqualTo: fixerId)
        .snapshots()
        .asyncMap((snapshot) async {
          print('DEBUG: Found ${snapshot.docs.length} bids for fixer $fixerId');
          List<Map<String, dynamic>> results = [];
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              final bid = BidModel.fromMap(data, doc.id);
              
              // Get parent request
              final requestDoc = await doc.reference.parent.parent!.get();
              if (requestDoc.exists) {
                results.add({
                  'bid': bid,
                  'request': RequestModel.fromMap(requestDoc.data() as Map<String, dynamic>, requestDoc.id),
                });
              }
            } catch (e) {
              print('DEBUG: Error parsing bid ${doc.id}: $e');
            }
          }
          return results;
        });
  }

  // Submit a Review for a fixer
  Future<void> submitReview(RequestModel request, double rating, String comment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final review = ReviewModel(
      userId: user.uid,
      userEmail: user.email ?? '',
      fixerId: request.acceptedFixerId ?? '',
      requestId: request.id!,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore.collection('reviews').add(review.toMap());
      
      // Mark the request as reviewed
      await _firestore.collection('requests').doc(request.id).update({
        'status': 'reviewed',
      });
      
      Get.snackbar('Thank you! ⭐', 'Your review has been submitted.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit review: $e');
    }
  }

  // Update Request Status (e.g., in_progress, completed)
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': status,
      });
      Get.snackbar('Status Updated', 'The request is now: ${status.replaceAll('_', ' ').toUpperCase()}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e');
    }
  }

  // User Rejects a Bid
  Future<void> rejectBid(String requestId, String fixerId) async {
    try {
      await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('bids')
          .doc(fixerId)
          .update({'status': 'rejected'});
      
      Get.snackbar('Bid Rejected', 'The offer has been removed.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject bid: $e');
    }
  }

  // Delete Request from Firestore
  Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).delete();
      Get.snackbar(
        'Deleted',
        'Request deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete request: $e');
    }
  }
}
