import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/post_controller.dart';
import '../controllers/home_controller.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final postController = Get.put(PostController());
  final homeController = Get.find<HomeController>();

  final itemNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  void _handlePost() async {
    if (itemNameController.text.isEmpty ||
        locationController.text.isEmpty ||
        postController.selectedCategoryId.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // ✅ Photo mandatory for found items
    if (postController.itemType.value == 'found' &&
        postController.localImages.isEmpty) {
      Get.snackbar(
        'Error',
        'Please upload at least one photo for a found item',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final success = await postController.createItem(
      categoryId: postController.selectedCategoryId.value,
      itemName: itemNameController.text,
      description: descriptionController.text.isEmpty ? null : descriptionController.text,
      location: locationController.text,
      dateLostFound: DateFormat('yyyy-MM-dd').format(selectedDate),
    );

    if (success) {
      itemNameController.clear();
      descriptionController.clear();
      locationController.clear();
      homeController.fetchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Item'),
        elevation: 0,
      ),
      body: Obx(() => Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Type Toggle
                Row(
                  children: [
                    _typeButton('Lost', 'lost'),
                    const SizedBox(width: 16),
                    _typeButton('Found', 'found'),
                  ],
                ),

                const SizedBox(height: 24),

                // ✅ Dynamic label based on item type
                Obx(() => Text(
                  postController.itemType.value == 'found'
                      ? 'Item Photos *'
                      : 'Item Photos (Optional)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
                const SizedBox(height: 8),
                _buildImageSection(),

                const SizedBox(height: 24),

                // Category Selection
                const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: postController.selectedCategoryId.value.isEmpty
                      ? null
                      : postController.selectedCategoryId.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: const Text('Select category'),
                  items: homeController.categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      postController.selectedCategoryId.value = value;
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Item Name
                const Text('Item Name *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: itemNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Black Wallet',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),

                const SizedBox(height: 24),

                // Description
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Provide details...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 24),

                // Location
                const Text('Location *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Library 2nd Floor',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),

                const SizedBox(height: 24),

                // Date
                const Text('Date *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: postController.isLoading.value ? null : _handlePost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: postController.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('POST ITEM', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Upload overlay
          if (postController.isUploadingImage.value)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Uploading images...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      )),
    );
  }

  Widget _buildImageSection() {
    return Obx(() {
      return Column(
        children: [
          // Display selected images
          if (postController.localImages.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: postController.localImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            postController.localImages[index],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => postController.removeLocalImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // Add image button
          if (postController.localImages.length < 5)
            GestureDetector(
              onTap: () => postController.showImageSourceDialog(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    // ✅ Red border hint when found type and no image selected
                    color: postController.itemType.value == 'found' &&
                        postController.localImages.isEmpty
                        ? Colors.red
                        : const Color(0xFF0D9488),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: postController.itemType.value == 'found' &&
                      postController.localImages.isEmpty
                      ? Colors.red.withOpacity(0.04)
                      : const Color(0xFF0D9488).withOpacity(0.05),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      color: postController.itemType.value == 'found' &&
                          postController.localImages.isEmpty
                          ? Colors.red
                          : const Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Photo (Max 5MB)',
                      style: TextStyle(
                        color: postController.itemType.value == 'found' &&
                            postController.localImages.isEmpty
                            ? Colors.red
                            : const Color(0xFF0D9488),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ✅ Required hint for found items
          if (postController.itemType.value == 'found' &&
              postController.localImages.isEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.red),
                const SizedBox(width: 6),
                Text(
                  'Photo is required for found items',
                  style: TextStyle(fontSize: 12, color: Colors.red[600]),
                ),
              ],
            ),
          ],

          if (postController.localImages.length >= 5)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Maximum 5 images allowed',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _typeButton(String label, String type) {
    return Expanded(
      child: Obx(() {
        final isSelected = postController.itemType.value == type;
        return GestureDetector(
          onTap: () => postController.itemType.value = type,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0D9488) : Colors.white,
              border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
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
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    itemNameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
