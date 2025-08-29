import 'package:flutter/material.dart';

class ApplyForWorkFab extends StatelessWidget {
  final int? initialCount;
  final VoidCallback? onPressed;
  const ApplyForWorkFab({super.key, this.initialCount, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = theme.colorScheme.secondaryContainer;
    final badgeTextColor = theme.colorScheme.onSecondaryContainer;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.extended(
          onPressed: onPressed,
          icon: const Icon(Icons.work_outline),
          label: const Text('Apply for Work'),
        ),
        if (initialCount != null && initialCount! > 0)
          Positioned(
            right: -2,
            top: -2,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey<int>(initialCount!),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  initialCount.toString(),
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
