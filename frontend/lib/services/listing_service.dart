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
    num? maintenanceCost,
    String? status,
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
      if (maintenanceCost != null) 'maintenanceCost': maintenanceCost,
      if (status != null) 'status': status,
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

  Future<List<dynamic>> getMyReservations() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get token');
    }

    final response = await apiClient.getJson(
      '/api/listings/renter',
      idToken: idToken,
    );

    if (response['success'] == true) {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['error'] ?? 'Unknown error fetching reservations');
    }
  }

  Future<void> recordView(String listingId) async {
    final user = _auth.currentUser;
    final idToken = user != null ? await user.getIdToken() : null;
    try {
      await apiClient.postJson(
        '/api/listings/$listingId/view',
        idToken: idToken ?? '',
        body: {},
      );
    } catch (e) {
      debugPrint('Error recording view: $e');
    }
  }

  Future<void> updateListingStatus(String listingId, String status) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final idToken = await user.getIdToken();
    final response = await apiClient.patchJson(
      '/api/listings/$listingId/status',
      idToken: idToken ?? '',
      body: {'status': status},
    );
    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Unknown error updating status');
    }
  }

  Future<void> deleteListing(String listingId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final idToken = await user.getIdToken();
    final response = await apiClient.delete(
      '/api/listings/$listingId',
      idToken: idToken ?? '',
    );
    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Unknown error deleting listing');
    }
  }

  Future<void> bookListing(
    String listingId,
    num total, {
    DateTime? rentStart,
    DateTime? rentEnd,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final idToken = await user.getIdToken();
    final response = await apiClient.postJson(
      '/api/listings/$listingId/book',
      idToken: idToken ?? '',
      body: {
        'total': total,
        if (rentStart != null) 'rentStart': rentStart.toIso8601String(),
        if (rentEnd != null) 'rentEnd': rentEnd.toIso8601String(),
      },
    );
    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Unknown error booking listing');
    }
  }

  Future<void> completeRental(String listingId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final idToken = await user.getIdToken();
    final response = await apiClient.postJson(
      '/api/listings/$listingId/complete',
      idToken: idToken ?? '',
      body: {},
    );
    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Unknown error completing rental');
    }
  }


}