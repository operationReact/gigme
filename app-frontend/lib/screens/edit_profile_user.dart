import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/profile_api.dart';
import '../services/session_service.dart';
import 'package:file_picker/file_picker.dart';
import '../services/s3_service.dart';
import '../env.dart';
import 'dart:io' show File;

/// ─────────────────────────────────────────────────────────────────────────────
/// Brand palette (kept inline so this file is standalone)
const _kTeal = Color(0xFF00C2A8);
const _kIndigo = Color(0xFF3B82F6);
const _kViolet = Color(0xFF7C3AED);
const _kHeading = Color(0xFF111827);

/// Tiny model to hold dynamic links
class ContactLink {
  String label;
  String url;
  ContactLink({required this.label, required this.url});

  Map<String, dynamic> toJson() => {'label': label, 'url': url};
  static ContactLink fromJson(Map<String, dynamic> j) =>
      ContactLink(label: (j['label'] ?? '').toString(), url: (j['url'] ?? '').toString());
}

class ProfileUserPage extends StatefulWidget {
  /// EDIT profile route
  static const routeName = '/profile/user';
  const ProfileUserPage({super.key});

  @override
  State<ProfileUserPage> createState() => _ProfileUserPageState();
}

class _ProfileUserPageState extends State<ProfileUserPage> {
  final _formKey = GlobalKey<FormState>();
  bool _dirty = false;
  bool _loading = false;

  // Controllers (mock initial data)
  final _nameCtrl = TextEditingController(text: 'Your Name');
  final _headlineCtrl = TextEditingController(text: 'Freelancer • Mobile & Web');
  final _locationCtrl = TextEditingController(text: 'Remote • Worldwide');
  final _emailCtrl = TextEditingController(text: 'email@example.com');
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController(text: 'your-portfolio.com'); // kept for backward-compat
  final _linkedinCtrl = TextEditingController(); // kept for backward-compat
  final _githubCtrl = TextEditingController(); // kept for backward-compat
  final _bioCtrl = TextEditingController(
    text:
    'Short bio goes here. Highlight your experience, niche and recent wins. Keep it concise and outcome-focused.',
  );
  final _rateCtrl = TextEditingController(text: '60');

  String _currency = 'USD';
  bool _available = true;

  // Avatar url and upload flag
  String? _imageUrl;
  bool _uploadingAvatar = false;

  // Skills editor
  final _skillCtrl = TextEditingController();
  final List<String> _skills = ['Flutter', 'Dart', 'Firebase', 'REST APIs'];

