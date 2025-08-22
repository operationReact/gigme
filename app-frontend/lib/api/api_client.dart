import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String get _base => EnvConfig.apiBaseUrl;

  Future<http.Response> get(String path) async {
    final uri = Uri.parse('$_base$path');
    final res = await http.get(uri, headers: _headers());
    return _handle(res);
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final uri = Uri.parse('$_base$path');
    final res = await http.post(uri, headers: _headers(), body: body == null ? null : jsonEncode(body));
    return _handle(res);
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final uri = Uri.parse('$_base$path');
    final res = await http.put(uri, headers: _headers(), body: body == null ? null : jsonEncode(body));
    return _handle(res);
  }

  Map<String,String> _headers() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  http.Response _handle(http.Response r) {
    // Basic pass through; higher-level code interprets status
    return r;
  }
}

