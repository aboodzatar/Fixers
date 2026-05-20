import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_training/controllers/request_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarningsView extends StatelessWidget {
  EarningsView({super.key});

  final RequestController requestController = Get.find<RequestController>();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: requestController.getFixerBids(currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          final completedJobs = items.where((i) {
            final reqStatus = i['request'].status;
            final bidStatus = i['bid'].status;
            return (reqStatus == 'completed' || reqStatus == 'reviewed') && bidStatus == 'accepted';
          }).toList();
          
          double totalEarnings = 0;
          for (var item in completedJobs) {
            totalEarnings += (item['request'].finalPrice ?? 0);
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    const Text('Total Revenue', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('\$${totalEarnings.toStringAsFixed(2)}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${completedJobs.length} Jobs Completed', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: completedJobs.length,
                  itemBuilder: (context, index) {
                    final job = completedJobs[index]['request'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEEF2FF),
                          child: Icon(Icons.check_circle_rounded, color: Colors.green),
                        ),
                        title: Text(job.deviceType, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Completed on ${job.createdAt.day}/${job.createdAt.month}'),
                        trailing: Text('+\$${job.finalPrice}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
