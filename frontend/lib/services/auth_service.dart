import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import 'api_client.dart';

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
}
