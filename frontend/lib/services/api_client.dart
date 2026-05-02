import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  Future<Map<String, dynamic>> postJson(
    String path, {
    required String idToken,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse("$baseUrl$path");
    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $idToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("request_failed_${response.statusCode}");
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    required String idToken,
  }) async {
    final uri = Uri.parse("$baseUrl$path");
    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $idToken",
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("request_failed_${response.statusCode}");
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
