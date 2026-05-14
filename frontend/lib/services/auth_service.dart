import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import 'api_client.dart';

String _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  return '[AuthService] [$timestamp] $message';
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    required this.role,
    this.currentMonthEarnings,
    this.totalViews,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String role;
  final num? currentMonthEarnings;
  final num? totalViews;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String? ?? 'renter',
      currentMonthEarnings: json['current_month_earnings'] as num?,
      totalViews: json['total_views'] as num?,
    );
  }
}

class AuthService {
  AuthService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.apiBaseUrl);

  final ApiClient _apiClient;

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    print(_log('Registration request started for email=$email'));
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(_log('Registration succeeded for uid=${credential.user?.uid} email=$email'));
      return credential;
    } catch (error) {
      print(_log('Registration error for email=$email error=$error'));
      rethrow;
    }
  }

  Future<void> upsertProfile({
    required String role,
    String? displayName,
    String? phoneNumber,
  }) async {
    print(_log('Profile update started role=$role displayName=${displayName ?? 'empty'} phoneNumber=${phoneNumber ?? 'empty'}'));
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("missing_user");
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception("missing_id_token");
    }
    await _apiClient.postJson(
      "/api/auth/profile",
      idToken: idToken,
      body: {
        "role": role,
        "display_name": displayName,
        "phone_number": phoneNumber,
      },
    );
    print(_log('Profile update succeeded role=$role'));
  }

  Future<UserProfile?> getProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      return null;
    }

    final response = await _apiClient.getJson(
      "/api/auth/me",
      idToken: idToken,
    );

    final profileJson = response['profile'] as Map<String, dynamic>?;
    if (profileJson == null) {
      return null;
    }

    return UserProfile.fromJson(profileJson);
  }

  Future<List<dynamic>> getFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      final token = await user.getIdToken();
      final response = await ApiClient(baseUrl: AppConfig.apiBaseUrl).getJson('/api/favorites', idToken: token!);
      return response['data'] as List<dynamic>? ?? [];
    } catch (e) {
      print('Error getting favs: $e');
      return [];
    }
  }

  Future<void> addFavorite(String listingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('not_logged_in');
    final token = await user.getIdToken();
    await ApiClient(baseUrl: AppConfig.apiBaseUrl).postJson('/api/favorites/$listingId', idToken: token!, body: {});
  }

  Future<void> removeFavorite(String listingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('not_logged_in');
    final token = await user.getIdToken();
    await ApiClient(baseUrl: AppConfig.apiBaseUrl).delete('/api/favorites/$listingId', idToken: token);
  }
}
