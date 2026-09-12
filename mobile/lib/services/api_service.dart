import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'image_compressor_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client;
  String _baseUrl;
  bool _resolved = false;

  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _getDefaultBaseUrl();

  String get baseUrl => _baseUrl;

  static String _getDefaultBaseUrl() {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    // Default to 127.0.0.1 (works for physical Android devices with `adb reverse tcp:8000 tcp:8000`,
    // as well as Web, Desktop, and iOS). For emulators without adb reverse, _sendWithFallback
    // will seamlessly fall back to 10.0.2.2.
    return 'http://127.0.0.1:8000/api/v1';
  }

  Future<http.Response> _sendWithFallback(
    Future<http.Response> Function(String baseUrl) requestFn,
  ) async {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty || _resolved) {
      return await requestFn(_baseUrl);
    }

    try {
      final res = await requestFn(_baseUrl).timeout(const Duration(seconds: 4));
      _resolved = true;
      return res;
    } on SocketException catch (_) {
      return await _tryAlternate(requestFn);
    } on http.ClientException catch (_) {
      return await _tryAlternate(requestFn);
    } catch (_) {
      return await _tryAlternate(requestFn);
    }
  }

  Future<http.Response> _tryAlternate(
    Future<http.Response> Function(String baseUrl) requestFn,
  ) async {
    String? alternateUrl;
    try {
      if (Platform.isAndroid) {
        if (_baseUrl.contains('127.0.0.1')) {
          alternateUrl = _baseUrl.replaceAll('127.0.0.1', '10.0.2.2');
        } else if (_baseUrl.contains('10.0.2.2')) {
          alternateUrl = _baseUrl.replaceAll('10.0.2.2', '127.0.0.1');
        }
      }
    } catch (_) {}

    if (alternateUrl != null) {
      try {
        final res = await requestFn(alternateUrl).timeout(const Duration(seconds: 4));
        _baseUrl = alternateUrl;
        _resolved = true;
        return res;
      } catch (_) {}
    }

    throw const SocketException('Unable to establish connection to backend');
  }

  static String _extractErrorMessage(dynamic detail, [String fallback = 'Operation failed']) {
    if (detail == null) return fallback;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        String msg = first['msg'].toString();
        if (msg.startsWith('Value error, ')) {
          msg = msg.substring('Value error, '.length);
        }
        if (msg.isNotEmpty) {
          msg = msg[0].toUpperCase() + msg.substring(1);
        }
        return msg;
      }
      return first.toString();
    }
    if (detail is Map && detail['msg'] != null) {
      return detail['msg'].toString();
    }
    return detail.toString();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/auth/login');
        return _client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        );
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw ApiException('Invalid email or password. Please verify credentials.', 401);
      } else {
        String msg = 'Authentication error (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          msg = _extractErrorMessage(body['detail'], msg);
        } catch (_) {}
        throw ApiException(msg, response.statusCode);
      }
    } on SocketException {
      throw ApiException(
        'Unable to connect to TiyraSense backend. If using a physical phone via USB, make sure "adb reverse tcp:8000 tcp:8000" was run and the backend is running on port 8000.',
      );
    } on http.ClientException {
      throw ApiException(
        'Unable to connect to TiyraSense backend. If using a physical phone via USB, make sure "adb reverse tcp:8000 tcp:8000" was run and the backend is running on port 8000.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<UserModel> fetchProfile(String token) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/auth/me');
        return _client.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      });

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException('Session expired. Please sign in again.', response.statusCode);
      }
    } on SocketException {
      throw ApiException('Unable to reach backend to refresh profile.');
    } on http.ClientException {
      throw ApiException('Unable to reach backend to refresh profile.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to retrieve profile: $e');
    }
  }

  Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/auth/register');
        return _client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': fullName.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
            'role': role.toApiRole(),
          }),
        );
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        String msg = 'Registration failed (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          msg = _extractErrorMessage(body['detail'], msg);
        } catch (_) {}
        throw ApiException(msg, response.statusCode);
      }
    } on SocketException {
      throw ApiException(
        'Unable to connect to TiyraSense backend. If using a physical phone via USB, make sure "adb reverse tcp:8000 tcp:8000" was run and the backend is running on port 8000.',
      );
    } on http.ClientException {
      throw ApiException(
        'Unable to connect to TiyraSense backend. If using a physical phone via USB, make sure "adb reverse tcp:8000 tcp:8000" was run and the backend is running on port 8000.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<Map<String, dynamic>> evaluateRoutes({
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    String vehicleClass = 'FOUR_WHEELER',
    bool preferSafety = true,
  }) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/routes/evaluate');
        return _client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'origin': origin,
            'destination': destination,
            'vehicle_class': vehicleClass,
            'prefer_safety': preferSafety,
          }),
        );
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException('Failed to evaluate candidate routes (${response.statusCode})', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Routing evaluation error: $e');
    }
  }

  Future<Map<String, dynamic>> startJourney({
    required String routeId,
    String? vehicleId,
    String? token,
    Map<String, dynamic>? originCoords,
    Map<String, dynamic>? destinationCoords,
    String? originName,
    String? destinationName,
    String? routeName,
    List<dynamic>? routeGeometry,
  }) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/journeys');
        final headers = {'Content-Type': 'application/json'};
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        final body = <String, dynamic>{
          'route_id': routeId,
        };
        if (vehicleId != null) body['vehicle_id'] = vehicleId;
        if (originCoords != null) body['origin_coords'] = originCoords;
        if (destinationCoords != null) body['destination_coords'] = destinationCoords;
        if (originName != null) body['origin_name'] = originName;
        if (destinationName != null) body['destination_name'] = destinationName;
        if (routeName != null) body['route_name'] = routeName;
        if (routeGeometry != null) body['route_geometry'] = routeGeometry;
        return _client.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException('Failed to initialize journey (${response.statusCode})', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Journey initiation error: $e');
    }
  }

  Future<void> sendTelemetry({
    required String journeyId,
    required double latitude,
    required double longitude,
    double speedKmh = 45.0,
    double headingDegrees = 0.0,
  }) async {
    try {
      await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/journeys/$journeyId/telemetry');
        return _client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'latitude': latitude,
            'longitude': longitude,
            'speed_kmh': speedKmh,
            'heading_degrees': headingDegrees,
          }),
        );
      });
    } catch (_) {
      // Telemetry degrades gracefully in intermittent connectivity
    }
  }

  Future<Map<String, dynamic>> getJourneyTracking(String journeyId) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/journeys/$journeyId/tracking');
        return _client.get(url);
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException('Failed to retrieve tracking info (${response.statusCode})', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tracking retrieval error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final encoded = Uri.encodeComponent(query);
        final url = Uri.parse('$baseUrl/routes/places/search?q=$encoded');
        return _client.get(url);
      });
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // =========================================================================
  // DIRECT SUPABASE CLOUD ACCESS (For Simple Direct Reads / Submissions)
  // Bypasses intermediate servers for low latency when no server analytics is needed.
  // =========================================================================
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  Map<String, String> get _supabaseHeaders => {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  /// Simple Request: Fetch live alerts directly from Supabase Cloud DB
  Future<List<Map<String, dynamic>>> fetchAlertsDirect({int limit = 20}) async {
    try {
      final response = await _client.get(
        Uri.parse('$supabaseUrl/rest/v1/alerts?select=*&order=created_at.desc&limit=$limit'),
        headers: _supabaseHeaders,
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Fetch live alerts from FastAPI backend service
  Future<List<Map<String, dynamic>>> fetchAlertsFromBackend({int limit = 50}) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/alerts');
        return _client.get(url, headers: {'Content-Type': 'application/json'});
      });
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Broadcast an official alert to the backend and official dashboard
  Future<Map<String, dynamic>?> broadcastAlert({
    required String severity,
    required String corridor,
    required String title,
    required String description,
    String? token,
  }) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/alerts');
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        return _client.post(
          url,
          headers: headers,
          body: jsonEncode({
            'severity': severity.toUpperCase(),
            'corridor': corridor,
            'title': title,
            'description': description,
          }),
        );
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Simple Request: Fetch safe havens directly from Supabase Cloud DB
  Future<List<Map<String, dynamic>>> fetchSafeHavensDirect() async {
    try {
      final response = await _client.get(
        Uri.parse('$supabaseUrl/rest/v1/safe_havens?select=*&order=name.asc'),
        headers: _supabaseHeaders,
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Simple Request: Submit incident report directly to Supabase Cloud DB
  Future<bool> submitReportDirect(Map<String, dynamic> reportPayload) async {
    try {
      final response = await _client.post(
        Uri.parse('$supabaseUrl/rest/v1/field_reports'),
        headers: _supabaseHeaders,
        body: jsonEncode(reportPayload),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Upload photo evidence directly to Cloudinary CDN with automatic detail-preserving compression.
  /// Compresses high-resolution photos (10MB-20MB) to ~250KB-450KB before transmission,
  /// preserving critical forensic details (cracks, warning signs, water levels).
  Future<String?> uploadEvidencePhotoToCloudinary({
    required File imageFile,
    String? cloudName,
    String? uploadPreset,
    bool autoCompress = true,
  }) async {
    try {
      // 1. High-fidelity compression before uploading across low-bandwidth corridors
      File fileToUpload = imageFile;
      if (autoCompress) {
        fileToUpload = await ImageCompressorService.compressFile(imageFile);
      }

      final cName = cloudName ?? const String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '');
      final preset = uploadPreset ?? const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: 'tiyrasense_evidence');
      if (cName.isEmpty) {
        throw ApiException('CLOUDINARY_CLOUD_NAME is not configured.');
      }
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cName/image/upload');

      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = preset
        ..files.add(await http.MultipartFile.fromPath('file', fileToUpload.path));

      final streamedRes = await _client.send(req);
      final res = await http.Response.fromStream(streamedRes);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Delete a wrong, old, or unwanted field incident report (Official / Admin action)
  Future<bool> deleteFieldReport(String reportId, [String? token]) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/reports/$reportId');
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        return _client.delete(url, headers: headers);
      });
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// Fetch total evidence photo statistics (count, size, format breakdown, recent uploads)
  Future<Map<String, dynamic>?> fetchEvidenceStats([String? token]) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/evidence/admin/stats');
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        return _client.get(url, headers: headers);
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Permanently delete an evidence photo asset from Cloudinary CDN and the database
  Future<bool> deleteEvidencePhoto(String evidenceId, [String? token]) async {
    try {
      final response = await _sendWithFallback((baseUrl) {
        final url = Uri.parse('$baseUrl/evidence/$evidenceId');
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        return _client.delete(url, headers: headers);
      });
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}



