import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
import 'package:fire_new/services/module_api_service.dart';

class EmergencyLightingChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const EmergencyLightingChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/emergency_lighting.webp',
    nextScreen: EmergencyLightingChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'emergency_light',
    moduleName: 'Emergency Lighting',
    primaryColor: const Color(0xFF1976D2),
    eventIdPrefix: 'lighting',
    fetchChecklist: () => ModuleApiService.emergencyLight.getChecklist(),
  );
}
