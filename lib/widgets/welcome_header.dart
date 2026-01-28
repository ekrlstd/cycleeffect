import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Welcome header widget with friendly icon and greeting message.
///
/// Displays at the top of the main screen with the app name and
/// a welcoming message to the user.
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Friendly car/road icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              size: 32,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TrafficVision AI',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
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
          ),
        ],
      ),
    );
  }
}
