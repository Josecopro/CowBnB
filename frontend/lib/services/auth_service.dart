import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import 'api_client.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    required this.role,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String role;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String? ?? 'renter',
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
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> upsertProfile({
    required String role,
    String? displayName,
    String? phoneNumber,
  }) async {
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
}
