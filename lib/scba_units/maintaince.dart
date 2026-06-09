import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class SCBAUnitsMaintenancePage extends StatelessWidget {
  const SCBAUnitsMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "SCBA Units Maintenance",
      imagePath: "assets/scba_unit.webp",
      api: ModuleApiService.scbaUnit,
    );
  }
}
