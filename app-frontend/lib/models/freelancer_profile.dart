class FreelancerProfile {
  final String displayName;
  final String professionalTitle;
  final String bio;
  final String? skillsCsv;
  final String? imageUrl;

  FreelancerProfile({
    required this.displayName,
    required this.professionalTitle,
    required this.bio,
    this.skillsCsv,
    this.imageUrl,
  });

  factory FreelancerProfile.fromJson(Map<String, dynamic> json) {
    return FreelancerProfile(
      displayName: json['displayName'] ?? '',
      professionalTitle: json['professionalTitle'] ?? '',
      bio: json['bio'] ?? '',
      skillsCsv: json['skillsCsv'],
      imageUrl: json['imageUrl'],
    );
  }
}

