// lib/screens/share_card_public.dart
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/home_api.dart';
import '../api/contact_api.dart';
import '../models/contact.dart';
import '../services/session_service.dart';

class ShareCardPublicPage extends StatefulWidget {
  static const routeName = '/card';

  /// Build a shareable URL (web: https://host/?u=<id>#/card, mobile: /card?u=<id>)
  static String buildUrlForUser(int userId) {
    final base = Uri.base;
    if (kIsWeb) {
      final url = Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        queryParameters: {'u': '$userId'},
        fragment: '/card',
      );
      return url.toString();
    }
    return '${ShareCardPublicPage.routeName}?u=$userId';
  }

  const ShareCardPublicPage({super.key});
  @override
  State<ShareCardPublicPage> createState() => _ShareCardPublicPageState();
}

class _ShareCardPublicPageState extends State<ShareCardPublicPage> {
  int? _userId;

  // Profile basics
  String _name = 'Your Name';
  String _title = 'Public Figure';
  String _bio = 'Building robust Flutter & Spring apps.';
  String? _imageUrl;

  // UI state
  bool _loadingProfile = true;
  bool _loadingLinks = true;
  String? _error;

  bool _darkMode = false;
  bool _gridMode = true;

  // Data
  List<ContactLinkDto> _links = [];
  Map<String, int> _clickCounts = {}; // key by url

