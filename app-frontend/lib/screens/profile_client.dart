import 'package:flutter/material.dart';

class ProfileClientPage extends StatefulWidget {
  static const routeName = '/profile/client';
  const ProfileClientPage({super.key});

  @override
  State<ProfileClientPage> createState() => _ProfileClientPageState();
}

class _ProfileClientPageState extends State<ProfileClientPage> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Client Profile')),
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
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                                backgroundColor: cs.tertiary.withOpacity(0.15),
                                child: Icon(Icons.apartment_outlined, size: 36, color: cs.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Your Company', style: Theme.of(context).textTheme.titleLarge),
                                    const SizedBox(height: 4),
                                    Text('Hiring for: Mobile, Web, Backend', style: Theme.of(context).textTheme.bodyMedium),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: const [
                                        Chip(label: Text('Startup')),
                                        Chip(label: Text('Remote-friendly')),
                                        Chip(label: Text('Agile')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Company'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _seg(1),
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_seg(1)),
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
                              Text('About', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              const Text(
                                'Brief company description, mission, and what you look for in freelancers.',
                              ),
                              const SizedBox(height: 16),
                              Text('Contact', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              const Text('talent@example.com'),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Post a Job'),
                              ),
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
    );
  }
}
