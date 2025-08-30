import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Stub widgets (remove if already imported from elsewhere)
class HoverScale extends StatelessWidget {
  final Widget child;
  const HoverScale({required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({required this.child});
  @override
  Widget build(BuildContext context) => Card(child: child);
}

class ProfilePreviewCard extends StatelessWidget {
  final String name;
  final String title;
  final String bio;
  final List<String> skills;
  final String? imageUrl;

  const ProfilePreviewCard({
    super.key,
    required this.name,
    required this.title,
    required this.bio,
    required this.skills,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return HoverScale(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              CircleAvatar(
                radius: 40,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null ? Icon(Icons.person, size: 40, color: Colors.grey.shade400) : null,
                backgroundColor: Colors.grey.shade100,
              ),
              const SizedBox(width: 24),
              // Profile details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: skills.map((skill) => Chip(
                        label: Text(skill, style: GoogleFonts.openSans(fontSize: 13)),
                        backgroundColor: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