  SharedPreferences? _prefs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureUserIdAndLoad();
  }

  Future<void> _ensureUserIdAndLoad() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final fromArgs = (args is Map && args['u'] != null)
        ? int.tryParse('${args['u']}')
        : null;
    final fromQuery = int.tryParse(Uri.base.queryParameters['u'] ?? '');
    final fromSession = SessionService.instance.user?.id;

    final incoming = fromArgs ?? fromQuery ?? fromSession;
    if (_userId == incoming && _userId != null) return;

    setState(() {
      _userId = incoming;
      _loadingProfile = true;
      _loadingLinks = true;
      _links = [];
      _error = null;
    });

    _prefs ??= await SharedPreferences.getInstance();

    // Load persisted toggles, with sane defaults
    final sysDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    _darkMode = _prefs?.getBool('card.dark') ?? sysDark;
    _gridMode = _prefs?.getBool('card.grid') ?? true;

    // Load saved click counts for this user
    _loadClickCounts();

    if (_userId == null) {
      setState(() {
        _loadingProfile = false;
        _loadingLinks = false;
      });
      return;
    }

    _loadProfile(_userId!);
    _loadLinks(_userId!);
  }

  void _loadClickCounts() {
    final key = 'card.clicks.${_userId ?? 0}';
    final raw = _prefs?.getString(key);
    if (raw != null) {
      final map = Map<String, dynamic>.from(jsonDecode(raw));
      _clickCounts = map.map((k, v) => MapEntry(k, (v as num).toInt()));
    } else {
      _clickCounts = {};
    }
    setState(() {});
  }

  void _saveClickCounts() {
    final key = 'card.clicks.${_userId ?? 0}';
    _prefs?.setString(key, jsonEncode(_clickCounts));
  }

  void _toggleDark() {
    setState(() => _darkMode = !_darkMode);
    _prefs?.setBool('card.dark', _darkMode);
  }

  void _toggleLayout() {
    setState(() => _gridMode = !_gridMode);
    _prefs?.setBool('card.grid', _gridMode);
  }

  Future<void> _loadProfile(int uid) async {
    try {
      final dto = await HomeApi().getHome(uid);
      final name = (dto.displayName ?? '').trim();
      final title = (dto.professionalTitle ?? '').trim();
      final bio = (dto.bio ?? '').trim();
      final img = dto.imageUrl;

      setState(() {
        if (name.isNotEmpty) _name = name;
        if (title.isNotEmpty) _title = title;
        if (bio.isNotEmpty) _bio = bio;
        if (img != null && img.isNotEmpty) _imageUrl = img;
        _loadingProfile = false;
      });
    } catch (_) {
      setState(() {
        _loadingProfile = false;
        _error = 'Could not load profile.';
      });
    }
  }

  Future<void> _loadLinks(int uid) async {
    try {
      final items = await ContactApi().listLinksPublic(uid);

      // Sort by order if present, else by label
      items.sort((a, b) {
        final ao = a.order, bo = b.order;
        if (ao != null && bo != null) return ao.compareTo(bo);
        if (ao != null) return -1;
        if (bo != null) return 1;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });

      setState(() {
        _links = items;
        _loadingLinks = false;
      });
    } catch (_) {
      setState(() {
        _loadingLinks = false;
        _error = 'Could not load links.';
      });
    }
  }

  Future<void> _copyShareUrl() async {
    final id = _userId;
    if (id == null) return;
    final url = ShareCardPublicPage.buildUrlForUser(id);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share link copied')),
    );
  }

  Future<void> _showShareSheet() async {
    final id = _userId;
    if (id == null) return;
    final url = ShareCardPublicPage.buildUrlForUser(id);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: _darkMode ? const Color(0xFF0F172A) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.copy_rounded, color: _darkMode ? Colors.white : null),
            title: const Text('Copy link'),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share link copied')),
                );
              }
            },
          ),
          ListTile(
            leading:
            Icon(Icons.qr_code_rounded, color: _darkMode ? Colors.white : null),
            title: const Text('Show QR code'),
            onTap: () {
              Navigator.pop(context);
              _showQr(url);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showQr(String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _darkMode ? const Color(0xFF0F172A) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(16),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Scan to open',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _darkMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: 220, height: 220, child: QrImageView(data: url)),
        ]),
      ),
    );
  }

  Future<void> _open(String url) async {
    String u = url.trim();

    if (u.startsWith('mailto:') || u.startsWith('tel:')) {
      final ok = await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open')));
      }
      _bumpAnalytics(url);
      return;
    }

    if (u.contains('twitter.com')) {
      u = u.replaceFirst('twitter.com', 'x.com');
    }

    final fixed = _normalizeUrl(u);
    final uri = Uri.tryParse(fixed);
    if (uri == null) return;

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open')));
    } else {
      _bumpAnalytics(url);
    }
  }

  void _bumpAnalytics(String url) {
    final n = _clickCounts[url] ?? 0;
    setState(() => _clickCounts[url] = n + 1);
    _saveClickCounts();
    // Optionally: send to server here if you add an endpoint.
  }

  String _normalizeUrl(String u) {
    var v = u.trim();
    v = Uri.encodeFull(v);
    if (kIsWeb && v.startsWith('http://')) {
      v = v.replaceFirst('http://', 'https://');
    }
    if (!v.startsWith('http')) v = 'https://$v';
    return v;
  }

  IconData _iconFor(String url, String label) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    final l = label.toLowerCase();
    if (host.contains('linkedin') || l.contains('linkedin')) return Icons.work_outline;
    if (host.contains('github') || l.contains('github')) return Icons.code;
    if (host.contains('twitter') || host.contains('x.com') || l.contains('twitter')) {
      return Icons.alternate_email;
    }
    if (host.contains('youtube')) return Icons.ondemand_video;
    if (host.contains('instagram')) return Icons.camera_alt_outlined;
    if (host.contains('facebook')) return Icons.facebook;
    if (host.contains('t.me') || host.contains('telegram')) return Icons.send_outlined;
    if (host.contains('whatsapp')) return Icons.chat;
    if (host.contains('medium')) return Icons.article_outlined;
    return Icons.link;
  }

  List<Color> _brandGrad(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('github')) return const [Color(0xFF24292e), Color(0xFF57606a)];
    if (host.contains('linkedin')) return const [Color(0xFF0a66c2), Color(0xFF33a0ff)];
    if (host.contains('instagram')) return const [Color(0xFFf58529), Color(0xFFdd2a7b)];
    if (host.contains('twitter') || host.contains('x.com')) {
      return const [Color(0xFF1d9bf0), Color(0xFF0a68a8)];
    }
    if (host.contains('youtube')) return const [Color(0xFFff0000), Color(0xFFff6a6a)];
    if (host.contains('facebook')) return const [Color(0xFF1877f2), Color(0xFF6aa5ff)];
    if (host.contains('t.me') || host.contains('telegram')) {
      return const [Color(0xFF0088cc), Color(0xFF43b2e6)];
    }
    if (host.contains('whatsapp')) return const [Color(0xFF25D366), Color(0xFF5BF393)];
    return const [Color(0xFF3B82F6), Color(0xFF7C3AED)];
  }

  @override
  Widget build(BuildContext context) {
    final card = _CardContent(
      name: _name,
      title: _title,
      bio: _bio,
      imageUrl: _imageUrl,
      loadingLinks: _loadingLinks,
      links: _links,
      brandGrad: _brandGrad,
      iconFor: _iconFor,
      onShare: _showShareSheet,
      onOpen: _open,
      dark: _darkMode,
      grid: _gridMode,
      counts: _clickCounts,
      onToggleDark: _toggleDark,
      onToggleLayout: _toggleLayout,
    );

    return Scaffold(
      body: Stack(
        children: [
          AuroraBackground(
            intensity: 1.0,
            speedSeconds: 10,
            dark: _darkMode,
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Hover3D(child: card),
            ),
          ),
          if (_error != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _copyShareUrl,
        icon: const Icon(Icons.link),
        label: const Text('Copy Card Link'),
      ),
    );
  }
}

