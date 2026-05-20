import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_training/controllers/home_controller.dart';
import 'package:firebase_training/controllers/request_controller.dart';
import 'package:firebase_training/models/bid_model.dart';
import 'package:firebase_training/models/request_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FixerOffersView extends StatefulWidget {
  const FixerOffersView({super.key});

  @override
  State<FixerOffersView> createState() => _FixerOffersViewState();
}

class _FixerOffersViewState extends State<FixerOffersView> {
  final HomeController homeController = Get.find<HomeController>();
  final RequestController requestController = Get.find<RequestController>();
  String _selectedFilter = 'all'; // all, pending, active, completed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Bids & Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending Bids', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Active Jobs', 'active'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', 'completed'),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Obx(() {
              if (homeController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Get all requests where the fixer has a bid
              List<RequestModel> myInvolvedRequests = homeController.requests.where((req) {
                return homeController.myBidRequestIds.contains(req.id);
              }).toList();

              // Combine with bid info
              List<Map<String, dynamic>> items = myInvolvedRequests.map((req) {
                return {
                  'request': req,
                  'bid': homeController.myBids[req.id],
                };
              }).toList();

              // Apply Filters
              if (_selectedFilter == 'pending') {
                items = items.where((i) => (i['bid'] as BidModel?)?.status == 'pending').toList();
              } else if (_selectedFilter == 'active') {
                items = items.where((i) {
                  final bid = i['bid'] as BidModel?;
                  final req = i['request'] as RequestModel;
                  return bid?.status == 'accepted' && (req.status == 'accepted' || req.status == 'in_progress');
                }).toList();
              } else if (_selectedFilter == 'completed') {
                items = items.where((i) {
                  final req = i['request'] as RequestModel;
                  return req.status == 'completed' || req.status == 'reviewed';
                }).toList();
              }

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No items found', style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final bid = items[index]['bid'] as BidModel?;
                  final req = items[index]['request'] as RequestModel;

                  if (bid == null) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(req.deviceType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            _buildBidStatusBadge(bid.status, req.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(req.issueDescription, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Your Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text('\$${bid.price}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                              ],
                            ),
                            if (bid.status == 'accepted')
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => Get.toNamed('/chat', arguments: {
                                      'requestId': req.id,
                                      'chatTitle': 'User',
                                    }),
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.indigo),
                                    tooltip: 'Open Chat',
                                  ),
                                  const SizedBox(width: 8),
                                  if (req.status == 'accepted')
                                    _buildStatusButton(
                                      'Start Job',
                                      Colors.indigo,
                                      () => requestController.updateRequestStatus(req.id!, 'in_progress'),
                                    ),
                                  if (req.status == 'in_progress')
                                    _buildStatusButton(
                                      'Complete',
                                      Colors.green,
                                      () => requestController.updateRequestStatus(req.id!, 'completed'),
                                    ),
                                  if (req.status == 'completed' || req.status == 'reviewed')
                                    const Text(
                                      'DONE',
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              )
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.indigo : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBidStatusBadge(String bidStatus, String reqStatus) {
    Color color = Colors.grey;
    String label = bidStatus;

    if (bidStatus == 'accepted') {
      color = Colors.green;
      if (reqStatus == 'in_progress') label = 'In Progress';
      if (reqStatus == 'completed' || reqStatus == 'reviewed') label = 'Completed';
    } else if (bidStatus == 'rejected') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
