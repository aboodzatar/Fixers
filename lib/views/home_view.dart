import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_training/controllers/auth_controller.dart';
import 'package:firebase_training/controllers/home_controller.dart';
import 'package:firebase_training/controllers/request_controller.dart';
import 'package:firebase_training/models/bid_model.dart';
import 'package:firebase_training/models/request_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final HomeController homeController = Get.find<HomeController>();
  final AuthController authController = Get.find<AuthController>();
  final RequestController requestController = Get.find<RequestController>();

  void _showDeleteDialog(String requestId) {
    Get.defaultDialog(
      title: 'Delete Request?',
      middleText: 'Are you sure you want to remove this request?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        requestController.deleteRequest(requestId);
        Get.back();
      },
    );
  }

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

  void _showBidBottomSheet(String requestId) {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final RxBool canComeToYou = false.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Make an Offer",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  labelText: 'Your Price',
                  hintText: 'e.g. 50',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message to User',
                  hintText: 'Explain what you will do...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => Container(
                  decoration: BoxDecoration(
                    color:
                        canComeToYou.value
                            ? Colors.indigo.withValues(alpha: 0.05)
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          canComeToYou.value
                              ? Colors.indigo.withValues(alpha: 0.2)
                              : Colors.transparent,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      "I can come to you",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text("Mobile repair service"),
                    value: canComeToYou.value,
                    onChanged: (val) => canComeToYou.value = val ?? false,
                    activeColor: Colors.indigo,
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (priceController.text.isEmpty) return;
                    requestController.submitBid(
                      requestId: requestId,
                      price: double.parse(priceController.text),
                      message: messageController.text,
                      canComeToYou: canComeToYou.value,
                    );
                    Get.back();
                    Get.snackbar('Success', 'Your bid has been submitted!');
                  },
                  child: const Text('Send Offer'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildFixerDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: const Text(
              'Fixer Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(authController.userEmail.value),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.engineering_rounded,
                color: Colors.indigo,
                size: 32,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: Colors.indigo),
            title: const Text('Marketplace'),
            onTap: () => Get.back(),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_rounded, color: Colors.indigo),
            title: const Text('My Active Bids'),
            onTap: () {
              Get.back();
              Get.toNamed('/fixer_offers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.payments_rounded, color: Colors.indigo),
            title: const Text('Earnings'),
            onTap: () {
              Get.back();
              Get.toNamed('/earnings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded, color: Colors.indigo),
            title: const Text('My Profile'),
            onTap: () {
              Get.back();
              Get.toNamed('/profile');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => authController.logout(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUserDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: const Text(
              'My Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(authController.userEmail.value),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person_rounded,
                color: Colors.blue,
                size: 32,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: Colors.blue),
            title: const Text('Home'),
            onTap: () => Get.back(),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_rounded, color: Colors.blue),
            title: const Text('All Requests'),
            onTap: () {
              Get.back();
              Get.toNamed('/user_requests');
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline_rounded, color: Colors.blue),
            title: const Text('New Request'),
            onTap: () {
              Get.back();
              Get.toNamed('/add_request');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded, color: Colors.blue),
            title: const Text('Profile'),
            onTap: () {
              Get.back();
              Get.toNamed('/profile');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => authController.logout(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Slate 100
        drawer:
            authController.userRole.value == 'fixer'
                ? _buildFixerDrawer()
                : _buildUserDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF1E293B),
          title: Text(
            authController.userRole.value == 'fixer'
                ? 'FixIt Pro'
                : 'FixIt',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          actions: [
            IconButton(
              onPressed: () => authController.logout(),
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Obx(() {
          if (homeController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (homeController.errorMessage.isNotEmpty) {
            return Center(child: Text(homeController.errorMessage.value));
          }

          final isFixer = authController.userRole.value == 'fixer';
          List<RequestModel> displayedRequests = isFixer ? homeController.filteredMarketplace : homeController.requests;

          if (!isFixer && displayedRequests.length > 5) {
             displayedRequests = displayedRequests.sublist(0, 5);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Welcome Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                sliver: SliverToBoxAdapter(
                  child: isFixer ? _buildFixerHero() : _buildUserHero(),
                ),
              ),

              if (displayedRequests.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_mosaic_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isFixer ? 'Market is quiet... for now!' : 'No requests yet',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                if (!isFixer)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                          TextButton(
                            onPressed: () => Get.toNamed('/user_requests'),
                            child: const Text('View All'),
                          )
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final req = displayedRequests[index];
                      return _buildRequestCard(context, req, isFixer);
                    }, childCount: displayedRequests.length),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        }),
        floatingActionButton: Obx(
          () =>
              authController.userRole.value == 'user'
                  ? FloatingActionButton.extended(
                    onPressed: () => Get.toNamed('/add_request'),
                    label: const Text('New Request'),
                    icon: const Icon(Icons.add),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildFixerHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Market Status', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('Active Gigs', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.show_chart_rounded, color: Colors.greenAccent),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildHeroStat('Open', homeController.filteredMarketplace.length.toString(), Colors.blueAccent),
              const SizedBox(width: 24),
              _buildHeroStat('My Bids', homeController.myBidRequestIds.length.toString(), Colors.amberAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildUserHero() {
    final userRequests = homeController.requests;
    final pendingCount = userRequests.where((r) => r.status == 'pending').length;
    final completedCount = userRequests.where((r) => r.status == 'completed' || r.status == 'reviewed').length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good morning! 👋', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('My Repairs', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.build_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildHeroStat('Pending', pendingCount.toString(), Colors.orangeAccent),
              const SizedBox(width: 24),
              _buildHeroStat('Completed', completedCount.toString(), Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, RequestModel req, bool isFixer) {
    final isAccepted = req.status == 'accepted';
    final isDone = req.status == 'completed' || req.status == 'reviewed';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // Header with Icon & Status
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(req.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_getDeviceIcon(req.deviceType), color: _getStatusColor(req.status)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.deviceType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        'Posted ${DateFormat.jm().format(req.createdAt)}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildCompactStatus(req.status),
              ],
            ),
          ),

          // Issue Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              req.issueDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
          ),

          // Images if any
          if (req.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: req.imageUrls.length,
                  itemBuilder: (context, i) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: NetworkImage(req.imageUrls[i]), fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),
          const Divider(height: 1),

          // Action Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (isFixer && req.status == 'pending')
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showBidBottomSheet(req.id!),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Make an Offer'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (!isFixer && req.status == 'pending')
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => Get.toNamed('/bids', arguments: req),
                            icon: const Icon(Icons.list_alt_rounded),
                            label: const Text('View Bids'),
                            style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showDeleteDialog(req.id!),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                if (isAccepted || req.status == 'in_progress' || isDone)
                   Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.toNamed('/chat', arguments: {
                            'requestId': req.id,
                            'chatTitle': isFixer ? 'Customer' : req.acceptedFixerName ?? 'Fixer',
                          }),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.indigo),
                        ),
                        const Spacer(),
                        if (isFixer && isAccepted)
                          _buildCardAction('Start Job', Colors.indigo, () => requestController.updateRequestStatus(req.id!, 'in_progress')),
                        if (isFixer && req.status == 'in_progress')
                          _buildCardAction('Complete', Colors.green, () => requestController.updateRequestStatus(req.id!, 'completed')),
                        if (!isFixer && req.status == 'completed')
                          _buildCardAction('Rate Fixer', Colors.amber, () => _showRatingDialog(req)),
                        if (isAccepted || isDone)
                           Padding(
                             padding: const EdgeInsets.only(left: 12),
                             child: Text('\$${req.finalPrice}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                           ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAction(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCompactStatus(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
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

  IconData _getDeviceIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('phone')) return Icons.smartphone_rounded;
    if (t.contains('laptop') || t.contains('computer')) return Icons.laptop_mac_rounded;
    if (t.contains('watch')) return Icons.watch_rounded;
    if (t.contains('tablet')) return Icons.tablet_mac_rounded;
    return Icons.settings_suggest_rounded;
  }
}
