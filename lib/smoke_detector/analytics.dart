import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_analytics_page.dart';
import 'services/smoke_detector_api_service.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericAnalyticsPage(
      title: "Smoke Detector Analytics",
      shortName: "Smoke Detector",
      assetLabel: "TOTAL SMOKE DETECTOR",
      apiService: SmokeDetectorApiService(),
      imagePath: "assets/smoke_detector.png",
      fallbackIcon: Icons.analytics_rounded,
    );
  }
}
