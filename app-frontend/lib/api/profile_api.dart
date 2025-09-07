import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class FreelancerProfileDto {
  final int id;
  final int userId;
  final String displayName;
  final String? professionalTitle;
  final String? bio;
  final String? skillsCsv;
  final String? imageUrl;
  final String? location;
  final String? contactEmail;
  final String? phone;
  final String? website;
  final String? linkedin;
  final String? github;
  final int? hourlyRateCents;
  final String? currency;
  final bool? available;
  FreelancerProfileDto({
    required this.id,
    required this.userId,
    required this.displayName,
    this.professionalTitle,
    this.bio,
    this.skillsCsv,
    this.imageUrl,
    this.location,
    this.contactEmail,
    this.phone,
    this.website,
    this.linkedin,
    this.github,
    this.hourlyRateCents,
    this.currency,
    this.available,
  });
  factory FreelancerProfileDto.fromJson(Map<String,dynamic> j) => FreelancerProfileDto(
    id: j['id'] as int,
    userId: j['userId'] as int,
    displayName: j['displayName'] as String,
    professionalTitle: j['professionalTitle'] as String?,
    bio: j['bio'] as String?,
    skillsCsv: j['skillsCsv'] as String?,
    imageUrl: j['imageUrl'] as String?,
    location: j['location'] as String?,
    contactEmail: j['contactEmail'] as String?,
    phone: j['phone'] as String?,
    website: j['website'] as String?,
    linkedin: j['linkedin'] as String?,
    github: j['github'] as String?,
    hourlyRateCents: j['hourlyRateCents'] as int?,
    currency: j['currency'] as String?,
    available: j['available'] as bool?,
  );
}

class ClientProfileDto {
  final int id;
  final int userId;
  final String companyName;
  final String? website;
  final String? description;
  ClientProfileDto({required this.id, required this.userId, required this.companyName, this.website, this.description});
  factory ClientProfileDto.fromJson(Map<String,dynamic> j) => ClientProfileDto(
    id: j['id'] as int,
    userId: j['userId'] as int,
    companyName: j['companyName'] as String,
    website: j['website'] as String?,
    description: j['description'] as String?,
  );
}

class ProfileApi {
  final _client = ApiClient.instance;

  Future<FreelancerProfileDto?> getFreelancer(int userId) async {
    final res = await _client.get('/api/freelancers/$userId/profile');
    if (res.statusCode == 200) {
      return FreelancerProfileDto.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 404) return null;
    throw Exception('Failed to load freelancer profile (${res.statusCode})');
  }

  Future<ClientProfileDto?> getClient(int userId) async {
    final res = await _client.get('/api/clients/$userId/profile');
    if (res.statusCode == 200) {
      return ClientProfileDto.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 404) return null;
    throw Exception('Failed to load client profile (${res.statusCode})');
  }

  Future<FreelancerProfileDto> upsertFreelancer(
    int userId, {
    required String displayName,
    String? professionalTitle,
    String? bio,
    String? skillsCsv,
    String? imageUrl,
    String? location,
    String? contactEmail,
    String? phone,
    String? website,
    String? linkedin,
    String? github,
    int? hourlyRateCents,
    String? currency,
    bool? available,
  }) async {
    final body = {
      'displayName': displayName,
      'professionalTitle': professionalTitle,
      'bio': bio,
      'skillsCsv': skillsCsv,
      'imageUrl': imageUrl,
      'location': location,
      'contactEmail': contactEmail,
      'phone': phone,
      'website': website,
      'linkedin': linkedin,
      'github': github,
      'hourlyRateCents': hourlyRateCents,
      'currency': currency,
      'available': available,
    };
    final res = await _client.put('/api/freelancers/$userId/profile', body: body);
    if (res.statusCode == 200) {
      return FreelancerProfileDto.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to save freelancer profile (${res.statusCode})');
  }

  Future<ClientProfileDto> upsertClient(int userId,{required String companyName, String? website, String? description}) async {
    final res = await _client.put('/api/clients/$userId/profile', body: {
      'companyName': companyName,
      'website': website,
      'description': description,
    });
    if (res.statusCode == 200) {
      return ClientProfileDto.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to save client profile (${res.statusCode})');
  }
}
