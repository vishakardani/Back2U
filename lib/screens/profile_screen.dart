import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/claim_controller.dart';
import '../models/claim_model.dart';
import 'auth_screen.dart';
import 'item_detail_screen.dart'; // 👈 added

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final profileController = Get.put(ProfileController());
    final claimController = Get.put(ClaimController());

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Account', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          authController.logout();
                          Get.offAll(() => const AuthScreen());
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF0D9488),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF0D9488),
            isScrollable: true,
            tabs: [
              Tab(text: 'Profile'),
              Tab(text: 'My Posts'),
              Tab(text: 'Sent Claims'),
              Tab(text: 'Received'),
            ],
          ),
        ),
        body: Obx(() {
          final user = authController.user.value;
          final isAdmin = authController.isAdmin.value;

          if (user == null && !isAdmin) return const Center(child: CircularProgressIndicator());

          return TabBarView(
            children: [
              _buildProfileTab(authController),
              _buildMyPostsTab(profileController),
              _buildSentClaimsTab(claimController),
              _buildReceivedClaimsTab(claimController),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProfileTab(AuthController authController) {
    final user = authController.user.value;
    final admin = authController.admin.value;
    final isAdmin = authController.isAdmin.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF0D9488),
            child: Text(
              isAdmin ? admin!.fullName[0].toUpperCase() : user!.firstName[0].toUpperCase(),
              style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          _infoCard('Full Name', isAdmin ? admin!.fullName : user!.fullName, Icons.person_outline),
          _infoCard('Email Address', isAdmin ? admin!.email : user!.email, Icons.email_outlined),
          if (!isAdmin) ...[
            _infoCard('University ID', user!.universityId, Icons.badge_outlined),
            _infoCard('Phone Number', user.phone, Icons.phone_outlined),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D9488)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyPostsTab(ProfileController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.myItems.isEmpty) return _buildEmptyState('No items posted yet');

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.myItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = controller.myItems[index];
            return GestureDetector( // 👈 added
              onTap: () => Get.to(() => ItemDetailScreen(item: item)), // 👈 added
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.itemType == 'lost' ? Icons.search : Icons.inventory_2,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(item.location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isClaimed
                                ? Colors.green[50]
                                : (item.itemType == 'lost' ? Colors.red[50] : Colors.teal[50]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.isClaimed ? "CLAIMED" : item.itemType.toUpperCase(),
                            style: TextStyle(
                              color: item.isClaimed
                                  ? Colors.green
                                  : (item.itemType == 'lost' ? Colors.red : const Color(0xFF0D9488)),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _confirmDelete(controller, item.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _confirmDelete(ProfileController controller, String itemId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteMyItem(itemId);
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSentClaimsTab(ClaimController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchClaims(),
      child: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.myClaims.isEmpty) return _buildEmptyState('You haven\'t raised any claims');

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.myClaims.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final claim = controller.myClaims[index];
            return _buildClaimCard(claim, isSent: true);
          },
        );
      }),
    );
  }

  Widget _buildReceivedClaimsTab(ClaimController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchClaims(),
      child: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.receivedClaims.isEmpty) return _buildEmptyState('No claims received yet');

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.receivedClaims.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final claim = controller.receivedClaims[index];
            return _buildClaimCard(
              claim,
              isSent: false,
              onConfirm: () => _confirmAction(
                    () => controller.confirmClaim(claim.id),
                'Confirm Claim',
                'Are you sure you want to confirm this claim?',
              ),
              onReject: (reason) => controller.rejectClaim(claim.id, reason),
            );
          },
        );
      }),
    );
  }

  void _confirmAction(VoidCallback action, String title, String content) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              action();
              Get.back();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(Claim claim, {required bool isSent, VoidCallback? onConfirm, Function(String)? onReject}) {
    final statusColor = claim.status == 'confirmed'
        ? Colors.green
        : (claim.status == 'rejected' ? Colors.red : Colors.orange);

    return GestureDetector( // 👈 added
      onTap: claim.item != null // 👈 added
          ? () => Get.to(() => ItemDetailScreen(item: claim.item!))
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    claim.item?.itemName ?? 'Unknown Item',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    claim.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isSent)
              Text('To: ${claim.item?.user?.fullName ?? 'Owner'}', style: TextStyle(color: Colors.grey[600], fontSize: 13))
            else
              Text('From: ${claim.claimant?.fullName ?? 'Claimant'}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),

            if (claim.message != null && claim.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Message: ${claim.message}',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            if (claim.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Rejection Reason: ${claim.rejectionReason}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            if (!isSent && claim.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(onReject),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(Function(String)? onReject) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Reject Claim'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason (mandatory)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Reason is required');
                return;
              }
              onReject?.call(reasonController.text);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