/* ----------------------------- Visual Widgets ---------------------------- */

class _CardContent extends StatelessWidget {
  final String name, title, bio;
  final String? imageUrl;
  final bool loadingLinks, dark, grid;
  final List<ContactLinkDto> links;
  final Map<String, int> counts;
  final void Function() onShare, onToggleDark, onToggleLayout;
  final List<Color> Function(String url) brandGrad;
  final IconData Function(String url, String label) iconFor;
  final void Function(String url) onOpen;

  const _CardContent({
    required this.name,
    required this.title,
    required this.bio,
    required this.imageUrl,
    required this.loadingLinks,
    required this.links,
    required this.brandGrad,
    required this.iconFor,
    required this.onShare,
    required this.onOpen,
    required this.dark,
    required this.grid,
    required this.counts,
    required this.onToggleDark,
    required this.onToggleLayout,
  });

  @override
  Widget build(BuildContext context) {
    final hasEmail = links.any((l) => l.url.startsWith('mailto:'));
    final hasTel = links.any((l) => l.url.startsWith('tel:'));

    const headerHeight = 66.0;

    final cardBg = dark ? const Color(0xCC0B1220) : Colors.white.withOpacity(.85);
    final headerGrad = dark
        ? const [Color(0xFF0EA5E9), Color(0xFF6366F1)]
        : const [Color(0xFF22D3EE), Color(0xFF3B82F6), Color(0xFF7C3AED)];

    final textMain = dark ? Colors.white : const Color(0xFF111827);
    final textSub = dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final bioColor = dark ? const Color(0xFFE5E7EB) : const Color(0xFF374151);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Card(
          margin: const EdgeInsets.all(20),
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          // ⬇️ Stack ensures the avatar draws above the seam
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header band (icons only)
                  Container(
                    height: headerHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: headerGrad,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            color: Colors.white,
                            tooltip: 'Switch layout',
                            onPressed: onToggleLayout,
                            icon: Icon(grid ? Icons.view_list : Icons.grid_view),
                          ),
                          IconButton(
                            color: Colors.white,
                            tooltip: dark ? 'Light mode' : 'Dark mode',
                            onPressed: onToggleDark,
                            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
                          ),
                          IconButton(
                            color: Colors.white,
                            tooltip: 'Share',
                            onPressed: onShare,
                            icon: const Icon(Icons.ios_share_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Space to accommodate the overlapping avatar
                  const SizedBox(height: 28),

                  // Name/Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                    child: Row(
                      children: [
                        const SizedBox(width: 72), // leave room for avatar circle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSub,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bio
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                      child: Text(
                        bio,
                        style: TextStyle(fontSize: 14, color: bioColor),
                      ),
                    ),
                  ),

                  // Quick contact row
                  if (hasEmail || hasTel)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          if (hasEmail)
                            _ChipButton(
                              icon: Icons.mail_outline,
                              label: 'Email',
                              dark: dark,
                              onTap: () {
                                final link =
                                links.firstWhere((l) => l.url.startsWith('mailto:'));
                                onOpen(link.url);
                              },
                            ),
                          if (hasTel) const SizedBox(width: 8),
                          if (hasTel)
                            _ChipButton(
                              icon: Icons.call_outlined,
                              label: 'Call',
                              dark: dark,
                              onTap: () {
                                final link =
                                links.firstWhere((l) => l.url.startsWith('tel:'));
                                onOpen(link.url);
                              },
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 6),

                  // Links
                  if (loadingLinks)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: List.generate(
                          3,
                              (i) => Padding(
                            padding: EdgeInsets.only(bottom: i == 2 ? 0 : 10),
                            child: _skeletonBar(
                              height: 46,
                              dark: dark,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (links.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text('No links yet',
                          style:
                          TextStyle(color: textSub, fontWeight: FontWeight.w500)),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: grid
                          ? _GridLinks(
                        links: links,
                        counts: counts,
                        dark: dark,
                        brandGrad: brandGrad,
                        iconFor: iconFor,
                        onOpen: onOpen,
                      )
                          : Column(
                        children: links
                            .map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LinkButton(
                            label: l.label,
                            url: l.url,
                            icon: iconFor(l.url, l.label),
                            gradient: brandGrad(l.url),
                            onTap: () => onOpen(l.url),
                            count: counts[l.url] ?? 0,
                            dark: dark,
                          ),
                        ))
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 6),
                  Opacity(
                    opacity: .7,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Text(
                        'GigMeWork • People Need People',
                        style: TextStyle(fontSize: 12, color: textSub),
                      ),
                    ),
                  ),
                ],
              ),

              // ⬇️ Avatar floats above header/body seam
              Positioned(
                left: 16,
                top: headerHeight - 32, // 64px avatar overlaps by ~half
                child: _HeaderAvatar(url: imageUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _skeletonBar({double height = 44, required bool dark}) => Container(
    height: height,
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF1F2937) : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

class _HeaderAvatar extends StatelessWidget {
  final String? url;
  const _HeaderAvatar({required this.url});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [Color(0xFF00C2A8), Color(0xFF3B82F6), Color(0xFF7C3AED), Color(0xFF00C2A8)],
              stops: [0, .33, .66, 1],
            ),
          ),
        ),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            image: (url != null && url!.isNotEmpty)
                ? DecorationImage(
              image: NetworkImage(kIsWeb && url!.startsWith('http://')
                  ? url!.replaceFirst('http://', 'https://')
                  : url!),
              fit: BoxFit.cover,
            )
                : null,
            color: Colors.white,
          ),
          child: (url == null || url!.isEmpty)
              ? const Icon(Icons.person, color: Color(0xFF6B7280))
              : null,
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dark;
  const _ChipButton(
      {required this.icon, required this.label, required this.onTap, required this.dark});
  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border:
          Border.all(color: dark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: dark ? Colors.white : const Color(0xFF374151)),
            const SizedBox(width: 6),
            Text(label,
                style:
                TextStyle(color: dark ? Colors.white : const Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ Interactions ----------------------------- */

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const PressableScale({super.key, required this.child, required this.onTap});
  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: GestureDetector(onTap: widget.onTap, child: widget.child),
      ),
    );
  }
}

