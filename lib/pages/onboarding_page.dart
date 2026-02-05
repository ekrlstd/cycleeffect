import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _sunriseController;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _sunriseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _positionAnimation = Tween<double>(
      begin: -0.5,
      end: -0.85,
    ).animate(CurvedAnimation(
      parent: _sunriseController,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.1,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sunriseController,
      curve: Curves.easeOut,
    ));

    _sunriseController.forward();
  }

  @override
  void dispose() {
    _sunriseController.dispose();
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.setUsername(name);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Sun gradient background - animated sunrise effect
          AnimatedBuilder(
            animation: _sunriseController,
            builder: (context, child) {
              return Positioned(
                top: screenHeight * _positionAnimation.value,
                left: -screenWidth * 0.75,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    width: screenWidth * 2.5,
                    height: screenHeight * 2,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.5,
                        colors: [
                          Color(0xFFFC9444),
                          Color(0xFFFC9444),
                          Color(0xFFF06A34),
                          Color(0xFFE23824),
                          Color(0xFFB02A1A),
                          Color(0xFF5A1510),
                          Color(0xFF200A08),
                          Color(0xFF060606),
                        ],
                        stops: [0.0, 0.3, 0.45, 0.55, 0.65, 0.75, 0.85, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Content
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                children: [
                  // Title at ~1/3 down
                  SizedBox(height: screenHeight * 0.12),

                  // Company Branding
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'PREVUE',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6.0,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          height: 1.15,
                        ),
                        children: [
                          const TextSpan(text: 'Navigate '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x060606).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'safely',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  height: 1.15,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: '\nwith confidence'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your intelligent driving co-pilot. Get real-time traffic alerts, speed camera warnings, and voice-guided navigation assistance.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // Input field - positioned higher
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderTop.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              focusNode: _focusNode,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'What should we call you?',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary.withValues(alpha: 0.4),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              onSubmitted: (_) => _onContinue(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _onContinue,
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(

                                color: AppTheme.cardBackground.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.borderSides,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                color: AppTheme.textPrimary.withValues(alpha: 0.8),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Promises card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderTop.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _PromiseItem(
                            title: 'Active Safety',
                            description: 'Real-time hazard detection and proactive alerts using government API\u0027s.',
                          ),
                          const SizedBox(height: 12),
                          _PromiseItem(
                            title: 'AV-Ready',
                            description: 'Built with autonomous vehicles in mind. Ready for the future.',
                          ),
                          const SizedBox(height: 12),
                          _PromiseItem(
                            title: 'Privacy First',
                            description: 'Your data stays on your device. No tracking, no ads. Your data is strictly yours.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // Footer card - sticks up from bottom
          Positioned(
            bottom: -30,
            left: screenWidth * 0.025,
            right: screenWidth * 0.025,
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 14, bottom: 64),
              decoration: BoxDecoration(
                color: const Color(0xFF030303),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cycle Effect',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    'CAI x GoWest 2026 Hackathon',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromiseItem extends StatelessWidget {
  final String title;
  final String description;

  const _PromiseItem({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
