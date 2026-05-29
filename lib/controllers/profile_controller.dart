import 'package:get/get.dart';
import 'package:unifound/controllers/auth_controller.dart';
import 'package:unifound/models/item_model.dart';
import 'package:unifound/services/api_service.dart';

class ProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final isLoading = false.obs;
  final myItems = <UniversityItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyItems();
  }

  /// Fetches items posted by the current logged-in user
  Future<void> fetchMyItems() async {
    try {
      isLoading.value = true;
      
      // Added .value here to extract the raw String from the GetX observable
      final token = _authController.token.value; 
      
      final items = await ApiService.getUserItems(token: token);
      myItems.assignAll(items);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load items: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Deletes a specific item and updates the UI list locally
  Future<void> deleteMyItem(String itemId) async {
    try {
      // Added .value here as well
      final token = _authController.token.value; 
      
      await ApiService.deleteItem(token: token, itemId: itemId);
      myItems.removeWhere((item) => item.id == itemId);
      
      Get.snackbar(
        'Success',
        'Post deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete item: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
