import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AuthUser {
  final int id;
  final String email;
  final String role; // FREELANCER or CLIENT
  final bool hasFreelancerProfile;
  final bool hasClientProfile;
  AuthUser({required this.id, required this.email, required this.role, required this.hasFreelancerProfile, required this.hasClientProfile});
  factory AuthUser.fromJson(Map<String,dynamic> j) => AuthUser(
    id: j['id'] as int,
    email: j['email'] as String,
    role: j['role'] as String,
    hasFreelancerProfile: j['hasFreelancerProfile'] as bool? ?? false,
    hasClientProfile: j['hasClientProfile'] as bool? ?? false,
  );
}

class AuthApi {
  final _client = ApiClient.instance;
  Future<AuthUser> register({required String email, required String password, required String role}) async {
    final res = await _client.post('/api/auth/register', body: {
      'email': email,
      'password': password,
      'role': role,
    });
    if (res.statusCode == 201) {
      return AuthUser.fromJson(jsonDecode(res.body) as Map<String,dynamic>);
    }
    throw ApiException(_errorMsg(res));
  }

  Future<AuthUser> login({required String email, required String password}) async {
    final res = await _client.post('/api/auth/login', body: {
      'email': email,
      'password': password,
    });
    if (res.statusCode == 200) {
      return AuthUser.fromJson(jsonDecode(res.body) as Map<String,dynamic>);
    }
    throw ApiException(_errorMsg(res));
  }

  String _errorMsg(http.Response r) {
    try {
      final m = jsonDecode(r.body);
      if (m is Map && m['error'] is String) return m['error'];
    } catch (_) {}
    return 'Request failed (${r.statusCode})';
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

