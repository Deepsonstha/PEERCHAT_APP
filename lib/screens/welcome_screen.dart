import 'package:flutter/material.dart';
import 'package:peerchat/widgets/welcome_screen_first_section.dart';
import 'package:peerchat/widgets/welcome_start_chatting_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                WelcomeScreenFirstSection(),
                const SizedBox(height: 40),
                WelcomeStartChattingButton(),
                const SizedBox(height: 16),
                Text(
                  'Your data stays on your device.\nNo servers, no tracking, no data collection.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
