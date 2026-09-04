import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

const _kTokenKey = 'tiyrasense_auth_token';
const _kUserDataKey = 'tiyrasense_user_data';

/// Manages authentication state with persistent, encrypted session storage.
///
/// The JWT token and cached user model are stored securely via
/// [FlutterSecureStorage] (Android Keystore / iOS Keychain / Windows DPAPI).
/// The session persists across app kills and phone restarts. The user only
/// logs out when:
/// 1. They explicitly tap "Sign Out" in the application UI, or
/// 2. The backend authoritatively returns HTTP 401 or 403 upon token verification.
///
/// Offline launches retain the cached session so drivers in remote NER
/// regions without network coverage can still access the application.
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage;

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  AuthProvider({
    ApiService? apiService,
    FlutterSecureStorage? secureStorage,
  })  : _apiService = apiService ?? ApiService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Called on application startup before rendering the initial screen.
  ///
  /// Restores credentials from OS secure storage. If cached credentials exist,
  /// the user enters the app immediately without seeing the login screen.
  /// Background revalidation verifies the token against the backend; transient
  /// network failures or offline conditions do NOT log the user out.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final savedToken = await _secureStorage.read(key: _kTokenKey);
      final savedUserJson = await _secureStorage.read(key: _kUserDataKey);

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        if (savedUserJson != null && savedUserJson.isNotEmpty) {
          try {
            _currentUser = UserModel.fromJson(
              jsonDecode(savedUserJson) as Map<String, dynamic>,
            );
          } catch (_) {}
        }

        // Attempt live profile refresh with the backend
        try {
          final profile = await _apiService.fetchProfile(savedToken);
          _currentUser = profile;
          await _secureStorage.write(
            key: _kUserDataKey,
            value: jsonEncode(profile.toJson()),
          );
        } on ApiException catch (e) {
          // Authoritative auth rejection (token revoked or expired on server)
          if (e.statusCode == 401 || e.statusCode == 403) {
            await logout();
            return;
          }
          // Network errors or 5xx server issues keep the cached offline session intact
        } catch (_) {
          // Offline / connectivity failure preserves the cached session
        }
      }
    } catch (_) {
      // Secure storage read error
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.login(email, password);
      _token = data['access_token'] as String;
      _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      // Persist token and cached user data in OS-level encrypted storage
      await _secureStorage.write(key: _kTokenKey, value: _token);
      await _secureStorage.write(
        key: _kUserDataKey,
        value: jsonEncode(_currentUser!.toJson()),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Authentication error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Explicit user logout. Completely wipes tokens and cached profile.
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _errorMessage = null;
    await _clearStoredSession();
    notifyListeners();
  }

  Future<void> _clearStoredSession() async {
    try {
      await _secureStorage.delete(key: _kTokenKey);
      await _secureStorage.delete(key: _kUserDataKey);
    } catch (_) {}
  }
}
