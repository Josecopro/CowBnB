import 'package:firebase_auth/firebase_auth.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';

class ListingService {
  final ApiClient apiClient;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ListingService({required this.apiClient});

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
}
