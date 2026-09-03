import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('tiyrasense_mobile_token');
      if (savedToken != null) {
        _token = savedToken;
        _currentUser = await _apiService.fetchProfile(savedToken);
      }
    } catch (_) {
      await logout();
    } finally {
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

      // Persist token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tiyrasense_mobile_token', _token!);

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

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _errorMessage = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tiyrasense_mobile_token');
    } catch (_) {}
    notifyListeners();
  }
}
