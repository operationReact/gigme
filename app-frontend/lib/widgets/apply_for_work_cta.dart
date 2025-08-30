import 'package:flutter/material.dart';
import 'open_jobs_dialog.dart';

class ApplyForWorkCta extends StatelessWidget {
  final int? initialCount;
  final VoidCallback? onPressed;
  final bool dense;
  final bool showLabel;

  const ApplyForWorkCta({
    super.key,
    this.initialCount,
    this.onPressed,
    this.dense = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final backgroundColor = primary.withValues(alpha: 0.94);
    final badgeColor = theme.colorScheme.secondaryContainer;
    final badgeTextColor = theme.colorScheme.onSecondaryContainer;
    final borderRadius = BorderRadius.circular(32);
    final width = MediaQuery.of(context).size.width;
    final bool hideLabel = width < 340; // Responsive: hide label for very narrow widths
    final bool effectiveShowLabel = showLabel && !hideLabel;
    final label = effectiveShowLabel ? Text('Apply for Work', style: TextStyle(color: onPrimary)) : null;

    Widget badge = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: (initialCount != null && initialCount! > 0)
          ? Semantics(
              label: 'New jobs: $initialCount',
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
                    fontSize: dense ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );

    return Tooltip(
      message: 'See new jobs',
      child: Semantics(
        button: true,
        label: 'Apply for Work' + (initialCount != null && initialCount! > 0 ? ', $initialCount new jobs' : ''),
        child: Material(
          color: backgroundColor,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () async {
              // TODO: Replace with actual logged-in freelancer email
              const freelancerEmail = 'freelancer@example.com';
              final result = await showDialog(
                context: context,
                builder: (ctx) => OpenJobsDialog(freelancerEmail: freelancerEmail),
              );
              if (result == 'applied') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Applied for job successfully!')),
                );
              }
            },
            hoverColor: primary.withValues(alpha: 0.10),
            highlightColor: primary.withValues(alpha: 0.18),
            splashColor: primary.withValues(alpha: 0.20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Container(
                padding: dense
                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                    : const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work_outline, color: onPrimary, size: dense ? 18 : 22),
                        if (effectiveShowLabel) ...[
                          const SizedBox(width: 8),
                          label!,
                        ],
                      ],
                    ),
                    Positioned(
                      right: -8,
                      top: -8,
                      child: badge,
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
