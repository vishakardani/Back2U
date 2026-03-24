import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:unifound/utils/category_icon_mapper.dart';
import '../controllers/home_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/item_model.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.put(HomeController());
    final authController = Get.find<AuthController>();

    return Obx(() => RefreshIndicator(
      onRefresh: () => homeController.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (authController.isAdmin.value) _buildStats(homeController),

          _buildSearch(homeController),
          const SizedBox(height: 24),

          _buildFilters(homeController),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                authController.isAdmin.value ? "System Logs" : "Latest Findings",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const Text(
                "See All",
                style: TextStyle(color: Color(0xFF0D9488), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (homeController.isLoading.value)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xFF0D9488)),
              ),
            )
          else if (homeController.filteredItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No items found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ...homeController.filteredItems.map(
                  (item) => _buildCard(item, authController.isAdmin.value, homeController),
            ),
        ],
      ),
    ));
  }

  Widget _buildStats(HomeController controller) {
    return Obx(() {
      final stats = controller.adminStats.value;

      if (stats == null) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(32),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF0D9488)),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            _statBox("${stats.lostItems + stats.foundItems}", "ITEMS", Icons.inventory_2_outlined, Colors.teal),
            const SizedBox(width: 12),
            _statBox("${stats.totalUsers}", "USERS", Icons.group_outlined, Colors.blue),
            const SizedBox(width: 12),
            _statBox("${stats.claimedItems}", "CLAIMED", Icons.check_circle_outline, Colors.green),
          ],
        ),
      );
    });
  }

  Widget _statBox(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text(
              label,
              style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(HomeController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextField(
        onChanged: (value) => controller.searchItems(value),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          hintText: "What did you lose?",
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () => controller.clearSearch(),
          )
              : const SizedBox.shrink()),
        ),
      ),
    );
  }

  Widget _buildFilters(HomeController controller) {
    final filters = ["all", "found", "lost"];

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];

          return Obx(() {
            final isSelected = controller.selectedFilter.value == filter;

            return GestureDetector(
              onTap: () => controller.setFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D9488) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey[300]!,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    filter[0].toUpperCase() + filter.substring(1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildCard(UniversityItem item, bool isAdmin, HomeController controller) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    String formattedDate = 'N/A';

    try {
      formattedDate = dateFormat.format(DateTime.parse(item.dateLostFound));
    } catch (e) {
      formattedDate = item.dateLostFound;
    }

    return GestureDetector(
      onTap: () => Get.to(() => ItemDetailScreen(item: item)),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                // Image or placeholder
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: item.images.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: item.images.first.thumbnailUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0D9488),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildNoImagePlaceholder(item),
                  )
                      : _buildNoImagePlaceholder(item),

                ),

                // Lost/Found Badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.itemType == 'found' ? const Color(0xFF0D9488) : const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (item.itemType == 'found' ? const Color(0xFF0D9488) : const Color(0xFFE11D48))
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      item.itemType.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Claimed Badge
                if (item.isClaimed)
                  Positioned(
                    top: 16,
                    right: isAdmin ? 80 : 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'CLAIMED',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Admin Delete Button
                if (isAdmin)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _adminTool(Icons.delete_outline, Colors.red, () {
                          Get.dialog(
                            AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Delete Item'),
                              content: const Text('Are you sure you want to delete this item?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    controller.deleteItem(item.id);
                                    Get.back();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),

            // Item Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.category!.name.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF0D9488),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description ?? 'No description',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF0D9488)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (item.user != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Posted by ${item.user!.firstName} ${item.user!.lastName}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
                              ),
                              if (item.user!.email != null)
                                Text(
                                  item.user!.email!,
                                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Add this new method for the no-image placeholder
  Widget _buildNoImagePlaceholder(UniversityItem item) {
    // Fallback to category icon; if null, use generic category icon
    final iconData = CategoryIconMapper.fromName(item.category?.iconName);

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              iconData,
              size: 48,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.category?.name ?? 'No Image',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  Widget _adminTool(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
