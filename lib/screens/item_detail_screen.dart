import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:unifound/utils/category_icon_mapper.dart';
import '../models/item_model.dart';
import '../controllers/auth_controller.dart';
import '../controllers/claim_controller.dart';
import '../controllers/home_controller.dart';
import '../services/api_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final UniversityItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final authController = Get.find<AuthController>();
  final claimController = Get.find<ClaimController>();
  List<UniversityItem> relatedItems = [];
  bool isLoadingRelated = false;

  @override
  void initState() {
    super.initState();
    _fetchRelatedItems();
    // 👇 Ensure claims are loaded so receivedClaims is populated
    claimController.fetchClaims();
  }

  Future<void> _fetchRelatedItems() async {
    setState(() => isLoadingRelated = true);
    try {
      final items = await ApiService.getRelatedItems(widget.item.id);
      setState(() => relatedItems = items);
    } catch (e) {
      print('Error fetching related items: $e');
    } finally {
      setState(() => isLoadingRelated = false);
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteItem(
          token: authController.token.value,
          itemId: widget.item.id,
        );
        Get.snackbar('Success', 'Item deleted successfully',
            backgroundColor: const Color(0xFF0D9488), colorText: Colors.white);
        try {
          Get.find<HomeController>().fetchItems();
        } catch (_) {}
        Get.back();
      } catch (e) {
        Get.snackbar('Error', 'Failed to delete item: $e',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    String formattedDate = 'N/A';
    try {
      formattedDate = dateFormat.format(DateTime.parse(widget.item.dateLostFound));
    } catch (_) {
      formattedDate = widget.item.dateLostFound;
    }

    final isOwner = authController.userId == widget.item.userId;
    final isAdmin = authController.isAdmin.value;
    final canClaim = !isOwner && widget.item.itemType == 'found' && !widget.item.isClaimed;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              if (isOwner || isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: _deleteItem,
                  style: IconButton.styleFrom(backgroundColor: Colors.black26),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.item.images.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: widget.item.images.first.url,
                fit: BoxFit.cover,
              )
                  : _buildNoImagePlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type + Category Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.item.itemType == 'found'
                              ? const Color(0xFF0D9488)
                              : const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.item.itemType.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.item.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.item.category!.name.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF0D9488), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Item Name
                  Text(
                    widget.item.itemName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Location + Date
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF0D9488)),
                      const SizedBox(width: 4),
                      Text(widget.item.location, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                      const Spacer(),
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 40),

                  // Description
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description ?? "No description provided.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
                  ),
                  const Divider(height: 40),

                  // Posted By
                  _buildUserInfo(),

                  // 👇 Owner: show claims list | Non-owner: show raise claim button
                  if (isOwner)
                    _buildOwnerClaimsSection()
                  else if (canClaim)
                    _buildRaiseClaimButton(),

                  // Related Items
                  if (relatedItems.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    Text(
                      widget.item.itemType == 'lost'
                          ? "Potential Matches Found"
                          : "Potential Owners (Lost Posts)",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildRelatedItems(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👇 New: Owner's claim list section
  Widget _buildOwnerClaimsSection() {
    return Obx(() {
      final itemClaims = claimController.receivedClaims
          .where((c) => c.item?.id == widget.item.id)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Row(
            children: [
              const Text(
                "Claims Received",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (itemClaims.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${itemClaims.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (claimController.isLoading.value)
            const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          else if (itemClaims.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No claims raised yet',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemClaims.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final claim = itemClaims[index];
                final statusColor = claim.status == 'confirmed'
                    ? Colors.green
                    : (claim.status == 'rejected' ? Colors.red : Colors.orange);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Claimant Info + Status
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.teal[50],
                            child: Text(
                              claim.claimant?.fullName[0].toUpperCase() ?? '?',
                              style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  claim.claimant?.fullName ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  claim.claimant?.email ?? '',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              claim.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Claim Message
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
                            '"${claim.message}"',
                            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],

                      // Rejection Reason
                      if (claim.rejectionReason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Rejection Reason: ${claim.rejectionReason}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],

                      // Confirm / Reject Buttons (only for pending)
                      if (claim.status == 'pending') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showRejectDialog(
                                      (reason) => claimController.rejectClaim(claim.id, reason),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _confirmAction(
                                      () => claimController.confirmClaim(claim.id),
                                  'Confirm Claim',
                                  'Are you sure you want to confirm this claim?',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Confirm'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      );
    });
  }

  // 👇 Non-owner raise claim button (extracted from build)
  Widget _buildRaiseClaimButton() {
    return Obx(() {
      final alreadyClaimed = claimController.hasClaimed(widget.item.id);
      final isLoading = claimController.isLoading.value;

      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: (alreadyClaimed || isLoading) ? null : () => _showClaimDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: alreadyClaimed ? Colors.grey : const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
              alreadyClaimed ? "Claim Raised" : "Raise Claim",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildUserInfo() {
    if (widget.item.user == null) return const SizedBox.shrink();
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.teal[50],
          child: Text(
            widget.item.user!.firstName[0],
            style: const TextStyle(color: Color(0xFF0D9488)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.user!.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.item.user!.email ?? "No email",
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildRelatedItems() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: relatedItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = relatedItems[index];
          return GestureDetector(
            onTap: () => Get.to(() => ItemDetailScreen(item: item), preventDuplicates: false),
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.images.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: item.images.first.thumbnailUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[100],
                      child: Icon(
                        CategoryIconMapper.fromName(item.category?.iconName),
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(item.location,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          CategoryIconMapper.fromName(widget.item.category?.iconName),
          size: 80,
          color: Colors.grey[300],
        ),
      ),
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

  void _showRejectDialog(Function(String) onReject) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              onReject(reasonController.text);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showClaimDialog() {
    final messageController = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Raise a Claim"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want to raise a claim for this item? Provide some details or proof that this item belongs to you.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "E.g. The wallpaper is a cat, or it has a scratch on the left side.",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              claimController.raiseClaim(widget.item.id, messageController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm Claim"),
          ),
        ],
      ),
    );
  }
}
