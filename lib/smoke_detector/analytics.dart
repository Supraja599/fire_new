import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_analytics_page.dart';
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericAnalyticsPage(
      title: "Smoke Detector Analytics",
      shortName: "Smoke Detector",
      assetLabel: "TOTAL SMOKE DETECTOR",
      apiService: ModuleApiService.smokeDetector,
      imagePath: "assets/smoke_detector.png",
      fallbackIcon: Icons.analytics_rounded,
    );
  }
}
