// lib/api/contact_api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;

import '../env.dart';
import '../services/session_service.dart';
import '../models/contact.dart';

class ContactApi {
  ContactApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  String get _base => EnvConfig.apiBaseUrl;

  /// Read a bearer token if present (token/authToken/jwt/accessToken),
  /// otherwise omit the header (useful for cookie sessions).
  String? _readBearerToken() {
    try {
      final s = SessionService.instance;
      final dyn = (s as dynamic);
      final t = dyn.token ?? dyn.authToken ?? dyn.jwt ?? dyn.accessToken;
      if (t is String && t.isNotEmpty) return t;
    } catch (_) {}
    return null;
  }

  Map<String, String> _authHeader() {
    final t = _readBearerToken();
    return t == null ? const {} : {'Authorization': 'Bearer $t'};
  }

  /// Headers for JSON body requests (POST/PUT)
  Map<String, String> _jsonHeaders({bool withAuth = true}) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (withAuth) ..._authHeader(),
  };

  /// Headers for GET/DELETE (no Content-Type to avoid preflight where possible)
  Map<String, String> _getHeaders({bool withAuth = true}) => {
    'Accept': 'application/json',
    if (withAuth) ..._authHeader(),
  };

  /// --- AUThed (in-app) ---
  Future<List<ContactLinkDto>> listLinks(int userId) async {
    final uri = Uri.parse('$_base/api/contact-links')
        .replace(queryParameters: {'userId': '$userId'});
    final res = await _client
        .get(uri, headers: _getHeaders())
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load contact links (HTTP ${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('Invalid response for contact links; expected JSON array.');
    }

    return decoded
        .map<ContactLinkDto>(
            (e) => ContactLinkDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// --- PUBLIC (no auth) ---
  Future<List<ContactLinkDto>> listLinksPublic(int userId) async {
    final uri = Uri.parse('$_base/api/contact-links/public')
        .replace(queryParameters: {'userId': '$userId'});

    final res = await _client
        .get(uri, headers: _getHeaders(withAuth: false))
        .timeout(const Duration(seconds: 20));

    if (kDebugMode) {
      // debug prints help while wiring the public card
      // ignore: avoid_print
      print('GET $uri -> ${res.statusCode}');
    }

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load public contact links (HTTP ${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('Invalid response for public contact links.');
    }

    return decoded
        .map<ContactLinkDto>(
            (e) => ContactLinkDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContactLinkDto> createLink({
    required int userId,
    required String label,
    required String url,
    String? kind,
    int? order,
  }) async {
    final uri = Uri.parse('$_base/api/contact-links');
    final body = jsonEncode(
        {'userId': userId, 'label': label, 'url': url, 'kind': kind, 'order': order});

    final res = await _client
        .post(uri, headers: _jsonHeaders(), body: body)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create link (HTTP ${res.statusCode}): ${res.body}');
    }

    return res.body.isNotEmpty
        ? ContactLinkDto.fromJson(jsonDecode(res.body) as Map<String, dynamic>)
        : ContactLinkDto.fromJson({
      'id': 0,
      'userId': userId,
      'label': label,
      'url': url,
      'kind': kind,
      'order': order,
    });
  }

  Future<ContactLinkDto> updateLink(
      int id, {
        String? label,
        String? url,
        String? kind,
        int? order,
      }) async {
    final uri = Uri.parse('$_base/api/contact-links/$id');
    final body =
    jsonEncode({'label': label, 'url': url, 'kind': kind, 'order': order});

    final res = await _client
        .put(uri, headers: _jsonHeaders(), body: body)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('Failed to update link (HTTP ${res.statusCode}): ${res.body}');
    }
    return ContactLinkDto.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteLink(int id) async {
    final uri = Uri.parse('$_base/api/contact-links/$id');
    final res = await _client
        .delete(uri, headers: _getHeaders())
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete link (HTTP ${res.statusCode}): ${res.body}');
    }
  }

  void close() => _client.close();
}
