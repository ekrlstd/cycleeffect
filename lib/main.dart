import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/welcome_header.dart';
import 'widgets/map_card.dart';
import 'widgets/traffic_list_card.dart';
import 'widgets/waveform_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.paleGreen,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TrafficVisionApp());
}

/// Main application widget.
///
/// Sets up the Provider for state management and applies the app theme.
class TrafficVisionApp extends StatelessWidget {
  const TrafficVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'TrafficVision AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomePage(),
      ),
    );
  }
}

/// Main home page with all UI components.
///
/// Displays the map, traffic updates, and audio waveform visualizer
/// in a scrollable layout.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Initialize the app provider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    // For physical device, you may need to set the backend URL
    // provider.setWebSocketUrl('ws://YOUR_PC_IP:8000/ws/traffic');

    await provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paleGreen,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () async {
                await provider.reconnect();
              },
              color: AppTheme.primaryGreen,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Welcome header with icon
                    const WelcomeHeader(),
                    const SizedBox(height: 16),
                    // Map card with location marker
                    const MapCard(),
                    const SizedBox(height: 20),
                    // Traffic updates list
                    const TrafficListCard(),
                    const SizedBox(height: 20),
                    // Audio waveform visualizer
                    const WaveformCard(),
                    const SizedBox(height: 24),
                    // Debug section (can be removed in production)
                    if (provider.error != null)
                      _buildErrorBanner(context, provider.error!),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            );
          },
        ),
      ),
      // Floating action button for quick actions
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (provider.trafficUpdates.isEmpty) {
                provider.loadMockData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Loaded demo traffic data'),
                    backgroundColor: AppTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else if (provider.trafficUpdates.isNotEmpty) {
                // Speak the most recent update
                final update = provider.trafficUpdates.first;
                final message =
                    '${update.location}. ${update.vehicleCount} vehicles. ${update.density.displayName}.';
                provider.speakAlert(message);
              }
            },
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            icon: Icon(
              provider.trafficUpdates.isEmpty
                  ? Icons.download_rounded
                  : Icons.campaign_rounded,
            ),
            label: Text(
              provider.trafficUpdates.isEmpty ? 'Load Demo' : 'Announce',
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.trafficHigh.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.trafficHigh.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.trafficHigh,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: AppTheme.trafficHigh,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
