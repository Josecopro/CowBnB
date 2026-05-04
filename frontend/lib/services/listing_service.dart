import 'package:firebase_auth/firebase_auth.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ListingService {
  final ApiClient apiClient;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ListingService({ApiClient? apiClient}) 
      : apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.apiBaseUrl);

  Future<String> createListing({
    required String title,
    required String description,
    required num size,
    required num price,
    required List<String> features,
    required List<Map<String, String>> imagesBase64,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get token');
    }

    final body = {
      'title': title,
      'description': description,
      'size': size,
      'price': price,
      'features': features,
      'images': imagesBase64,
    };

    final response = await apiClient.postJson(
      '/api/listings',
      idToken: idToken,
      body: body,
    );

    if (response['success'] == true) {
      return response['id'] as String;
    } else {
      throw Exception(response['error'] ?? 'Unknown error occurred');
    }
  }

  Future<List<dynamic>> getMyListings() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get token');
    }

    final response = await apiClient.getJson(
      '/api/listings/me',
      idToken: idToken,
    );

    if (response['success'] == true) {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['error'] ?? 'Unknown error fetching my listings');
    }
  }

  Future<List<dynamic>> getAllListings() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get token');
    }

    final response = await apiClient.getJson(
      '/api/listings',
      idToken: idToken,
    );

    if (response['success'] == true) {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['error'] ?? 'Unknown error fetching all listings');
    }
  }
}
