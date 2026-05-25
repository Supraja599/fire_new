import 'package:flutter/material.dart';
import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
class WindSockChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const WindSockChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/wind_sock.png',
    nextScreen: WindSockChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'wind_sock',
    moduleName: 'Wind Sock',
    primaryColor: const Color(0xFF1976D2),
    eventIdPrefix: 'wind_sock',
    fetchChecklist: () => ModuleApiService.windSock.getChecklist(),
  );
}
