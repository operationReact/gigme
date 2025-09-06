import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../services/session_service.dart';
import '../models/contact.dart';

class ContactApi {
  final _base = EnvConfig.apiBaseUrl;

  /// Try to read a bearer token from SessionService without a compile-time dependency
  /// on a specific property name. Works whether your service uses `token`, `authToken`,
  /// `jwt`, or `accessToken`. If none are present, we’ll just omit the header
  /// (useful for cookie-based sessions on web/same-origin).
  String? _readBearerToken() {
    try {
      final s = SessionService.instance;
      final dyn = (s as dynamic);
      final t = dyn.token ??
          dyn.authToken ??
          dyn.jwt ??
          dyn.accessToken;
      if (t is String && t.isNotEmpty) return t;
    } catch (_) {
      // No token property available or not logged in
    }
    return null;
  }

  Map<String, String> _headers() {
    final t = _readBearerToken();
    return <String, String>{
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<List<ContactLinkDto>> listLinks(int userId) async {
    final uri = Uri.parse('$_base/api/contact-links')
        .replace(queryParameters: {'userId': '$userId'});
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load contact links (HTTP ${res.statusCode})');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => ContactLinkDto.fromJson(e)).toList();
  }

  Future<ContactLinkDto> createLink({
    required int userId,
    required String label,
    required String url,
    String? kind,
    int? order,
  }) async {
    final uri = Uri.parse('$_base/api/contact-links');
    final body = jsonEncode({
      'userId': userId,
      'label': label,
      'url': url,
      'kind': kind,
      'order': order,
    });
    final res = await http.post(uri, headers: _headers(), body: body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create link (HTTP ${res.statusCode})');
    }
    // Many APIs return the created entity; if yours returns empty body on 201, the UI
    // already re-fetches after save, so this value isn’t relied upon.
    return res.body.isNotEmpty
        ? ContactLinkDto.fromJson(jsonDecode(res.body))
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
    final res = await http.put(uri, headers: _headers(), body: body);
    if (res.statusCode != 200) {
      throw Exception('Failed to update link (HTTP ${res.statusCode})');
    }
    return ContactLinkDto.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteLink(int id) async {
    final uri = Uri.parse('$_base/api/contact-links/$id');
    final res = await http.delete(uri, headers: _headers());
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete link (HTTP ${res.statusCode})');
    }
  }
}
