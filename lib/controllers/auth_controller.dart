import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/auth_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthController extends GetxController {
  final Rx<AuthUser?> user = Rx<AuthUser?>(null);
  final Rx<Admin?> admin = Rx<Admin?>(null);
  final RxString token = ''.obs;
  final RxBool isAdmin = false.obs;
  final RxBool isLoading = false.obs;

  bool get isLoggedIn => token.value.isNotEmpty;
  String get userId => isAdmin.value ? (admin.value?.id ?? '') : (user.value?.id ?? '');

  @override
  void onInit() {
    super.onInit();
    checkAuth();
  }

  void checkAuth() {
    final savedToken = StorageService.getToken();
    final savedUser = StorageService.getUser();
    final savedIsAdmin = StorageService.getIsAdmin();

    if (savedToken != null && savedUser != null) {
      token.value = savedToken;
      isAdmin.value = savedIsAdmin;

      if (savedIsAdmin) {
        admin.value = Admin.fromJson(savedUser);
      } else {
        user.value = AuthUser.fromJson(savedUser);
      }
    }
  }

  Future<bool> register({
    required String universityId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      isLoading.value = true;

      final response = await ApiService.register(
        universityId: universityId,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      if (response['success'] == true) {
        token.value = response['token'];
        user.value = AuthUser.fromJson(response['user']);
        isAdmin.value = false;

        await StorageService.saveToken(response['token']);
        await StorageService.saveUser(response['user']);
        await StorageService.saveIsAdmin(false);

        Get.snackbar(
          'Success',
          'Account created successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0D9488),
          colorText: Colors.white,
        );

        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar(
        'Registration Failed',
        _parseErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login({
    required String universityId,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final response = await ApiService.login(
        universityId: universityId,
        password: password,
      );

      if (response['success'] == true) {
        token.value = response['token'];
        user.value = AuthUser.fromJson(response['user']);
        isAdmin.value = false;

        await StorageService.saveToken(response['token']);
        await StorageService.saveUser(response['user']);
        await StorageService.saveIsAdmin(false);

        Get.snackbar(
          'Welcome Back',
          'Login successful!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0D9488),
          colorText: Colors.white,
        );

        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        _parseErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> adminLogin({
    required String username,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final response = await ApiService.adminLogin(
        username: username,
        password: password,
      );

      if (response['success'] == true) {
        token.value = response['token'];
        admin.value = Admin.fromJson(response['admin']);
        isAdmin.value = true;

        await StorageService.saveToken(response['token']);
        await StorageService.saveUser(response['admin']);
        await StorageService.saveIsAdmin(true);

        Get.snackbar(
          'Admin Access Granted',
          'Welcome, ${response['admin']['full_name']}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE11D48),
          colorText: Colors.white,
        );

        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar(
        'Admin Login Failed',
        _parseErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    user.value = null;
    admin.value = null;
    token.value = '';
    isAdmin.value = false;
    await StorageService.clearAll();

    Get.snackbar(
      'Logged Out',
      'You have been logged out successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.grey[700],
      colorText: Colors.white,
    );
  }

  Future<void> refreshProfile() async {
    if (token.value.isEmpty || isAdmin.value) return;

    try {
      final profile = await ApiService.getUserProfile(token.value);
      user.value = profile;
      await StorageService.saveUser(profile.toJson());
    } catch (e) {
      print('Failed to refresh profile: $e');
    }
  }

  String _parseErrorMessage(String error) {
    // Remove "Exception: " prefix if present
    if (error.startsWith('Exception: ')) {
      error = error.substring(11);
    }

    // Handle common error messages
    if (error.contains('Invalid credentials')) {
      return 'Invalid username or password';
    } else if (error.contains('already exists')) {
      return 'This university ID or email is already registered';
    } else if (error.contains('Network')) {
      return 'Network error. Please check your connection';
    } else if (error.contains('timeout')) {
      return 'Request timeout. Please try again';
    }

    return error;
  }
}
