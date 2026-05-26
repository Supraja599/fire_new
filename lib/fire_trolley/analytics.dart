import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_analytics_page.dart';
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericAnalyticsPage(
      title: "Fire Trolley Analytics",
      shortName: "Fire Trolley",
      assetLabel: "TOTAL FIRE TROLLEY",
      apiService: ModuleApiService.fireTrolley,
      imagePath: "assets/fire_trolley.webp",
      fallbackIcon: Icons.analytics_rounded,
    );
  }
}
