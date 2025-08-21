import 'dart:ui' as ui;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'profile_freelancer.dart';

class FreelancerHomePage extends StatelessWidget {
  static const routeName = '/home/freelancer';
  const FreelancerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Freelancer Home'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.secondary.withOpacity(0.25),
                  cs.tertiary.withOpacity(0.25),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GlassHeader(),
                  const SizedBox(height: 16),
                  _KpiRow(),
                  const SizedBox(height: 16),
                  _QuickActions(),
                  const SizedBox(height: 16),
                  _ActiveContracts(),
                  const SizedBox(height: 16),
                  _Recommendations(),
                  const SizedBox(height: 16),
                  _ScheduleMini(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showProfileMenu(context),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.secondary.withOpacity(0.2),
                  child: Icon(Icons.person_outline, color: cs.primary, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back, Satya Varma Lutukurthi', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Earning is a fun', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                color: cs.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _KpiTile(label: 'Earnings (M)', value: '\$3,480', icon: Icons.attach_money)),
        SizedBox(width: 12),
        Expanded(child: _KpiTile(label: 'Active Gigs', value: '4', icon: Icons.work_outline)),
        SizedBox(width: 12),
        Expanded(child: _KpiTile(label: 'Proposals', value: '7', icon: Icons.description_outlined)),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _KpiTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _ActionChip(icon: Icons.search, label: 'Find gigs', onTap: () {}),
              _ActionChip(icon: Icons.send_outlined, label: 'New proposal', onTap: () {}),
              _ActionChip(icon: Icons.schedule, label: 'Availability', onTap: () {}),
              _ActionChip(icon: Icons.account_balance_wallet_outlined, label: 'Withdraw', onTap: () {}),
              _ActionChip(icon: Icons.ios_share_outlined, label: 'Share card', onTap: () => _openVisitingCard(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.secondary.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.secondary.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _ActiveContracts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Contracts', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(onPressed: () {}, child: const Text('View all')),
                ],
              ),
              const SizedBox(height: 8),
              const _ContractTile(
                client: 'Acme Corp',
                role: 'Flutter App Revamp',
                progress: 0.65,
                due: 'Due in 5 days',
              ),
              const SizedBox(height: 10),
              const _ContractTile(
                client: 'Globex',
                role: 'Landing Page Polish',
                progress: 0.35,
                due: 'Due in 12 days',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContractTile extends StatelessWidget {
  final String client;
  final String role;
  final double progress;
  final String due;
  const _ContractTile({required this.client, required this.role, required this.progress, required this.due});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 18, child: Icon(Icons.business_outlined)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              Text(client, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text(due, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        )
      ],
    );
  }
}

class _Recommendations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recommended for you', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(onPressed: () {}, child: const Text('Refresh')),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _RecCard(title: 'Build Admin Panel', budget: '\$1200', tags: ['Flutter', 'Rest', 'Firebase']),
                    SizedBox(width: 12),
                    _RecCard(title: 'Portfolio Site', budget: '\$600', tags: ['Web', 'UI', 'Animations']),
                    SizedBox(width: 12),
                    _RecCard(title: 'Mobile MVP', budget: '\$3500', tags: ['Flutter', 'Payments', 'Maps']),
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

class _RecCard extends StatelessWidget {
  final String title;
  final String budget;
  final List<String> tags;
  const _RecCard({required this.title, required this.budget, required this.tags});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(budget, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((t) => Chip(label: Text(t))).toList(),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('View'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleMini extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Today', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('10:00 AM  Standup with Acme Corp', style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('2:30 PM   Design review (Globex)', style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showProfileMenu(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (ctx) {
      final size = MediaQuery.of(ctx).size;
      final maxWidth = size.width > 640 ? 540.0 : size.width * 0.92;
      final maxHeight = size.height * 0.82;
      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: maxWidth,
            height: maxHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    children: [
                      // Header bar with handle and close button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Scrollable content
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: cs.secondary.withOpacity(0.2),
                                  child: Icon(Icons.person_outline, color: cs.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Satya Varma Lutukurthi', style: Theme.of(context).textTheme.titleMedium),
                                      Text('satya@example.com', style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _copyProfileLink(context),
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy link'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _MenuGrid(
                              items: [
                                _MenuItem(Icons.person_outline, 'View profile', () => Navigator.of(context).pushNamed(ProfileFreelancerPage.routeName)),
                                _MenuItem(Icons.edit_outlined, 'Edit profile', () {}),
                                _MenuItem(Icons.photo_library_outlined, 'Portfolio', () => Navigator.of(context).pushNamed(ProfileFreelancerPage.routeName)),
                                _MenuItem(Icons.description_outlined, 'Proposals', () {}),
                                _MenuItem(Icons.work_outline, 'Contracts', () {}),
                                _MenuItem(Icons.account_balance_wallet_outlined, 'Wallet', () {}),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _MenuTile(
                              icon: Icons.ios_share_outlined,
                              title: 'Share visiting card',
                              subtitle: 'Share a compact profile card with clients',
                              onTap: () {
                                Navigator.of(ctx).maybePop();
                                _openVisitingCard(context);
                              },
                            ),
                            const SizedBox(height: 8),
                            _AvailabilityTile(),
                            const Divider(height: 24),
                            _MenuTile(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'Theme, notifications, privacy', onTap: () {}),
                            _MenuTile(icon: Icons.language_outlined, title: 'Language & region', subtitle: 'English (US), GMT+5:30', onTap: () {}),
                            _MenuTile(icon: Icons.help_center_outlined, title: 'Help & support', subtitle: 'FAQs, contact support', onTap: () {}),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.logout),
                              label: const Text('Sign out'),
                            ),
                          ],
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
    },
  );
}

void _openVisitingCard(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  const name = 'Satya Varma Lutukurthi';
  const title = 'Flutter Developer';
  const email = 'satya@example.com';
  const profileLink = 'https://gigmework.app/u/satya'; // placeholder

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: cs.secondary.withOpacity(0.2),
                        child: Icon(Icons.person_outline, color: cs.primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: Theme.of(context).textTheme.titleMedium),
                            Text(title, style: Theme.of(context).textTheme.bodyMedium),
                            Text(email, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyProfileLink(context, link: profileLink),
                          icon: const Icon(Icons.link),
                          label: const Text('Copy link'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareVisitingCard(context, link: profileLink, name: name, title: title),
                          icon: const Icon(Icons.ios_share_outlined),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(ProfileFreelancerPage.routeName),
                    child: const Text('View full profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _shareVisitingCard(BuildContext context, {required String link, required String name, required String title}) {
  final message = 'Check out $name — $title on GigMeWork\n$link';
  Share.share(message, subject: 'Visiting card');
}

void _copyProfileLink(BuildContext context, {String link = 'https://gigmework.app/u/satya'}) {
  Clipboard.setData(ClipboardData(text: link));
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile link copied')));
}

class _MenuGrid extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final it = items[i];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: it.onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.secondary.withOpacity(0.2),
                  child: Icon(it.icon, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _MenuTile({super.key, required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _AvailabilityTile extends StatefulWidget {
  @override
  State<_AvailabilityTile> createState() => _AvailabilityTileState();
}

class _AvailabilityTileState extends State<_AvailabilityTile> {
  bool _available = true;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _available,
      onChanged: (v) => setState(() => _available = v),
      title: Text(_available ? 'Available for work' : 'Busy'),
      subtitle: const Text('Show your availability to clients'),
      secondary: const Icon(Icons.schedule_outlined),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
