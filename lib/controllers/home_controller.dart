import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_training/controllers/auth_controller.dart';
import 'package:firebase_training/models/bid_model.dart';
import 'package:firebase_training/models/request_model.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  StreamSubscription<QuerySnapshot>? _subscription;

  final requests = <RequestModel>[].obs;
  final myBidRequestIds = <String>{}.obs;
  final myBids = RxMap<String, BidModel>(); // requestId -> BidModel
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  StreamSubscription<QuerySnapshot>? _bidsSubscription;

  @override
  void onInit() {
    super.onInit();
    ever(_authController.userRole, (_) => _startListening());
    
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startListening();
      } else {
        isLoading.value = false;
      }
    });

    _startListening();
  }

  void _startListening() {
    _subscription?.cancel();
    _bidsSubscription?.cancel();

    final String role = _authController.userRole.value;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      isLoading.value = false;
      return;
    }

    final String uid = user.uid;
    isLoading.value = true;

    // 1. Listen to fixer's own bids to filter them out of marketplace
    if (role == 'fixer') {
      _bidsSubscription = _firestore
          .collectionGroup('bids')
          .where('fixerId', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
            myBidRequestIds.assignAll(snapshot.docs.map((doc) => doc.reference.parent.parent!.id));
            
            // Map requestId to BidModel
            Map<String, BidModel> bidsMap = {};
            for (var doc in snapshot.docs) {
              final requestId = doc.reference.parent.parent!.id;
              bidsMap[requestId] = BidModel.fromMap(doc.data(), doc.id);
            }
            myBids.assignAll(bidsMap);
          });
    }

    // 2. Listen to requests
    try {
      Query query = _firestore.collection('requests');

      if (role == 'user') {
        query = query.where('userId', isEqualTo: uid);
      }

      _subscription = query.snapshots().listen(
            (snapshot) {
              var list = snapshot.docs.map((doc) {
                    return RequestModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).toList();
              
              // Sort locally by createdAt descending
              list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              
              requests.value = list;
              isLoading.value = false;
              errorMessage.value = '';
            },
            onError: (error) {
              errorMessage.value = 'Failed to load requests: $error';
              isLoading.value = false;
            },
          );
    } catch (e) {
      errorMessage.value = 'Stream error: $e';
      isLoading.value = false;
    }
  }

  // Helper to filter marketplace for fixers
  List<RequestModel> get filteredMarketplace {
    if (_authController.userRole.value != 'fixer') return requests;
    
    return requests.where((req) {
      // Hide if already accepted by ANYONE or if CURRENT FIXER has bid on it
      return req.status == 'pending' && !myBidRequestIds.contains(req.id);
    }).toList();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _bidsSubscription?.cancel();
    super.onClose();
  }
}
