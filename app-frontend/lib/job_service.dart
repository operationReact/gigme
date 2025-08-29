import 'dart:convert';
import 'package:http/http.dart' as http;
import 'env.dart';

class Job {
  final int id;
  final String title;
  final String? description;
  Job({required this.id, required this.title, this.description});
  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
      );
}

class JobService {
  final String _base = EnvConfig.apiBaseUrl;

  Future<List<Job>> listJobs() async {
    final res = await http.get(Uri.parse('$_base/api/jobs'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load jobs: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Job> createJob(String title, {String? description}) async {
    final res = await http.post(
      Uri.parse('$_base/api/jobs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'description': description}),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to create job: ${res.statusCode} ${res.body}');
    }
    return Job.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<int> countNewJobs() async {
    final res = await http.get(Uri.parse('$_base/api/jobs/new/count'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load new jobs count: \\${res.statusCode}');
    }
    final body = res.body.trim();
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['count'] != null) {
        return (decoded['count'] as num).toInt();
      }
      if (decoded is num) {
        return decoded.toInt();
      }
    } catch (_) {
      // Not JSON, try parsing as int
      final n = int.tryParse(body);
      if (n != null) return n;
    }
    throw Exception('Unexpected response for new jobs count: $body');
  }

  Future<List<Job>> listOpenJobs() async {
    final res = await http.get(Uri.parse('$_base/api/jobs/open'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load open jobs: \\${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> applyForJob(int jobId, String freelancerEmail) async {
    final res = await http.post(
      Uri.parse('$_base/api/jobs/$jobId/apply?freelancerEmail=$freelancerEmail'),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to apply for job: \\${res.statusCode}');
    }
  }
}
