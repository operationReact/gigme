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
}

