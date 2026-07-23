import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'https://bot.kainuwa.africa/mobile';
  
  String? _token;
  String? _role;
  bool _isInit = false;

  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInit;
  String? get role => _role;

  ApiService() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _token = await _storage.read(key: 'api_token');
    _role = await _storage.read(key: 'user_role');
    _isInit = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        _token = data['token'];
        _role = data['role'];
        await _storage.write(key: 'api_token', value: _token);
        await _storage.write(key: 'user_role', value: _role);
        notifyListeners();
      }
      return data;
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    await _storage.delete(key: 'api_token');
    await _storage.delete(key: 'user_role');
    notifyListeners();
  }

  Future<Map<String, dynamic>> getEndpoint(String endpoint) async {
    if (_token == null) return {'status': 'error', 'message': 'Unauthorized'};
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> postEndpoint(String endpoint, Map<String, dynamic> payload) async {
    if (_token == null) return {'status': 'error', 'message': 'Unauthorized'};
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(payload),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error'};
    }
  }
}
