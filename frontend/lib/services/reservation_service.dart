import 'package:firebase_auth/firebase_auth.dart';
import 'api_client.dart';
import '../config/app_config.dart';

class ReservationService {
  final ApiClient apiClient;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ReservationService({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.apiBaseUrl);

  Future<Map<String, dynamic>> createReservation({
    required String listingId,
    required String listingTitle,
    required String listingImage,
    required String ownerId,
    required String ownerName,
    required String startDate,
    required String endDate,
    required int months,
    required num monthlyPrice,
    required num maintenanceMonthly,
    required num taxes,
    required num total,
    String? renterName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final idToken = await user.getIdToken();
    if (idToken == null) throw Exception('Failed to get token');

    final body = {
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImage': listingImage,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'startDate': startDate,
      'endDate': endDate,
      'months': months,
      'monthlyPrice': monthlyPrice,
      'maintenanceMonthly': maintenanceMonthly,
      'taxes': taxes,
      'total': total,
      if (renterName != null) 'renterName': renterName,
    };

    final response = await apiClient.postJson(
      '/api/reservations',
      idToken: idToken,
      body: body,
    );

    if (response['success'] == true) {
      return response;
    } else {
      throw Exception(response['error'] ?? 'Unknown error');
    }
  }

  Future<List<dynamic>> getMyReservations() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final idToken = await user.getIdToken();
    if (idToken == null) throw Exception('Failed to get token');

    final response = await apiClient.getJson(
      '/api/reservations/renter',
      idToken: idToken,
    );

    if (response['success'] == true) {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['error'] ?? 'Unknown error');
    }
  }

  Future<List<dynamic>> getOwnerReservations() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final idToken = await user.getIdToken();
    if (idToken == null) throw Exception('Failed to get token');

    final response = await apiClient.getJson(
      '/api/reservations/owner',
      idToken: idToken,
    );

    if (response['success'] == true) {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['error'] ?? 'Unknown error');
    }
  }

  Future<void> updateStatus(String reservationId, String status) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final idToken = await user.getIdToken();
    if (idToken == null) throw Exception('Failed to get token');

    final response = await apiClient.patchJson(
      '/api/reservations/$reservationId/status',
      idToken: idToken,
      body: {'status': status},
    );

    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Unknown error');
    }
  }

  Future<void> deleteReservation(String reservationId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final idToken = await user.getIdToken();
    if (idToken == null) throw Exception('Failed to get token');

    final response = await apiClient.delete(
      '/api/reservations/$reservationId',
      idToken: idToken,
    );

    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Unknown error');
    }
  }
}
