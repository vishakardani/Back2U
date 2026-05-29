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
    // Attempt to find controllers, but don't force a rebuild cycle on them
    // using Obx directly at the top level of the build.
    final authController = Get.find<AuthController>();
    
    // We use a GetBuilder or a conditional check to ensure we don't 
    // try to access controllers that are being disposed.
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (homeController) {
        return Obx(() {
          // If the auth token is cleared, don't try to render the screen
          if (authController.token.value.isEmpty) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          return Scaffold(
            body: RefreshIndicator(
              onRefresh: () async => await homeController.refreshData(),
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
                      const Text("See All", style: TextStyle(color: Color(0xFF0D9488), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (homeController.isLoading.value)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF0D9488))))
                  else if (homeController.filteredItems.isEmpty)
                    _buildEmptyState()
                  else
                    ...homeController.filteredItems.map((item) => _buildCard(item, authController.isAdmin.value, homeController)),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // --- Helper Methods ---

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No items found', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(HomeController controller) {
    final stats = controller.adminStats.value;
    if (stats == null) return const SizedBox.shrink();
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
  }

  Widget _statBox(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(HomeController controller) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: TextField(
        onChanged: (value) => controller.searchItems(value),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          hintText: "What did you lose?",
          border: InputBorder.none,
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => controller.clearSearch())
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
                  border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[300]!),
                ),
                child: Center(child: Text(filter.capitalizeFirst!, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13))),
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
    try { formattedDate = dateFormat.format(DateTime.parse(item.dateLostFound)); } catch (e) { formattedDate = item.dateLostFound; }

    return GestureDetector(
      onTap: () => Get.to(() => ItemDetailScreen(item: item)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: item.images.isNotEmpty
                      ? CachedNetworkImage(imageUrl: item.images.first.thumbnailUrl, height: 180, width: double.infinity, fit: BoxFit.cover, errorWidget: (a, b, c) => _buildNoImagePlaceholder(item))
                      : _buildNoImagePlaceholder(item),
                ),
                Positioned(top: 16, left: 16, child: _typeTag(item.itemType)),
                if (item.isClaimed) Positioned(top: 16, right: isAdmin ? 80 : 16, child: _claimedTag()),
                if (isAdmin) Positioned(top: 16, right: 16, child: _adminTool(Icons.delete_outline, Colors.red, () => controller.deleteItem(item.id))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.itemName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(item.description ?? 'No description', style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF0D9488)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(item.location, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    Text(formattedDate, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeTag(String type) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: type == 'found' ? const Color(0xFF0D9488) : const Color(0xFFE11D48), borderRadius: BorderRadius.circular(20)),
      child: Text(type.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)));

  Widget _claimedTag() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
      child: const Text('CLAIMED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)));

  Widget _adminTool(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
      onTap: () => Get.defaultDialog(title: 'Delete Item', middleText: 'Delete?', onConfirm: () { onTap(); Get.back(); }, textConfirm: 'Delete'),
      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 18)));

  Widget _buildNoImagePlaceholder(UniversityItem item) => Container(
      height: 180, width: double.infinity, color: Colors.grey[100],
      child: Icon(CategoryIconMapper.fromName(item.category?.iconName), size: 48, color: Colors.grey[500]));
}
