import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_analytics_page.dart';
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericAnalyticsPage(
      title: "Alarm Panel Analytics",
      shortName: "Alarm Panel",
      assetLabel: "TOTAL ALARM PANEL",
      apiService: ModuleApiService.alarmPanel,
      imagePath: "assets/alarm_panel.png",
      fallbackIcon: Icons.analytics_rounded,
    );
  }
}
