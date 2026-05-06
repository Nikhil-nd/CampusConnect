import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class CampusHeroHeader extends StatelessWidget {
  const CampusHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = theme.extension<AppSemanticColors>() ?? AppTheme.lightSemanticColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary,
            semantic.info,
            semantic.surfaceTint,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'CampusConnect',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Everything students need in one connected feed.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Marketplace, events, jobs, lost & found, chat, and moderation all flow through the same experience.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _StatChip(label: 'Events', value: 'Live', color: semantic.success),
              _StatChip(label: 'Reports', value: 'Moderated', color: semantic.warning),
              _StatChip(label: 'Chats', value: 'Connected', color: semantic.info),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary),
          children: <InlineSpan>[
            TextSpan(text: '$label\n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            TextSpan(text: value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
