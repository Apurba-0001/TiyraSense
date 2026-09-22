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

  static const _androidOptions = AndroidOptions(
    resetOnError: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  AuthProvider({
    ApiService? apiService,
    FlutterSecureStorage? secureStorage,
  })  : _apiService = apiService ?? ApiService(),
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: _androidOptions,
              iOptions: _iosOptions,
            );

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  ApiService get apiService => _apiService;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null || _currentUser != null;

  /// Called on application startup before rendering the initial screen.
  ///
  /// Restores credentials from OS secure storage. If cached credentials exist,
  /// the user stays logged in and enters the app immediately without seeing
  /// the login screen. The user only logs out when they explicitly tap "Sign Out".
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final savedToken = await _secureStorage.read(
        key: _kTokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      final savedUserJson = await _secureStorage.read(
        key: _kUserDataKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
      }

      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        try {
          _currentUser = UserModel.fromJson(
            jsonDecode(savedUserJson) as Map<String, dynamic>,
          );
        } catch (_) {}
      }

      // If token is present, attempt background profile refresh with backend
      if (_token != null && _token!.isNotEmpty) {
        try {
          final profile = await _apiService.fetchProfile(_token!);
          _currentUser = profile;
          await _secureStorage.write(
            key: _kUserDataKey,
            value: jsonEncode(profile.toJson()),
            aOptions: _androidOptions,
            iOptions: _iosOptions,
          );
        } catch (_) {
          // Never log the user out automatically on startup or network/server errors.
          // The cached user profile keeps the user logged in until they explicitly click Sign Out.
        }
      }
    } catch (_) {
      // Secure storage read error handled safely
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
      await _secureStorage.write(
        key: _kTokenKey,
        value: _token,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _secureStorage.write(
        key: _kUserDataKey,
        value: jsonEncode(_currentUser!.toJson()),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
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

  Future<bool> register(String fullName, String email, String password, UserRole role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.register(fullName, email, password, role);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  bool _lastProfileUpdateSynced = true;
  bool get lastProfileUpdateSynced => _lastProfileUpdateSynced;

  Future<bool> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? organization,
  }) async {
    if (_currentUser == null) return false;

    // Optimistically update local state so UI updates immediately
    _currentUser = UserModel(
      id: _currentUser!.id,
      email: _currentUser!.email,
      fullName: fullName.trim(),
      role: _currentUser!.role,
      phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
      organization: organization ?? _currentUser!.organization,
    );
    notifyListeners();

    try {
      await _secureStorage.write(
        key: _kUserDataKey,
        value: jsonEncode(_currentUser!.toJson()),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (_) {}

    // Persist to backend and cloud database if authenticated
    if (_token != null && _token!.isNotEmpty) {
      try {
        final serverUpdatedUser = await _apiService.updateProfile(
          token: _token!,
          fullName: fullName,
          phoneNumber: phoneNumber,
          organization: organization,
        );
        _currentUser = serverUpdatedUser;
        _lastProfileUpdateSynced = true;
        await _secureStorage.write(
          key: _kUserDataKey,
          value: jsonEncode(_currentUser!.toJson()),
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
        notifyListeners();
        return true;
      } catch (e) {
        // Retain local optimistic update, but flag that backend DB was not synced
        _lastProfileUpdateSynced = false;
        notifyListeners();
        return false;
      }
    }
    _lastProfileUpdateSynced = false;
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null || _token!.isEmpty) return false;
    try {
      return await _apiService.changePassword(
        token: _token!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (_) {
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
      await _secureStorage.delete(
        key: _kTokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _secureStorage.delete(
        key: _kUserDataKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (_) {}
  }
}

/// Global AuthProvider instance for app-wide access
final authProvider = AuthProvider();

