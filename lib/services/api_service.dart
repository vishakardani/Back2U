import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:unifound/config/app_config.dart';
import '../models/item_model.dart';
import '../models/auth_model.dart';
import 'dart:io';


class ApiService {
  // Auth headers helper
  static Map<String, String> _getHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> register({
    required String universityId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/register'),
      headers: _getHeaders(),
      body: jsonEncode({
        'university_id': universityId,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String universityId,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/login'),
      headers: _getHeaders(),
      body: jsonEncode({
        'university_id': universityId,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/admin/login'),
      headers: _getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  // Items endpoints
  static Future<List<UniversityItem>> getItems({
    String? type,
    String? categoryId,
    String? claimed,
  }) async {
    var uri = Uri.parse('${AppConfig.baseUrl}/items');

    Map<String, String> queryParams = {};
    if (type != null) queryParams['type'] = type;
    if (categoryId != null) queryParams['category'] = categoryId;
    if (claimed != null) queryParams['claimed'] = claimed;

    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);

    if (data['success'] == true && data['items'] != null) {
      return (data['items'] as List)
          .map((item) => UniversityItem.fromJson(item))
          .toList();
    }
    return [];
  }

  static Future<UniversityItem> getItemById(String id) async {
    final response = await http.get(Uri.parse('${AppConfig.baseUrl}/items/$id'), headers: _getHeaders());
    final data = _handleResponse(response);

    if (data['success'] == true && data['item'] != null) {
      return UniversityItem.fromJson(data['item']);
    }
    throw Exception('Item not found');
  }

  static Future<List<UniversityItem>> getRelatedItems(String id) async {
    final response = await http.get(Uri.parse('${AppConfig.baseUrl}/items/$id/related'), headers: _getHeaders());
    final data = _handleResponse(response);

    if (data['success'] == true && data['items'] != null) {
      return (data['items'] as List)
          .map((item) => UniversityItem.fromJson(item))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createItem({
    required String token,
    required String categoryId,
    required String itemType,
    required String itemName,
    String? description,
    required String location,
    required String dateLostFound,
    List<Map<String, dynamic>>? images,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/items'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'category_id': categoryId,
        'item_type': itemType,
        'item_name': itemName,
        'description': description,
        'location': location,
        'date_lost_found': dateLostFound,
        'images': images ?? [],
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateItem({
    required String token,
    required String itemId,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/items/$itemId'),
      headers: _getHeaders(token),
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  static Future<void> deleteItem({
    required String token,
    required String itemId,
  }) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/items/$itemId'),
      headers: _getHeaders(token),
    );

    _handleResponse(response);
  }

  // Claims endpoints
  static Future<Map<String, dynamic>> raiseClaim({
    required String token,
    required String itemId,
    String? message,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/claims'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'item_id': itemId,
        'message': message ?? '',
      }),
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getMyClaims({
    required String token,
    String? status,
  }) async {
    var uri = Uri.parse('${AppConfig.baseUrl}/claims/my');
    if (status != null) {
      uri = uri.replace(queryParameters: {'status': status});
    }

    final response = await http.get(
      uri,
      headers: _getHeaders(token),
    );

    final data = _handleResponse(response);
    if (data['success'] == true && data['claims'] != null) {
      return data['claims'];
    }
    return [];
  }

  static Future<List<dynamic>> getReceivedClaims({
    required String token,
    String? status,
  }) async {
    var uri = Uri.parse('${AppConfig.baseUrl}/claims/received');
    if (status != null) {
      uri = uri.replace(queryParameters: {'status': status});
    }

    final response = await http.get(
      uri,
      headers: _getHeaders(token),
    );

    final data = _handleResponse(response);
    if (data['success'] == true && data['claims'] != null) {
      return data['claims'];
    }
    return [];
  }

  static Future<Map<String, dynamic>> confirmClaim({
    required String token,
    required String claimId,
  }) async {
    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/claims/$claimId/confirm'),
      headers: _getHeaders(token),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> rejectClaim({
    required String token,
    required String claimId,
    required String rejectionReason,
  }) async {
    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/claims/$claimId/reject'),
      headers: _getHeaders(token),
      body: jsonEncode({'rejection_reason': rejectionReason}),
    );

    return _handleResponse(response);
  }

  // User endpoints
  static Future<List<UniversityItem>> getUserItems({
    required String token,
    String? type,
    String? claimed,
  }) async {
    var uri = Uri.parse('${AppConfig.baseUrl}/users/items');

    Map<String, String> queryParams = {};
    if (type != null) queryParams['type'] = type;
    if (claimed != null) queryParams['claimed'] = claimed;

    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(
      uri,
      headers: _getHeaders(token),
    );

    final data = _handleResponse(response);

    if (data['success'] == true && data['items'] != null) {
      return (data['items'] as List)
          .map((item) => UniversityItem.fromJson(item))
          .toList();
    }
    return [];
  }

  static Future<AuthUser> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/users/profile'),
      headers: _getHeaders(token),
    );

    final data = _handleResponse(response);

    if (data['success'] == true && data['user'] != null) {
      return AuthUser.fromJson(data['user']);
    }
    throw Exception('Failed to get profile');
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  }) async {
    Map<String, dynamic> body = {};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (phone != null) body['phone'] = phone;
    if (profileImageUrl != null) body['profile_image_url'] = profileImageUrl;

    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/users/profile'),
      headers: _getHeaders(token),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // Categories endpoint
  static Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('${AppConfig.baseUrl}/categories'), headers: _getHeaders());
    final data = _handleResponse(response);

    if (data['success'] == true && data['categories'] != null) {
      return (data['categories'] as List)
          .map((cat) => Category.fromJson(cat))
          .toList();
    }
    return [];
  }

  // Admin endpoints
  static Future<AdminStats> getAdminStats(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/admin/stats'),
      headers: _getHeaders(token),
    );

    final data = _handleResponse(response);

    if (data['success'] == true && data['stats'] != null) {
      return AdminStats.fromJson(data['stats']);
    }
    throw Exception('Failed to get stats');
  }

  // Helper method
  static Map<String, dynamic> _handleResponse(http.Response response) {
    // DEBUG LOG: FULL RESPONSE
    debugPrint('--- API RESPONSE START ---');
    debugPrint('URL: ${response.request?.url}');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('--- API RESPONSE END ---');

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      throw Exception('Empty response from server (Status: ${response.statusCode})');
    }

    try {
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Request failed (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (response.statusCode == 404) {
        throw Exception('Endpoint not found (404). Please check the API URL.');
      }
      if (response.statusCode == 500) {
        throw Exception('Internal Server Error (500). Please try again later.');
      }
      if (e is FormatException) {
        throw Exception('Server returned invalid data (HTML/Error page). Status: ${response.statusCode}');
      }
      throw Exception('Request failed (Status: ${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> uploadImage({
    required String token,
    required File imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/upload'),
      );

      request.headers.addAll(_getHeaders(token));

      // Add the image file
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
