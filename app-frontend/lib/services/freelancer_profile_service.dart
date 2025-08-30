import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/freelancer_profile.dart';
import '../env.dart';

class FreelancerProfileService {
  static Future<FreelancerProfile> fetchProfile(String userId) async {
    final String _base = EnvConfig.apiBaseUrl;
    final response = await http.get(Uri.parse('$_base/api/freelancer/$userId/profile'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return FreelancerProfile.fromJson(data);
    } else {
      throw Exception('Failed to load profile');
    }
  }
}
