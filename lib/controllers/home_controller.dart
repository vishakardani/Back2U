import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../models/auth_model.dart';
import '../services/api_service.dart';
import '../controllers/auth_controller.dart';

class HomeController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  // Reactive Lists
  final RxList<UniversityItem> items = <UniversityItem>[].obs;
  final RxList<Category> categories = <Category>[].obs;

  // Nullable reactive object
  final Rxn<AdminStats> adminStats = Rxn<AdminStats>();

  // States
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  // Filters
  final RxString selectedFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategoryId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  // =========================
  // LOAD ALL DATA
  // =========================
  Future<void> loadData() async {
    try {
      List<Future> futures = [fetchItems(), fetchCategories()];

      if (authController.isAdmin.value) {
        futures.add(fetchAdminStats());
      }

      await Future.wait(futures);
    } catch (e) {
      debugPrint('Load data error: $e');
    }
  }

  // =========================
  // REFRESH DATA
  // =========================
  Future<void> refreshData() async {
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

  // =========================
  // FETCH ITEMS
  // =========================
  Future<void> fetchItems() async {
    try {
      isLoading.value = true;

      String? type;

      if (selectedFilter.value == 'lost') {
        type = 'lost';
      } else if (selectedFilter.value == 'found') {
        type = 'found';
      }

      String? categoryId;

      if (selectedCategoryId.value.isNotEmpty &&
          selectedCategoryId.value != 'all') {
        categoryId = selectedCategoryId.value;
      }

      final fetchedItems = await ApiService.getItems(
        type: type,
        categoryId: categoryId,
        claimed: 'false',
      );

      items.assignAll(fetchedItems);
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

  // =========================
  // FETCH CATEGORIES
  // =========================
  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await ApiService.getCategories();
      categories.assignAll(fetchedCategories);
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  // =========================
  // FETCH ADMIN STATS
  // =========================
  Future<void> fetchAdminStats() async {
    try {
      final stats = await ApiService.getAdminStats(authController.token.value);

      adminStats.value = stats;
    } catch (e) {
      debugPrint('Failed to load admin stats: $e');
    }
  }

  // =========================
  // FILTERS
  // =========================
  void setFilter(String filter) {
    if (selectedFilter.value == filter) return;

    selectedFilter.value = filter;
    fetchItems();
  }

  void setCategoryFilter(String categoryId) {
    selectedCategoryId.value = categoryId;
    fetchItems();
  }

  // =========================
  // SEARCH
  // =========================
  void searchItems(String query) {
    searchQuery.value = query.toLowerCase();
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  // =========================
  // FILTERED ITEMS
  // =========================
  List<UniversityItem> get filteredItems {
    List<UniversityItem> filtered = items.toList();

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

  // =========================
  // DELETE ITEM
  // =========================
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

  // =========================
  // ERROR PARSER
  // =========================
  String _parseError(dynamic error) {
    String errorMsg = error.toString();

    if (errorMsg.startsWith('Exception: ')) {
      errorMsg = errorMsg.substring(11);
    }

    return errorMsg;
  }
}
