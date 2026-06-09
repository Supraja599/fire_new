import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class WindSockMaintenancePage extends StatelessWidget {
  const WindSockMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Wind Sock Maintenance",
      imagePath: "assets/wind_sock.webp",
      api: ModuleApiService.windSock,
    );
  }
}
