import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Simple greeting header with username.
class GreetingHeader extends StatelessWidget {
  final String? username;

  const GreetingHeader({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        'Drive safe, ${username ?? 'John'} ♡',
        style: GoogleFonts.inter(
          color: AppTheme.textPrimary.withOpacity(0.7),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
