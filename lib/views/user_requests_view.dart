import 'package:firebase_training/controllers/home_controller.dart';
import 'package:firebase_training/controllers/request_controller.dart';
import 'package:firebase_training/models/request_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class UserRequestsView extends StatefulWidget {
  const UserRequestsView({super.key});

  @override
  State<UserRequestsView> createState() => _UserRequestsViewState();
}

class _UserRequestsViewState extends State<UserRequestsView> {
  final HomeController homeController = Get.find<HomeController>();
  final RequestController requestController = Get.find<RequestController>();
  String _selectedFilter = 'all'; // all, pending, accepted, completed

  void _showRatingDialog(RequestModel req) {
    double selectedRating = 3.0;
    final TextEditingController commentController = TextEditingController();

    Get.defaultDialog(
      title: 'Rate the Service',
      content: Column(
        children: [
          RatingBar.builder(
            initialRating: 3,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) => selectedRating = rating,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: commentController,
            decoration: const InputDecoration(hintText: 'Leave a comment...'),
            maxLines: 3,
          ),
        ],
      ),
      textConfirm: 'Submit',
      onConfirm: () {
        requestController.submitReview(req, selectedRating, commentController.text);
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('All Requests', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  _buildFilterChip('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Accepted/Active', 'accepted'),
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

              // Apply Filter
              List<RequestModel> list = homeController.requests;
              if (_selectedFilter == 'pending') {
                list = list.where((r) => r.status == 'pending').toList();
              } else if (_selectedFilter == 'accepted') {
                list = list.where((r) => r.status == 'accepted' || r.status == 'in_progress').toList();
              } else if (_selectedFilter == 'completed') {
                list = list.where((r) => r.status == 'completed' || r.status == 'reviewed').toList();
              }

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No requests found', style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final req = list[index];
                  return _buildSimpleCard(req);
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

  Widget _buildSimpleCard(RequestModel req) {
    final bool canChat = req.status == 'accepted' || req.status == 'in_progress' || req.status == 'completed';
    final bool canRate = req.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.build_circle_rounded, color: Colors.indigo),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.deviceType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(DateFormat.yMMMd().format(req.createdAt), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(req.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  req.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(req.status)),
                ),
              ),
            ],
          ),
          if (canChat || canRate) ...[
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canChat)
                  TextButton.icon(
                    onPressed: () => Get.toNamed('/chat', arguments: {
                      'requestId': req.id,
                      'chatTitle': req.acceptedFixerName ?? 'Fixer',
                    }),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Chat'),
                  ),
                if (canRate)
                  const SizedBox(width: 8),
                if (canRate)
                  ElevatedButton(
                    onPressed: () => _showRatingDialog(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Rate Fixer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.blue;
      case 'accepted': return Colors.indigo;
      case 'in_progress': return Colors.orange;
      case 'completed': return Colors.green;
      case 'reviewed': return Colors.teal;
      default: return Colors.grey;
    }
  }
}
