import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';
import 'home_controller.dart';

class PostController extends GetxController {
  final authController = Get.find<AuthController>();
  final ImagePicker _picker = ImagePicker();

  final RxString itemType = 'lost'.obs;
  final RxString selectedCategoryId = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploadingImage = false.obs;

  // Local files selected by user
  final RxList<File> localImages = <File>[].obs;

  // Uploaded image metadata to send in createItem
  final RxList<Map<String, dynamic>> uploadedImages = <Map<String, dynamic>>[].obs;

  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB

  void resetForm() {
    itemType.value = 'lost';
    selectedCategoryId.value = '';
    localImages.clear();
    uploadedImages.clear();
  }

  void toggleItemType() {
    itemType.value = itemType.value == 'lost' ? 'found' : 'lost';
  }

  void setCategory(String categoryId) {
    selectedCategoryId.value = categoryId;
  }

  // === IMAGE PICK / COMPRESS / UPLOAD ===

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      File imageFile = File(pickedFile.path);
      final size = await imageFile.length();

      if (size > maxFileSizeInBytes) {
        final compressed = await _compressImage(imageFile);
        if (compressed == null) {
          Get.snackbar(
            'Error',
            'Failed to compress image. Please choose a smaller image.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        final compressedSize = await compressed.length();
        if (compressedSize > maxFileSizeInBytes) {
          Get.snackbar(
            'Error',
            'Image too large. Max size is 5MB.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        imageFile = compressed;
      }

      localImages.add(imageFile);

      Get.snackbar(
        'Image added',
        'It will be uploaded when you post the item.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0D9488),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize if needed
      int w = image.width;
      int h = image.height;
      if (w > 1920 || h > 1920) {
        if (w > h) {
          h = (h * 1920 / w).round();
          w = 1920;
        } else {
          w = (w * 1920 / h).round();
          h = 1920;
        }
        image = img.copyResize(image, width: w, height: h);
      }

      final compressedBytes = img.encodeJpg(image, quality: 75);
      final dir = await getTemporaryDirectory();
      final outFile = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg');
      await outFile.writeAsBytes(compressedBytes);
      return outFile;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _uploadImages() async {
    if (localImages.isEmpty) return true;

    try {
      isUploadingImage.value = true;
      uploadedImages.clear();

      for (final file in localImages) {
        final res = await ApiService.uploadImage(
          token: authController.token.value,
          imageFile: file,
        );

        if (res['success'] == true && res['image'] != null) {
          // Expecting backend to return something like { file_id, url, thumbnail_url }
          uploadedImages.add(res['image'] as Map<String, dynamic>);
        }
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Upload Error',
        'Failed to upload images: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isUploadingImage.value = false;
    }
  }

  void removeLocalImage(int index) {
    if (index >= 0 && index < localImages.length) {
      localImages.removeAt(index);
    }
  }

  void showImageSourceDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0D9488)),
                title: const Text('Camera'),
                onTap: () {
                  Get.back();
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0D9488)),
                title: const Text('Gallery'),
                onTap: () {
                  Get.back();
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === CREATE / UPDATE ITEM ===

  Future<bool> createItem({
    required String categoryId,
    required String itemName,
    String? description,
    required String location,
    required String dateLostFound,
  }) async {
    try {
      isLoading.value = true;

      if (localImages.isNotEmpty) {
        await _uploadImages();
      }

      final res = await ApiService.createItem(
        token: authController.token.value,
        categoryId: categoryId,
        itemType: itemType.value,
        itemName: itemName,
        description: description,
        location: location,
        dateLostFound: dateLostFound,
        images: uploadedImages.isNotEmpty ? uploadedImages : null,
      );

      if (res['success'] == true) {
        Get.snackbar(
          'Success',
          'Item posted successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0D9488),
          colorText: Colors.white,
        );

        resetForm();

        try {
          final home = Get.find<HomeController>();
          home.fetchItems();
        } catch (_) {}

        return true;
      }

      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to post item: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateItem({
    required String itemId,
    String? categoryId,
    String? itemName,
    String? description,
    String? location,
    String? dateLostFound,
    bool? isClaimed,
  }) async {
    try {
      isLoading.value = true;

      if (localImages.isNotEmpty) {
        await _uploadImages();
      }

      final data = <String, dynamic>{};
      if (categoryId != null) data['category_id'] = categoryId;
      if (itemName != null) data['item_name'] = itemName;
      if (description != null) data['description'] = description;
      if (location != null) data['location'] = location;
      if (dateLostFound != null) data['date_lost_found'] = dateLostFound;
      if (isClaimed != null) {
        data['is_claimed'] = isClaimed;
        if (isClaimed) data['claimed_at'] = DateTime.now().toIso8601String();
      }
      if (uploadedImages.isNotEmpty) {
        data['images'] = uploadedImages;
      }

      final res = await ApiService.updateItem(
        token: authController.token.value,
        itemId: itemId,
        data: data,
      );

      if (res['success'] == true) {
        Get.snackbar(
          'Success',
          'Item updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0D9488),
          colorText: Colors.white,
        );

        try {
          final home = Get.find<HomeController>();
          home.fetchItems();
        } catch (_) {}

        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update item: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
