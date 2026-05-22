import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class SignageReportsPage extends StatelessWidget {
  const SignageReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = SignageApiService();
    return ModuleReportsPage(
      moduleName: "Signage",
      moduleCode: SignageApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
