import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Welcome header widget with app name and greeting message.
///
/// Displays at the top of the main screen with the app name and
/// a welcoming message to the user.
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App name
          Text(
            'Headsup',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textBright,
                  fontSize: 32,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your intelligent driving co-pilot',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
