import 'package:flutter/material.dart';

class WelcomeScreenFirstSection extends StatelessWidget {
  const WelcomeScreenFirstSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Icon(Icons.chat, size: 60, color: colorScheme.onPrimary),
        ),
        const SizedBox(height: 32),

        // Welcome text
        Text(
          'Welcome to PeerChat',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Text(
          'Connect directly with nearby devices\nNo internet required!',
          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 48),

        // Features
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              _buildFeatureRow(context, Icons.wifi_off, 'Offline Chat', 'Works without internet connection'),
              const SizedBox(height: 12),
              _buildFeatureRow(context, Icons.security, 'Private & Secure', 'Direct device-to-device communication'),
              const SizedBox(height: 12),
              _buildFeatureRow(context, Icons.speed, 'Fast & Reliable', 'Low latency local network messaging'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(description, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
