import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/auth_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/google_signin_service.dart';
import '../screens/auth_screen.dart';

class AuthController extends GetxController {
  final Rx<AuthUser?> user = Rx<AuthUser?>(null);
  final Rx<Admin?> admin = Rx<Admin?>(null);

  final RxString token = ''.obs;
  final RxBool isAdmin = false.obs;
  final RxBool isLoading = false.obs;

  bool get isLoggedIn => token.value.isNotEmpty;

  String get userId =>
      isAdmin.value
          ? (admin.value?.id ?? '')
          : (user.value?.id ?? '');

  @override
  void onInit() {
    super.onInit();
    checkAuth();
  }

  void checkAuth() {
    try {
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
    } catch (e) {
      debugPrint("Auth Session Restoration Error: $e");
      logout(); 
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
      if (response['success'] == true || response['token'] != null) {
        Get.snackbar('Registration Successful', 'Please login with your credentials',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFF0D9488), colorText: Colors.white);
        return true;
      }
      throw Exception(response['message'] ?? 'Registration failed');
    } catch (e) {
      Get.snackbar('Registration Failed', _parseErrorMessage(e.toString()),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      isLoading.value = true;
      final response = await ApiService.login(email: email, password: password);
      if (response['token'] == null) throw Exception(response['message'] ?? 'Invalid email or password');
      
      final userData = response['user'] ?? response['data'] ?? response;
      if (userData == null) throw Exception('User profile data missing from server response');

      await StorageService.saveToken(response['token']);
      await StorageService.saveUser(userData);
      await StorageService.saveIsAdmin(false);

      token.value = response['token'];
      user.value = AuthUser.fromJson(userData);
      isAdmin.value = false;

      Get.snackbar('Welcome Back', 'Login successful!',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFF0D9488), colorText: Colors.white);
      return true;
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      Get.snackbar('Login Failed', _parseErrorMessage(e.toString()),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> googleSignIn() async {
    try {
      isLoading.value = true;
      final googleResult = await GoogleSignInService.signInWithValidation();
      if (!googleResult.success) throw Exception(googleResult.error ?? 'Google Sign-In failed');

      try {
        final response = await ApiService.googleSignIn(
          idToken: googleResult.idToken!,
          email: googleResult.email!,
          firstName: googleResult.firstName!,
          lastName: googleResult.lastName!,
          photoUrl: googleResult.photoUrl,
          googleUserId: googleResult.googleUserId,
        );
        if (response['token'] != null && response['user'] != null) {
          await StorageService.saveToken(response['token']);
          await StorageService.saveUser(response['user']);
          await StorageService.saveIsAdmin(false);
          token.value = response['token'];
          user.value = AuthUser.fromJson(response['user']);
          isAdmin.value = false;
          return true;
        }
      } catch (e) {
        if (e.toString().contains('404') || e.toString().contains('not found')) {
          return await _autoRegisterWithGoogle(googleResult);
        }
        rethrow;
      }
      return false;
    } catch (e) {
      Get.snackbar('Google Sign-In Failed', _parseErrorMessage(e.toString()),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _autoRegisterWithGoogle(GoogleSignInResult googleResult) async {
    try {
      final response = await ApiService.registerWithGoogle(
        idToken: googleResult.idToken!,
        email: googleResult.email!,
        firstName: googleResult.firstName!,
        lastName: googleResult.lastName!,
        phone: '0000000000',
        photoUrl: googleResult.photoUrl,
        googleUserId: googleResult.googleUserId,
      );
      if (response['token'] != null && response['user'] != null) {
        await StorageService.saveToken(response['token']);
        await StorageService.saveUser(response['user']);
        await StorageService.saveIsAdmin(false);
        token.value = response['token'];
        user.value = AuthUser.fromJson(response['user']);
        isAdmin.value = false;
        return true;
      }
      return false;
    } catch (e) { rethrow; }
  }

  Future<bool> adminLogin({required String username, required String password}) async {
    try {
      isLoading.value = true;
      final response = await ApiService.adminLogin(username: username, password: password);
      if (response['token'] != null && response['admin'] != null) {
        await StorageService.saveToken(response['token']);
        await StorageService.saveUser(response['admin']);
        await StorageService.saveIsAdmin(true);
        token.value = response['token'];
        admin.value = Admin.fromJson(response['admin']);
        isAdmin.value = true;
        Get.snackbar('Admin Access Granted', 'Welcome, ${admin.value?.fullName}',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFF0E11D48), colorText: Colors.white);
        return true;
      }
      throw Exception('Invalid Admin Credentials');
    } catch (e) {
      Get.snackbar('Admin Login Failed', _parseErrorMessage(e.toString()),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================
  // LOGOUT (FIXED: NON-BLOCKING CLEANUP)
  // ==========================
  Future<void> logout() async {
    // 1. Immediately wipe local auth states so the context updates
    user.value = null;
    admin.value = null;
    token.value = '';
    isAdmin.value = false;

    // 2. Clear local storage records
    await StorageService.clearAll();

    // 3. Trigger Google sign out in the background WITHOUT 'await'
    // This stops Google service dependencies from blocking or freezing execution threads.
    try {
      GoogleSignInService.signOut();
    } catch (e) {
      debugPrint("Google background sign out error: $e");
    }
  }

  String _parseErrorMessage(String error) {
    if (error.startsWith('Exception: ')) error = error.substring(11);
    if (error.contains('Invalid credentials') || error.contains('401')) return 'Invalid email or password';
    if (error.contains('already exists')) return 'This email is already registered';
    if (error.contains('CHARUSAT')) return 'Please use your official @charusat.edu.in email';
    if (error.contains('Network') || error.contains('SocketException')) return 'Network error. Please check your internet connection';
    if (error.contains('404')) return 'Server endpoint not found. Contact administrator.';
    return error;
  }
}
