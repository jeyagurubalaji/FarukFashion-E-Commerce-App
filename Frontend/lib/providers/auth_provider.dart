import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final _storage = const FlutterSecureStorage();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(AppConstants.userIdKey);
    final username = prefs.getString(AppConstants.usernameKey);
    final fullName = prefs.getString(AppConstants.fullNameKey);
    final rolesStr = prefs.getString('ff_roles') ?? '';

    if (id != null && username != null) {
      _api.setToken(token);
      _user = UserModel(
        id: id,
        username: username,
        fullName: fullName ?? username,
        email: '',
        roles: rolesStr.isEmpty ? {} : rolesStr.split(',').toSet(),
      );
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(username, password);
      await _saveSession(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.register(payload);
      await _saveSession(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

    Future<bool> loginWithGoogle() async {
      _isLoading = true;
      _error = null;
      notifyListeners();
      try {
        final googleSignIn = GoogleSignIn(
          clientId: AppConstants.googleClientId,
          scopes: const ['email', 'profile', 'openid'],
        );

        try {
          await googleSignIn.signOut();
        } catch (_) {}

        final account = await googleSignIn.signIn();
        if (account == null) {
          _error = 'Google sign-in cancelled';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final gAuth = await account.authentication;
        final idToken = gAuth.idToken;
        final accessToken = gAuth.accessToken;

        if ((idToken == null || idToken.isEmpty) &&
            (accessToken == null || accessToken.isEmpty)) {
          throw Exception(
            'Google returned no tokens. Check client ID origins and COOP headers.',
          );
        }

        final data = await _api.googleLogin(
          idToken: idToken,
          accessToken: accessToken,
          email: account.email,
          displayName: account.displayName,
        );
        await _saveSession(data);
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['accessToken'] as String;
    await _storage.write(key: AppConstants.tokenKey, value: token);
    _api.setToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userIdKey, data['userId']?.toString() ?? '');
    await prefs.setString(AppConstants.usernameKey, data['username'] ?? '');
    await prefs.setString(AppConstants.fullNameKey, data['fullName'] ?? '');
    final roles = (data['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
    await prefs.setString('ff_roles', roles.join(','));

    _user = UserModel.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn(clientId: AppConstants.googleClientId).signOut();
    } catch (_) {}
    await _storage.delete(key: AppConstants.tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _api.setToken(null);
    _user = null;
    notifyListeners();
  }
}