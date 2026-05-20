import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_analytics_page.dart';
import 'services/fire_trolley_api_service.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericAnalyticsPage(
      title: "Fire Trolley Analytics",
      shortName: "Fire Trolley",
      assetLabel: "TOTAL FIRE TROLLEY",
      apiService: FireTrolleyApiService(),
      imagePath: "assets/fire_trolley.png",
      fallbackIcon: Icons.analytics_rounded,
    );
  }
}