/// Hover tilt wrapper (desktop/web only visually noticeable).
class Hover3D extends StatefulWidget {
  final Widget child;
  const Hover3D({super.key, required this.child});
  @override
  State<Hover3D> createState() => _Hover3DState();
}

class _Hover3DState extends State<Hover3D> {
  double _rx = 0, _ry = 0;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final size = box.size;
        final pos = e.localPosition;
        final dx = (pos.dx - size.width / 2) / (size.width / 2);
        final dy = (pos.dy - size.height / 2) / (size.height / 2);
        setState(() {
          _ry = dx * 0.07;
          _rx = -dy * 0.07;
        });
      },
      onExit: (_) => setState(() {
        _rx = 0;
        _ry = 0;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rx)
          ..rotateY(_ry),
        child: widget.child,
      ),
    );
  }
}

/* --------------------------- Background Animation ------------------------ */

class AuroraBackground extends StatefulWidget {
  final double intensity; // 0..1
  final int speedSeconds;
  final bool dark;
  const AuroraBackground(
      {super.key, this.intensity = .7, this.speedSeconds = 14, this.dark = false});
  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: Duration(seconds: widget.speedSeconds))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.intensity;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value * 2 * math.pi;
        final a = Alignment(0.9 * math.cos(t), 0.9 * math.sin(t));
        final b = Alignment(-0.9 * math.cos(t * .8), -0.7 * math.sin(t * .8));
        final d = Alignment(0.9 * math.cos(t * 1.2 + 1.2), 0.9 * math.sin(t * 1.2 + 1.2));

        final baseGrad = widget.dark
            ? const [Color(0xFF0B1220), Color(0xFF111827), Color(0xFF1F2937)]
            : const [Color(0xFF22D3EE), Color(0xFF3B82F6), Color(0xFF7C3AED)];

        final blob1 = widget.dark ? const Color(0x661C64F2) : const Color(0x8822D3EE);
        final blob2 = widget.dark ? const Color(0x6614B8A6) : const Color(0x883B82F6);
        final blob3 = widget.dark ? const Color(0x66A855F7) : const Color(0x887C3AED);

        return Stack(children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: baseGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          _blob(color: blob1, alignment: a, size: 520 * (1 + k)),
          _blob(color: blob2, alignment: b, size: 640 * (1 + k)),
          _blob(color: blob3, alignment: d, size: 700 * (1 + k)),
        ]);
      },
    );
  }

  Widget _blob({
    required Color color,
    required Alignment alignment,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(.9), color.withOpacity(0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

/* -------------------------- Link views + favicon ------------------------- */

Widget _faviconOrIcon(String url, IconData fallback, {double size = 20}) {
  final host = Uri.tryParse(url)?.host;
  if (host == null || host.isEmpty) return Icon(fallback, color: Colors.white);
  final f = 'https://www.google.com/s2/favicons?domain=$host&sz=64';
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Image.network(
      f,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(fallback, color: Colors.white),
    ),
  );
}

// List style button (pill)
class _LinkButton extends StatelessWidget {
  final String label;
  final String url;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int count;
  final bool dark;

  const _LinkButton({
    required this.label,
    required this.url,
    required this.icon,
    required this.gradient,
    required this.onTap,
    required this.count,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x17000000), blurRadius: 12, offset: Offset(0, 4))
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _faviconOrIcon(url, icon),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded, color: Colors.white),
                    ],
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _CounterPill(count: count, dark: false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Grid style circular buttons
class _GridLinks extends StatelessWidget {
  final List<ContactLinkDto> links;
  final Map<String, int> counts;
  final bool dark;
  final List<Color> Function(String url) brandGrad;
  final IconData Function(String url, String label) iconFor;
  final void Function(String url) onOpen;

  const _GridLinks({
    required this.links,
    required this.counts,
    required this.dark,
    required this.brandGrad,
    required this.iconFor,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    int cross = 2;
    if (width > 780) {
      cross = 4;
    } else if (width > 560) {
      cross = 3;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: links.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (_, i) {
        final l = links[i];
        final g = brandGrad(l.url);
        final ic = iconFor(l.url, l.label);
        final count = counts[l.url] ?? 0;
        return PressableScale(
          onTap: () => onOpen(l.url),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: g),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 14,
                              offset: Offset(0, 6))
                        ],
                      ),
                      child: Center(
                        child: _faviconOrIcon(l.url, ic, size: 28),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: _CounterPill(count: count, dark: false, compact: true),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CounterPill extends StatelessWidget {
  final int count;
  final bool dark;
  final bool compact;
  const _CounterPill({required this.count, required this.dark, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF111827) : Colors.white;
    final fg = dark ? Colors.white : const Color(0xFF111827);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: bg.withOpacity(.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: dark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
      ),
      child: Text('$count', style: TextStyle(fontSize: compact ? 10 : 11, color: fg)),
    );
  }
}
