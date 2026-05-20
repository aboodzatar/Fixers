import 'package:firebase_training/controllers/auth_controller.dart';
import 'package:firebase_training/controllers/request_controller.dart';
import 'package:firebase_training/models/bid_model.dart';
import 'package:firebase_training/models/request_model.dart';
import 'package:firebase_training/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';

class BidsListView extends StatelessWidget {
  final RequestModel request;
  BidsListView({super.key, required this.request});

  final RequestController requestController = Get.find<RequestController>();
  final AuthController authController = Get.find<AuthController>();

  void _showFixerProfile(String fixerId) async {
    Get.dialog(const Center(child: CircularProgressIndicator()));
    final profile = await authController.getFixerProfile(fixerId);
    Get.back(); // Close loading

    if (profile.isEmpty) return;
    final UserModel fixer = profile['user'];
    final double rating = profile['avgRating'];
    final int count = profile['reviewCount'];

    Get.defaultDialog(
      title: 'Fixer Profile',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFEEF2FF),
            child: Icon(Icons.person, color: Colors.indigo, size: 30),
          ),
          const SizedBox(height: 12),
          Text(fixer.email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RatingBarIndicator(
            rating: rating,
            itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
            itemCount: 5,
            itemSize: 20,
          ),
          const SizedBox(height: 4),
          Text('($count reviews)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.location_on_outlined, color: Colors.indigo),
            title: const Text('Location', style: TextStyle(fontSize: 14, color: Colors.grey)),
            subtitle: Text(fixer.location ?? 'Not specified', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.indigo),
            title: const Text('Service Type', style: TextStyle(fontSize: 14, color: Colors.grey)),
            subtitle: Text(fixer.serviceType ?? 'Workshop', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      confirm: TextButton(onPressed: () => Get.back(), child: const Text('Close')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Compare Offers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: StreamBuilder<List<BidModel>>(
        stream: requestController.getBids(request.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final bids = snapshot.data?.where((b) => b.status != 'rejected').toList() ?? [];

          if (bids.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No offers yet. Hang tight!', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          double lowestPrice = bids.map((b) => b.price).reduce((a, b) => a < b ? a : b);

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: bids.length,
            itemBuilder: (context, index) {
              final bid = bids[index];
              final isBestPrice = bid.price == lowestPrice;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: isBestPrice ? Border.all(color: Colors.green.shade300, width: 2) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    if (isBestPrice)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        ),
                        child: const Text(
                          'BEST PRICE OFFER',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showFixerProfile(bid.fixerId),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.indigo.shade50,
                                        child: const Icon(Icons.person, color: Colors.indigo),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    bid.fixerName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.info_outline_rounded, size: 14, color: Colors.indigo),
                                              ],
                                            ),
                                            if (bid.canComeToYou)
                                              const Row(
                                                children: [
                                                  Icon(Icons.directions_car_filled_rounded, size: 12, color: Colors.green),
                                                  SizedBox(width: 4),
                                                  Text('Offers Home Visit', style: TextStyle(fontSize: 12, color: Colors.green)),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('\$${bid.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(bid.message, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _showRejectConfirm(bid),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(color: Colors.red.shade100),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Decline'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _showAcceptConfirm(bid),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Accept'),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAcceptConfirm(BidModel bid) {
    Get.defaultDialog(
      title: 'Accept Offer?',
      middleText: 'Once accepted, ${bid.fixerName} will be assigned to your request.',
      textConfirm: 'Accept',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        requestController.acceptBid(request.id!, bid);
        Get.back(); // Close dialog
        Get.back(); // Go back to Home
      },
    );
  }

  void _showRejectConfirm(BidModel bid) {
    Get.defaultDialog(
      title: 'Decline Offer?',
      middleText: 'This offer will be removed from your list.',
      textConfirm: 'Decline',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        requestController.rejectBid(request.id!, bid.fixerId);
        Get.back();
      },
    );
  }
}
