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


  Future<Map<String, dynamic>> patchJson(
    String path, {
    String? idToken,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    final response = await http.patch(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    String? idToken,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    final response = await http.delete(
      uri,
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
    }
  }

}