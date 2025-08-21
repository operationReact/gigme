import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum PortfolioCategory { videos, photos, documents }

class ProfileFreelancerPage extends StatefulWidget {
  static const routeName = '/profile/freelancer';
  const ProfileFreelancerPage({super.key});

  @override
  State<ProfileFreelancerPage> createState() => _ProfileFreelancerPageState();
}

class _ProfileFreelancerPageState extends State<ProfileFreelancerPage> with SingleTickerProviderStateMixin {
  // Mock data
  double get averageRating => 4.6;
  int get reviewCount => 31;

  final List<_PortfolioItem> portfolio = const [
    _PortfolioItem(
      name: 'Landing Page Redesign',
      url: 'https://example.com/portfolio/landing_redesign.png',
    ),
    _PortfolioItem(
      name: 'Promo Video',
      url: 'https://example.com/portfolio/promo_video.mp4',
    ),
    _PortfolioItem(
      name: 'Case Study PDF',
      url: 'https://example.com/portfolio/case_study.pdf',
    ),
    _PortfolioItem(
      name: 'App Screens',
      url: 'https://example.com/portfolio/app_screens.jpg',
    ),
  ];

  PortfolioCategory _selected = PortfolioCategory.photos;

  late final AnimationController _introCtl;

  Animation<double> _seg(int index) {
    final start = (index * 0.12).clamp(0.0, 1.0);
    final end = (start + 0.6).clamp(0.0, 1.0);
    return CurvedAnimation(parent: _introCtl, curve: Interval(start, end, curve: Curves.easeOut));
  }

  @override
  void initState() {
    super.initState();
    _introCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  }

  @override
  void dispose() {
    _introCtl.dispose();
    super.dispose();
  }

  List<_PortfolioItem> get _filteredItems {
    return portfolio.where((item) {
      final url = item.url.toLowerCase();
      final isImage = url.endsWith('.png') || url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.gif');
      final isVideo = url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.webm');
      switch (_selected) {
        case PortfolioCategory.photos:
          return isImage;
        case PortfolioCategory.videos:
          return isVideo;
        case PortfolioCategory.documents:
          return !isImage && !isVideo;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Freelancer Profile')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.secondary.withOpacity(0.35), cs.tertiary.withOpacity(0.35)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header (stagger 0)
                    FadeTransition(
                      opacity: _seg(0),
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_seg(0)),
                        child: Card(
                          color: cs.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: cs.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: cs.secondary.withOpacity(0.15),
                                  child: Icon(Icons.person_outline, size: 36, color: cs.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Your Name', style: Theme.of(context).textTheme.titleLarge),
                                      const SizedBox(height: 4),
                                      Text('Freelancer • Mobile & Web', style: Theme.of(context).textTheme.bodyMedium),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: const [
                                          Chip(label: Text('Flutter')),
                                          Chip(label: Text('Dart')),
                                          Chip(label: Text('Firebase')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit Profile'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rating section (stagger 1)
                    FadeTransition(
                      opacity: _seg(1),
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_seg(1)),
                        child: _RatingCard(average: averageRating, count: reviewCount),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // About (stagger 2)
                    FadeTransition(
                      opacity: _seg(2),
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_seg(2)),
                        child: Card(
                          color: cs.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: cs.outlineVariant),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('About', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                SizedBox(height: 8),
                                Text(
                                  'Short bio goes here. Highlight your experience, niche and recent wins.',
                                ),
                                SizedBox(height: 16),
                                Text('Contact', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                SizedBox(height: 8),
                                Text('email@example.com'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Portfolio with category filters (stagger 3)
                    FadeTransition(
                      opacity: _seg(3),
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_seg(3)),
                        child: Card(
                          color: cs.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: cs.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Portfolio', style: Theme.of(context).textTheme.titleMedium),
                                    SegmentedButton<PortfolioCategory>(
                                      segments: const [
                                        ButtonSegment(
                                          value: PortfolioCategory.videos,
                                          label: Text('Videos'),
                                          icon: Icon(Icons.videocam_outlined),
                                        ),
                                        ButtonSegment(
                                          value: PortfolioCategory.photos,
                                          label: Text('Photos'),
                                          icon: Icon(Icons.image_outlined),
                                        ),
                                        ButtonSegment(
                                          value: PortfolioCategory.documents,
                                          label: Text('Documents'),
                                          icon: Icon(Icons.description_outlined),
                                        ),
                                      ],
                                      selected: {_selected},
                                      onSelectionChanged: (s) {
                                        if (s.isNotEmpty) {
                                          setState(() => _selected = s.first);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_filteredItems.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      'No items found in this section.',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  )
                                else
                                  _PortfolioGrid(items: _filteredItems),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                   ],
                 ),
               ),
             ),
           ),
         ),
       ),
     );
  }
}

class _RatingCard extends StatelessWidget {
  final double average;
  final int count;
  const _RatingCard({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _StarRow(rating: average),
            const SizedBox(width: 12),
            Text('${average.toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text('($count reviews)', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating; // 0..5
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5 && fullStars < 5;
    final emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);
    final color = Theme.of(context).colorScheme.secondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < fullStars; i++) Icon(Icons.star, color: color),
        if (hasHalf) Icon(Icons.star_half, color: color),
        for (var i = 0; i < emptyStars; i++) Icon(Icons.star_border, color: color),
      ],
    );
  }
}

class _PortfolioItem {
  final String name;
  final String url; // can be image, video, document or any file
  const _PortfolioItem({required this.name, required this.url});
}

class _PortfolioGrid extends StatelessWidget {
  final List<_PortfolioItem> items;
  const _PortfolioGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Portfolio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _PortfolioTile(item: item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  final _PortfolioItem item;
  const _PortfolioTile({required this.item});

  bool get _isImage => item.url.toLowerCase().endsWith('.png') || item.url.toLowerCase().endsWith('.jpg') || item.url.toLowerCase().endsWith('.jpeg') || item.url.toLowerCase().endsWith('.gif');
  bool get _isVideo => item.url.toLowerCase().endsWith('.mp4') || item.url.toLowerCase().endsWith('.mov') || item.url.toLowerCase().endsWith('.webm');

  Future<void> _open() async {
    final uri = Uri.parse(item.url);
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      // ignore: avoid_print
      print('Could not launch ${item.url}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _open,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPreview(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_isImage) {
      return Container(
        color: cs.secondary.withOpacity(0.08),
        child: Image.network(
          item.url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _IconPreview(icon: Icons.image_not_supported_outlined),
        ),
      );
    } else if (_isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: cs.secondary.withOpacity(0.08)),
          const Center(child: Icon(Icons.videocam_outlined, size: 40)),
        ],
      );
    } else {
      return const _IconPreview(icon: Icons.description_outlined);
    }
  }
}

class _IconPreview extends StatelessWidget {
  final IconData icon;
  const _IconPreview({required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.secondary.withOpacity(0.08),
      child: Icon(icon, size: 40, color: cs.primary),
    );
  }
}
