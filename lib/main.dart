import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'pages/onboarding_page.dart';
import 'widgets/greeting_header.dart';
import 'widgets/map_card.dart';
import 'widgets/bento_cards.dart';
import 'widgets/voice_pill.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const HeadsupApp());
}

/// Main application widget.
class HeadsupApp extends StatelessWidget {
  const HeadsupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Headsup',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const OnboardingPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}

/// Main home page with new layout.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/Gradient.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting header
                GreetingHeader(username: provider.username),

                // Map card (~40% of viewport)
                const MapCard(),

                const SizedBox(height: 16),

                // Bento Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Row 1: Intersections (full width)
                        const Expanded(
                          flex: 1,
                          child: UpcomingIntersectionsCard(),
                        ),

                        const SizedBox(height: 12),

                        // Row 2: Speed & Distance
                        const SizedBox(
                          height: 125,
                          child: SpeedDistanceCard(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Voice Interface Pill
                const VoicePill(),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}
