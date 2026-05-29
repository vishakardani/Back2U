import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/post_controller.dart';
import '../models/item_model.dart';

class PostScreen extends StatelessWidget {
  PostScreen({super.key});

  final PostController controller =
      Get.put(PostController());

  final HomeController homeController =
      Get.find<HomeController>();

  final TextEditingController itemNameController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  final TextEditingController locationController =
      TextEditingController();

  final TextEditingController dateController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Obx(() {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // =========================
                // HEADER
                // =========================

                const Center(
                  child: Column(
                    children: [

                      Text(
                        'Post Item',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        'Help someone recover their belongings',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // =========================
                // LOST / FOUND TOGGLE
                // =========================

                Container(
                  padding: const EdgeInsets.all(4),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),

                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      // LOST
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            controller.itemType.value =
                                'lost';
                          },

                          child: AnimatedContainer(
                            duration:
                                const Duration(
                                    milliseconds: 200),

                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),

                            decoration: BoxDecoration(
                              color:
                                  controller.itemType.value ==
                                          'lost'
                                      ? const Color(
                                          0xFF0D9488)
                                      : Colors.transparent,

                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                            ),

                            child: Text(
                              'Lost',
                              textAlign:
                                  TextAlign.center,

                              style: TextStyle(
                                color:
                                    controller.itemType
                                                .value ==
                                            'lost'
                                        ? Colors.white
                                        : Colors.black87,

                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // FOUND
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            controller.itemType.value =
                                'found';
                          },

                          child: AnimatedContainer(
                            duration:
                                const Duration(
                                    milliseconds: 200),

                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),

                            decoration: BoxDecoration(
                              color:
                                  controller.itemType.value ==
                                          'found'
                                      ? const Color(
                                          0xFF0D9488)
                                      : Colors.transparent,

                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                            ),

                            child: Text(
                              'Found',
                              textAlign:
                                  TextAlign.center,

                              style: TextStyle(
                                color:
                                    controller.itemType
                                                .value ==
                                            'found'
                                        ? Colors.white
                                        : Colors.black87,

                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // =========================
                // IMAGE PICKER
                // =========================

                const Text(
                  'Item Photos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 12),

                GestureDetector(
                  onTap:
                      controller.showImageSourceDialog,

                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 22,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(18),

                      border: Border.all(
                        color: const Color(
                            0xFF0D9488),
                        width: 1.5,
                      ),
                    ),

                    child: Column(
                      children: [

                        const Icon(
                          Icons.add_a_photo_outlined,
                          color: Color(0xFF0D9488),
                          size: 30,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          controller.localImages.isEmpty
                              ? 'Add Photo (Max 5MB)'
                              : 'Add More Photos',

                          style: const TextStyle(
                            color: Color(0xFF0D9488),
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // IMAGE PREVIEW
                if (controller.localImages.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 16),

                    child: SizedBox(
                      height: 100,

                      child: ListView.builder(
                        scrollDirection:
                            Axis.horizontal,

                        itemCount:
                            controller.localImages
                                .length,

                        itemBuilder: (context, index) {
                          File image = controller
                              .localImages[index];

                          return Stack(
                            children: [

                              Container(
                                margin:
                                    const EdgeInsets.only(
                                  right: 12,
                                ),

                                width: 100,
                                height: 100,

                                decoration:
                                    BoxDecoration(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              16),

                                  image:
                                      DecorationImage(
                                    image:
                                        FileImage(image),

                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              Positioned(
                                top: 6,
                                right: 18,

                                child: GestureDetector(
                                  onTap: () {
                                    controller
                                        .removeLocalImage(
                                            index);
                                  },

                                  child: Container(
                                    padding:
                                        const EdgeInsets
                                            .all(4),

                                    decoration:
                                        const BoxDecoration(
                                      color: Colors.red,
                                      shape:
                                          BoxShape.circle,
                                    ),

                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color:
                                          Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 26),

                // =========================
                // CATEGORY
                // =========================

                const Text(
                  'Category',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                  ),

                  child: DropdownButtonFormField<String>(
                    value: controller
                            .selectedCategoryId
                            .value
                            .isEmpty
                        ? null
                        : controller
                            .selectedCategoryId
                            .value,

                    decoration: InputDecoration(
                      hintText: 'Select category',
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),

                    items: homeController.categories
                        .map<
                            DropdownMenuItem<
                                String>>(
                      (Category category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      },
                    ).toList(),

                    onChanged: (value) {
                      if (value != null) {
                        controller.setCategory(
                            value);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 22),

                // ITEM NAME
                _buildTextField(
                  controller: itemNameController,
                  hint: 'e.g. Black Wallet',
                  title: 'Item Name',
                ),

                const SizedBox(height: 22),

                // DESCRIPTION
                _buildTextField(
                  controller:
                      descriptionController,

                  hint: 'Provide details...',

                  title: 'Description',

                  maxLines: 4,
                ),

                const SizedBox(height: 22),

                // LOCATION
                _buildTextField(
                  controller: locationController,
                  hint: 'Where was it lost/found?',
                  title: 'Location',
                ),

                const SizedBox(height: 22),

                // DATE
                GestureDetector(
                  onTap: () async {
                    DateTime? picked =
                        await showDatePicker(
                      context: context,

                      initialDate:
                          DateTime.now(),

                      firstDate: DateTime(2020),

                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {
                      dateController.text =
                          picked
                              .toString()
                              .split(' ')[0];
                    }
                  },

                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: dateController,
                      hint: 'Select date',
                      title: 'Date',
                    ),
                  ),
                ),

                const SizedBox(height: 34),

                // =========================
                // SUBMIT BUTTON
                // =========================

                SizedBox(
                  width: double.infinity,
                  height: 58,

                  child: ElevatedButton(
                    onPressed:
                        controller.isLoading.value
                            ? null
                            : () async {

                                if (controller
                                    .selectedCategoryId
                                    .value
                                    .isEmpty) {
                                  Get.snackbar(
                                    'Error',
                                    'Please select category',
                                    snackPosition:
                                        SnackPosition
                                            .BOTTOM,
                                    backgroundColor:
                                        Colors.red,
                                    colorText:
                                        Colors.white,
                                  );

                                  return;
                                }

                                if (itemNameController
                                    .text
                                    .trim()
                                    .isEmpty) {
                                  Get.snackbar(
                                    'Error',
                                    'Please enter item name',
                                    snackPosition:
                                        SnackPosition
                                            .BOTTOM,
                                    backgroundColor:
                                        Colors.red,
                                    colorText:
                                        Colors.white,
                                  );

                                  return;
                                }

                                if (locationController
                                    .text
                                    .trim()
                                    .isEmpty) {
                                  Get.snackbar(
                                    'Error',
                                    'Please enter location',
                                    snackPosition:
                                        SnackPosition
                                            .BOTTOM,
                                    backgroundColor:
                                        Colors.red,
                                    colorText:
                                        Colors.white,
                                  );

                                  return;
                                }

                                if (dateController
                                    .text
                                    .trim()
                                    .isEmpty) {
                                  Get.snackbar(
                                    'Error',
                                    'Please select date',
                                    snackPosition:
                                        SnackPosition
                                            .BOTTOM,
                                    backgroundColor:
                                        Colors.red,
                                    colorText:
                                        Colors.white,
                                  );

                                  return;
                                }

                                bool success =
                                    await controller
                                        .createItem(
                                  categoryId: controller
                                      .selectedCategoryId
                                      .value,

                                  itemName:
                                      itemNameController
                                          .text
                                          .trim(),

                                  description:
                                      descriptionController
                                          .text
                                          .trim(),

                                  location:
                                      locationController
                                          .text
                                          .trim(),

                                  dateLostFound:
                                      dateController
                                          .text,
                                );

                                if (success) {
                                  itemNameController
                                      .clear();

                                  descriptionController
                                      .clear();

                                  locationController
                                      .clear();

                                  dateController
                                      .clear();
                                }
                              },

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF0D9488),

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                18),
                      ),
                    ),

                    child: controller
                            .isLoading.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,

                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Post Item',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String title,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
          ),

          child: TextField(
            controller: controller,
            maxLines: maxLines,

            decoration: InputDecoration(
              hintText: hint,

              border: InputBorder.none,

              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
