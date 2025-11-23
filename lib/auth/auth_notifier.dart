import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/constants.dart';

class User {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String roleId;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.roleId,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      roleId: json['role_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AuthNotifier extends ChangeNotifier {
  static const _tokenKey = 'auth_token';

  String? _token;
  User? _user;
  bool initializing = true;
  bool loading = false;
  String? errorMessage;

  String? get token => _token;
  User? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;

  Future<void> init(LocalData local) async {
    try {
      // Try to load token from Hive
      final box = await Hive.openBox('auth');
      _token = box.get(_tokenKey);

      if (_token != null) {
        // Verify token is valid by fetching current user
        await _fetchCurrentUser(local);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _token = null;
      _user = null;
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<void> _fetchCurrentUser(LocalData local) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        local.loggedInUserId = _user!.id;
      } else {
        // Token is invalid, clear it
        await _clearAuth();
      }
    } catch (e) {
      debugPrint('Error fetching current user: $e');
      await _clearAuth();
    }
  }

  Future<void> login({required String email, required String password}) async {
    errorMessage = null;
    loading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = User.fromJson(data['user']);

        // Store token in Hive
        final box = await Hive.openBox('auth');
        await box.put(_tokenKey, _token);
      } else {
        errorMessage = data['error'] ?? 'Login failed';
      }
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = 'Network error. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    errorMessage = null;
    loading = true;
    notifyListeners();

    try {
      // First check if username is available
      final checkResponse = await http.get(
        Uri.parse(
          '$apiBaseUrl/auth/check-username?username=${Uri.encodeComponent(username.trim())}',
        ),
      );

      if (checkResponse.statusCode == 200) {
        final checkData = jsonDecode(checkResponse.body);
        if (checkData['available'] == false) {
          errorMessage = 'Username already taken';
          loading = false;
          notifyListeners();
          return;
        }
      }

      // Register user
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'full_name': fullName,
          'username': username.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _user = User.fromJson(data['user']);

        // Store token in Hive
        final box = await Hive.openBox('auth');
        await box.put(_tokenKey, _token);
      } else {
        errorMessage = data['error'] ?? 'Registration failed';
      }
    } catch (e, stackTrace) {
      debugPrint('Signup error: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = 'Network error. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _clearAuth();
    notifyListeners();
  }

  Future<void> _clearAuth() async {
    _token = null;
    _user = null;
    final box = await Hive.openBox('auth');
    await box.delete(_tokenKey);
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
