import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client;
  final String _baseUrl;

  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _getDefaultBaseUrl();

  static String _getDefaultBaseUrl() {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    try {
      if (Platform.isAndroid) {
        // Standard Android emulator loopback alias to host machine localhost.
        // For physical devices, run `adb reverse tcp:8000 tcp:8000` to route localhost:8000,
        // or pass --dart-define=API_URL=http://<YOUR_PC_LAN_IP>:8000/api/v1.
        return 'http://10.0.2.2:8000/api/v1';
      }
    } catch (_) {
      // Fallback for non-dart:io environments or web
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw ApiException('Invalid email or password. Please verify credentials.', 401);
      } else {
        String msg = 'Authentication error (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          if (body['detail'] != null) msg = body['detail'].toString();
        } catch (_) {}
        throw ApiException(msg, response.statusCode);
      }
    } on SocketException {
      throw ApiException(
        'Unable to connect to TiyraSense backend. Verify backend server is running on localhost:8000.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<UserModel> fetchProfile(String token) async {
    final url = Uri.parse('$_baseUrl/auth/me');
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException('Session expired. Please sign in again.', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to retrieve profile: $e');
    }
  }
}
