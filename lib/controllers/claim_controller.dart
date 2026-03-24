import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/claim_model.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';
import 'home_controller.dart';

class ClaimController extends GetxController {
  final authController = Get.find<AuthController>();

  final RxList<Claim> myClaims = <Claim>[].obs;
  final RxList<Claim> receivedClaims = <Claim>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (authController.isLoggedIn) {
      fetchClaims();
    }
  }

  Future<void> fetchClaims() async {
    try {
      isLoading.value = true;
      final token = authController.token.value;

      final my = await ApiService.getMyClaims(token: token);
      myClaims.value = my.map((e) => Claim.fromJson(e)).toList();

      final received = await ApiService.getReceivedClaims(token: token);
      receivedClaims.value = received.map((e) => Claim.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching claims: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool hasClaimed(String itemId) {
    return myClaims.any((claim) => claim.itemId == itemId);
  }

  Future<void> raiseClaim(String itemId, String message) async {
    try {
      isLoading.value = true;
      final res = await ApiService.raiseClaim(
        token: authController.token.value,
        itemId: itemId,
        message: message,
      );

      if (res['success'] == true) {
        Get.snackbar(
          'Success',
          'Claim raised successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0D9488),
          colorText: Colors.white,
        );
        await fetchClaims();
        Get.back(); // Close dialog/bottom sheet
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to raise claim: ${_parseError(e)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmClaim(String claimId) async {
    try {
      isLoading.value = true;
      final res = await ApiService.confirmClaim(
        token: authController.token.value,
        claimId: claimId,
      );

      if (res['success'] == true) {
        Get.snackbar(
          'Success',
          'Claim confirmed successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0D9488),
          colorText: Colors.white,
        );
        await fetchClaims();
        // Refresh home items since the item is now claimed
        try {
          Get.find<HomeController>().fetchItems();
        } catch (_) {}
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to confirm claim: ${_parseError(e)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectClaim(String claimId, String reason) async {
    if (reason.isEmpty) {
      Get.snackbar('Error', 'Rejection reason is mandatory');
      return;
    }

    try {
      isLoading.value = true;
      final res = await ApiService.rejectClaim(
        token: authController.token.value,
        claimId: claimId,
        rejectionReason: reason,
      );

      if (res['success'] == true) {
        Get.snackbar(
          'Rejected',
          'Claim has been rejected',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        await fetchClaims();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reject claim: ${_parseError(e)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
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
