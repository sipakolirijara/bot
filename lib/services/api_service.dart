import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService extends ChangeNotifier {
  static const String baseUrl = 'https://bot.kainuwa.africa/mobile';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  String? _role;
  bool _isInitialized = false;

  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInitialized;
  String? get role => _role;

  Future<void> initAuth() async {
    _token = await _storage.read(key: 'auth_token');
    _role = await _storage.read(key: 'user_role');
    _isInitialized = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth.php?action=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        _token = data['data']['token'];
        _role = data['data']['role'];

        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(key: 'user_role', value: _role);
        
        notifyListeners();
      }
      return data;
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: Unable to connect.'};
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.get(
          Uri.parse('$baseUrl/auth.php?action=logout'),
          headers: {'Authorization': 'Bearer $_token'},
        );
      } catch (_) {}
    }
    
    _token = null;
    _role = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<Map<String, dynamic>> getEndpoint(String endpoint) async {
    if (_token == null) return {'status': 'error', 'message': 'Unauthorized'};
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed'};
    }
  }

  Future<Map<String, dynamic>> postEndpoint(String endpoint, Map<String, dynamic> body) async {
    if (_token == null) return {'status': 'error', 'message': 'Unauthorized'};
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed'};
    }
  }
}