  // ── NEW: Dynamic link editor state
  final List<ContactLink> _links = [];
  final _urlReg = RegExp(r'^(https?:\/\/)[^\s/$.?#].[^\s]*$', caseSensitive: false);

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameCtrl,
      _headlineCtrl,
      _locationCtrl,
      _emailCtrl,
      _phoneCtrl,
      _websiteCtrl,
      _linkedinCtrl,
      _githubCtrl,
      _bioCtrl,
      _rateCtrl,
    ]) {
      c.addListener(() => setState(() => _dirty = true));
    }
    _prefill();
  }

  Future<void> _prefill() async {
    final user = SessionService.instance.user;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final dto = await ProfileApi().getFreelancer(user.id);
      if (dto != null) {
        _nameCtrl.text = dto.displayName;
        if ((dto.professionalTitle ?? '').isNotEmpty) {
          _headlineCtrl.text = dto.professionalTitle!;
        }
        if ((dto.location ?? '').isNotEmpty) _locationCtrl.text = dto.location!;
        if ((dto.contactEmail ?? '').isNotEmpty) _emailCtrl.text = dto.contactEmail!;
        if ((dto.phone ?? '').isNotEmpty) _phoneCtrl.text = dto.phone!;
        if ((dto.website ?? '').isNotEmpty) _websiteCtrl.text = dto.website!;
        if ((dto.linkedin ?? '').isNotEmpty) _linkedinCtrl.text = dto.linkedin!;
        if ((dto.github ?? '').isNotEmpty) _githubCtrl.text = dto.github!;
        if ((dto.bio ?? '').isNotEmpty) _bioCtrl.text = dto.bio!;
        if (dto.hourlyRateCents != null) {
          final cents = dto.hourlyRateCents!;
          final value = cents / 100.0;
          String s = value.toStringAsFixed(2);
          if (s.endsWith('.00')) s = s.substring(0, s.length - 3);
          if (s.contains('.') && s.endsWith('0')) s = s.substring(0, s.length - 1);
          _rateCtrl.text = s;
        }
        if ((dto.currency ?? '').isNotEmpty) {
          const allowed = ['USD', 'EUR', 'GBP', 'INR'];
          _currency = allowed.contains(dto.currency) ? dto.currency! : _currency;
        }
        if (dto.available != null) _available = dto.available!;
        final csv = (dto.skillsCsv ?? '').trim();
        if (csv.isNotEmpty) {
          _skills
            ..clear()
            ..addAll(csv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
        }
        final img = (dto.imageUrl ?? '').trim();
        if (img.isNotEmpty) _imageUrl = img;

        // ── Prefill dynamic links from dto.extraJson or dto.socialLinksJson; else fallback to old fields
        _links.clear();
        bool filledFromJson = false;

        // Option A: dto.extraJson (generic JSON blob)
        final rawExtraJson = (dto.extraJson ?? '').trim();
        if (rawExtraJson.isNotEmpty) {
          try {
            final map = jsonDecode(rawExtraJson) as Map<String, dynamic>;
            final arr = (map['socialLinks'] as List?) ?? [];
            for (final e in arr) {
              _links.add(ContactLink.fromJson(Map<String, dynamic>.from(e as Map)));
            }
            filledFromJson = _links.isNotEmpty;
          } catch (_) {}
        }

        // Option B: dto.socialLinksJson (if you already have a dedicated field)
        if (!filledFromJson) {
          final rawSocial = (dto.socialLinksJson ?? '').trim();
          if (rawSocial.isNotEmpty) {
            try {
              final arr = jsonDecode(rawSocial) as List;
              for (final e in arr) {
                _links.add(ContactLink.fromJson(Map<String, dynamic>.from(e as Map)));
              }
              filledFromJson = _links.isNotEmpty;
            } catch (_) {}
          }
        }

        // Fallback: build from legacy discrete fields
        if (!filledFromJson) {
          if ((dto.website ?? '').trim().isNotEmpty) {
            _links.add(ContactLink(label: 'Website', url: dto.website!.trim()));
          }
          if ((dto.linkedin ?? '').trim().isNotEmpty) {
            _links.add(ContactLink(label: 'LinkedIn', url: dto.linkedin!.trim()));
          }
          if ((dto.github ?? '').trim().isNotEmpty) {
            _links.add(ContactLink(label: 'GitHub', url: dto.github!.trim()));
          }
        }

        // Reset dirty after prefill
        _dirty = false;
      }
    } catch (_) {
      // ignore prefill errors; user can still edit
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _headlineCtrl,
      _locationCtrl,
      _emailCtrl,
      _phoneCtrl,
      _websiteCtrl,
      _linkedinCtrl,
      _githubCtrl,
      _bioCtrl,
      _rateCtrl,
      _skillCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final cs = Theme.of(context).colorScheme;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved edits. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = SessionService.instance.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in')),
      );
      return;
    }
    try {
      final rateStr = _rateCtrl.text.trim();
      final rate = rateStr.isEmpty ? null : double.tryParse(rateStr);
      final cents = rate == null ? null : (rate * 100).round();
      final skillsCsv = _skills.isEmpty ? null : _skills.join(', ');

      // Build social links JSON and embed inside a generic extraJson map
      final socialJsonArr = _links.map((e) => e.toJson()).toList();
      final extraJson = jsonEncode({'socialLinks': socialJsonArr});

      await ProfileApi().upsertFreelancer(
        user.id,
        displayName: _nameCtrl.text.trim(),
        professionalTitle: _headlineCtrl.text.trim().isEmpty ? null : _headlineCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        skillsCsv: skillsCsv,
        imageUrl: _imageUrl, // persist avatar url
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        contactEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),

        // legacy discrete fields (keep for backward compatibility)
        website: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        linkedin: _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        github: _githubCtrl.text.trim().isEmpty ? null : _githubCtrl.text.trim(),

        hourlyRateCents: cents,
        currency: _currency,
        available: _available,

        // ── NEW: generic JSON blob to store dynamic links
        extraJson: extraJson,
        // If you already have a dedicated field, you could also pass:
        // socialLinksJson: jsonEncode(socialJsonArr),
      );

      if (!mounted) return;
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  InputDecoration _decoration(BuildContext context, String label, {String? hint, Widget? prefix}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(0.24),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.7))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.secondary, width: 1.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // route already popped (e.g., not dirty)
        () async {
          final ok = await _confirmDiscard();
          if (ok && mounted) Navigator.of(context).pop();
        }();
      },
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await _confirmDiscard();
                      if (ok && mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Discard'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: cs.secondary.withOpacity(0.6)),
                      foregroundColor: cs.secondary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save changes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: cs.secondary,
                      foregroundColor: cs.onSecondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            // ── Slim, pinned gradient header ────��───────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () async {
                  final ok = await _confirmDiscard();
                  if (ok && mounted) Navigator.of(context).pop();
                },
              ),
              title: const _GmwLogo(markSize: 22, fontSize: 18, onDark: true),
              flexibleSpace: LayoutBuilder(
                builder: (_, __) {
                  final cs = Theme.of(context).colorScheme;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cs.secondary, cs.tertiary],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                        child: Text(
                          'Edit Profile',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Form ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_loading) const LinearProgressIndicator(minHeight: 2),

                          _HeaderCard(
                            nameCtrl: _nameCtrl,
                            headlineCtrl: _headlineCtrl,
                            onChanged: () => setState(() => _dirty = true),
                            onChangePhoto: _changePhoto,
                            onRemovePhoto: _removePhoto,
                            imageUrl: _imageUrl,
                          ),
                          const SizedBox(height: 10),

                          // BASIC INFO
                          _EditSection(
                            title: 'Basic info',
                            child: _ResponsiveColumns(
                              children: [
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: _decoration(context, 'Full name',
                                      prefix: const Icon(Icons.person_rounded)),
                                  validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                                ),
                                TextFormField(
                                  controller: _headlineCtrl,
                                  decoration: _decoration(context, 'Headline (what you do)',
                                      prefix: const Icon(Icons.badge_outlined)),
                                ),
                                TextFormField(
                                  controller: _locationCtrl,
                                  decoration: _decoration(context, 'Location',
                                      prefix: const Icon(Icons.location_on_outlined)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // CONTACT
                          _EditSection(
                            title: 'Contact',
                            child: Column(
                              children: [
                                _ResponsiveColumns(
                                  children: [
                                    TextFormField(
                                      controller: _emailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: _decoration(context, 'Email',
                                          prefix: const Icon(Icons.email_outlined)),
                                      validator: (v) {
                                        final ok =
                                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '');
                                        return ok ? null : 'Enter a valid email';
                                      },
                                    ),
                                    TextFormField(
                                      controller: _phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: _decoration(context, 'Phone (optional)',
                                          prefix: const Icon(Icons.phone_outlined)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _ContactLinksEditor(
                                  links: _links,
                                  onChanged: () => setState(() => _dirty = true),
                                  urlValidator: (s) => _urlReg.hasMatch(s),
                                  decorationBuilder:
                                      (label, {prefix}) => _decoration(context, label, prefix: prefix),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ABOUT
                          _EditSection(
                            title: 'About',
                            child: TextFormField(
                              controller: _bioCtrl,
                              minLines: 4,
                              maxLines: 8,
                              decoration: _decoration(context, 'Short bio'),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // SKILLS
                          _EditSection(
                            title: 'Skills',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final s in _skills)
                                      InputChip(
                                        label: Text(s),
                                        onDeleted: () {
                                          setState(() {
                                            _skills.remove(s);
                                            _dirty = true;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _skillCtrl,
                                        decoration: _decoration(context, 'Add a skill'),
                                        onSubmitted: (_) => _addSkill(),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    FilledButton.icon(
                                      onPressed: _addSkill,
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Add'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // RATES & AVAILABILITY
                          _EditSection(
                            title: 'Rates & availability',
                            child: _ResponsiveColumns(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _rateCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(
                                            decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                                        ],
                                        decoration: _decoration(context, 'Hourly rate'),
                                        validator: (v) {
                                          final t = (v ?? '').trim();
                                          if (t.isEmpty) return null; // optional
                                          final n = double.tryParse(t);
                                          return (n == null) ? 'Enter a number' : null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 110,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _currency,
                                        decoration: _decoration(context, 'Currency'),
                                        items: const [
                                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                                          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                                          DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                                          DropdownMenuItem(value: 'INR', child: Text('INR')),
                                        ],
                                        onChanged: (v) => setState(() {
                                          _currency = v ?? _currency;
                                          _dirty = true;
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Switch(
                                      value: _available,
                                      onChanged: (v) => setState(() {
                                        _available = v;
                                        _dirty = true;
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _available
                                            ? 'Open to new projects'
                                            : 'Not currently available',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSkill() {
    final s = _skillCtrl.text.trim();
    if (s.isEmpty) return;
    if (_skills.contains(s)) {
      _skillCtrl.clear();
      return;
    }
    setState(() {
      _skills.add(s);
      _skillCtrl.clear();
      _dirty = true;
    });
  }

  // ── Avatar actions (UI ready; wire to your picker/uploader)
  void _changePhoto() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAndUploadAvatar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(ctx);
                // Camera capture typically uses image_picker; using gallery for now
                await _pickAndUploadAvatar();
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;
    final user = SessionService.instance.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in required')),
      );
      return;
    }
    try {
      setState(() => _uploadingAvatar = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.single;
      final bytes = f.bytes;
      List<int> data;
      if (bytes != null) {
        data = bytes;
      } else if ((f.path ?? '').isNotEmpty) {
        // ignore: avoid_web_libraries_in_flutter
        data = await File(f.path!).readAsBytes();
      } else {
        throw Exception('No file data');
      }
      // Optional: basic size guard (10MB)
      if (data.length > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose an image under 10 MB')),
        );
        return;
      }
      final ext = (f.extension ?? 'jpg').toLowerCase();
      final key = 'avatars/${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final presigned = await S3Service.getPresignedUploadUrl(key);
      await S3Service.uploadBytesToS3(presigned, data);
      final publicUrl = EnvConfig.s3FileUrl(key);
      if (!mounted) return;
      setState(() {
        _imageUrl = publicUrl;
        _dirty = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded. Don\'t forget to Save.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _removePhoto() {
    setState(() {
      _imageUrl = null;
      _dirty = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo removed. Don\'t forget to Save.')),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Header card with avatar + inline name/headline editing
class _HeaderCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController headlineCtrl;
  final VoidCallback onChanged;
  final VoidCallback onChangePhoto;
  final VoidCallback onRemovePhoto;
  final String? imageUrl;

  const _HeaderCard({
    required this.nameCtrl,
    required this.headlineCtrl,
    required this.onChanged,
    required this.onChangePhoto,
    required this.onRemovePhoto,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    InputDecoration dec(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(0.18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.secondary, width: 1.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // avatar + quick actions
            Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: cs.secondary.withOpacity(0.20),
                      backgroundImage: imageUrl == null || imageUrl!.isEmpty ? null : NetworkImage(imageUrl!),
                      child: (imageUrl == null || imageUrl!.isEmpty)
                          ? Icon(Icons.person_outline,
                          size: 44, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    Material(
                      color: cs.secondary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onChangePhoto,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextButton(onPressed: onChangePhoto, child: const Text('Change photo')),
                TextButton(
                  onPressed: onRemovePhoto,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Remove'),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // inline name + headline
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    onChanged: (_) => onChanged(),
                    decoration: dec('Full name'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: headlineCtrl,
                    onChanged: (_) => onChanged(),
                    decoration: dec('Headline'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand section wrapper with subtle title bar
class _EditSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _EditSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.titleMedium?.color;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 5,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(colors: [cs.secondary, cs.tertiary]),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Responsive grid: 1 column on narrow, 2 on wide
class _ResponsiveColumns extends StatelessWidget {
  final List<Widget> children;
  const _ResponsiveColumns({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final twoCol = c.maxWidth >= 720;
        if (!twoCol) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        // two columns
        final left = <Widget>[];
        final right = <Widget>[];
        for (int i = 0; i < children.length; i++) {
          (i.isEven ? left : right).add(children[i]);
        }
        Widget col(List<Widget> list) => Column(
          children: [
            for (int i = 0; i < list.length; i++) ...[
              list[i],
              if (i < list.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: col(left)),
            const SizedBox(width: 12),
            Expanded(child: col(right)),
          ],
        );
      },
    );
  }
}

/// Small GigMeWork logo used in headers
class _GmwLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final bool onDark;
  const _GmwLogo({this.markSize = 26, this.fontSize = 20, this.onDark = false, super.key});

  @override
  Widget build(BuildContext context) {
    final head = onDark ? Colors.white : _kHeading;
    final wordmark = Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Gig', style: TextStyle(color: head, fontWeight: FontWeight.w700)),
        const TextSpan(text: 'Me', style: TextStyle(color: _kTeal, fontWeight: FontWeight.w700)),
        TextSpan(text: 'Work', style: TextStyle(color: head, fontWeight: FontWeight.w700)),
      ]),
      style: TextStyle(fontSize: fontSize, height: 1.0, letterSpacing: 0.2),
    );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _GmwMark(size: markSize),
      const SizedBox(width: 8),
      wordmark,
    ]);
  }
}

class _GmwMark extends StatelessWidget {
  final double size;
  const _GmwMark({required this.size});

  @override
  Widget build(BuildContext context) {
    final h = size;
    final w = size * 1.7;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Container(width: h, height: h, decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle))),
          Align(
              alignment: Alignment.centerRight,
              child: Container(width: h, height: h, decoration: const BoxDecoration(color: _kViolet, shape: BoxShape.circle))),
          Container(
            width: w * 0.74,
            height: h * 0.34,
            decoration: BoxDecoration(
              color: _kIndigo,
              borderRadius: BorderRadius.circular(h),
              border: Border.all(color: Colors.white, width: h * 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────��───────────────────────────────────────────────────
/// Dynamic Links Editor
class _ContactLinksEditor extends StatefulWidget {
  final List<ContactLink> links;
  final VoidCallback onChanged;
  final bool Function(String) urlValidator;
  final InputDecoration Function(String, {Widget? prefix}) decorationBuilder;

  const _ContactLinksEditor({
    required this.links,
    required this.onChanged,
    required this.urlValidator,
    required this.decorationBuilder,
  });

  @override
  State<_ContactLinksEditor> createState() => _ContactLinksEditorState();
}

class _ContactLinksEditorState extends State<_ContactLinksEditor> {
  void _addEmpty() {
    setState(() {
      widget.links.add(ContactLink(label: '', url: ''));
    });
    widget.onChanged();
  }

  Icon _iconForLink(String label, String url) {
    final t = (label + ' ' + url).toLowerCase();
    if (t.contains('linkedin') || t.contains('lnkd')) return const Icon(Icons.business_outlined);
    if (t.contains('github')) return const Icon(Icons.code_outlined);
    if (t.contains('twitter') || t.contains('x.com')) return const Icon(Icons.alternate_email);
    if (t.contains('youtube')) return const Icon(Icons.play_circle_outline);
    if (t.contains('instagram')) return const Icon(Icons.camera_alt_outlined);
    if (t.contains('facebook')) return const Icon(Icons.facebook_outlined);
    if (t.contains('behance')) return const Icon(Icons.palette_outlined);
    if (t.contains('dribbble')) return const Icon(Icons.sports_basketball_outlined);
    return const Icon(Icons.link_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget row(int i) {
      final item = widget.links[i];
      final labelCtrl = TextEditingController(text: item.label);
      final urlCtrl = TextEditingController(text: item.url);

      void writeBack() {
        item.label = labelCtrl.text.trim();
        item.url = urlCtrl.text.trim();
        widget.onChanged();
        setState(() {}); // to refresh icon when label/url changes
      }

      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: labelCtrl,
                      onChanged: (_) => writeBack(),
                      decoration: widget.decorationBuilder('Label', prefix: const Icon(Icons.label_rounded)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: urlCtrl,
                      onChanged: (_) => writeBack(),
                      decoration: widget.decorationBuilder('Link (https://...)',
                          prefix: _iconForLink(labelCtrl.text, urlCtrl.text)),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Required';
                        return widget.urlValidator(t) ? null : 'Invalid URL';
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() => widget.links.removeAt(i));
                      widget.onChanged();
                    },
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(colors: [cs.secondary, cs.tertiary]),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Links (add any: website, LinkedIn, GitHub, portfolio, etc.)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _addEmpty,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add link'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.links.isEmpty)
          OutlinedButton.icon(
            onPressed: _addEmpty,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add your first link'),
          )
        else
          Column(
            children: [for (int i = 0; i < widget.links.length; i++) row(i)],
          ),
      ],
    );
  }
}
