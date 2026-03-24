import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

class HomeController extends GetxController {
  final authController = Get.find<AuthController>();

  final RxList<UniversityItem> items = <UniversityItem>[].obs;
  final RxList<Category> categories = <Category>[].obs;
  final Rx<AdminStats?> adminStats = Rx<AdminStats?>(null);

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategoryId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([
      fetchItems(),
      fetchCategories(),
      if (authController.isAdmin.value) fetchAdminStats(),
    ]);
  }

  Future<void> refresh() async {
    try {
      isRefreshing.value = true;
      await loadData();
    } catch (e) {
      Get.snackbar(
        'Refresh Failed',
        'Failed to refresh data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> fetchItems() async {
    try {
      isLoading.value = true;

      String? type;
      if (selectedFilter.value == 'lost') type = 'lost';
      if (selectedFilter.value == 'found') type = 'found';

      String? categoryId;
      if (selectedCategoryId.value.isNotEmpty && selectedCategoryId.value != 'all') {
        categoryId = selectedCategoryId.value;
      }



      // Hide claimed items from the main feed
      final fetchedItems = await ApiService.getItems(
        type: type,
        categoryId: categoryId,
        claimed: 'false',
      );
      items.value = fetchedItems;
      print('Fetched items: $fetchedItems');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load items: ${_parseError(e)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await ApiService.getCategories();
      categories.value = fetchedCategories;
    } catch (e) {
      print('Failed to load categories: $e');
    }
  }

  Future<void> fetchAdminStats() async {
    try {
      final stats = await ApiService.getAdminStats(authController.token.value);
      adminStats.value = stats;
    } catch (e) {
      print('Failed to load stats: $e');
    }
  }

  void setFilter(String filter) {
    if (selectedFilter.value == filter) return;
    selectedFilter.value = filter;
    fetchItems();
  }

  void setCategoryFilter(String categoryId) {
    selectedCategoryId.value = categoryId;
    fetchItems();
  }

  void searchItems(String query) {
    searchQuery.value = query.toLowerCase();
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  List<UniversityItem> get filteredItems {
    var filtered = items.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((item) {
        final itemName = item.itemName.toLowerCase();
        final description = item.description?.toLowerCase() ?? '';
        final location = item.location.toLowerCase();
        final query = searchQuery.value;

        return itemName.contains(query) ||
            description.contains(query) ||
            location.contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await ApiService.deleteItem(
        token: authController.token.value,
        itemId: itemId,
      );

      items.removeWhere((item) => item.id == itemId);

      Get.snackbar(
        'Success',
        'Item deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0D9488),
        colorText: Colors.white,
      );

      // Refresh stats if admin
      if (authController.isAdmin.value) {
        fetchAdminStats();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete item: ${_parseError(e)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _parseError(dynamic error) {
    String errorMsg = error.toString();
    if (errorMsg.startsWith('Exception: ')) {
      errorMsg = errorMsg.substring(11);
    }
    return errorMsg;
  }
}
