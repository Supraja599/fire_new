import 'package:flutter/material.dart';
import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
class FireTrolleyChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const FireTrolleyChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/fire_trolley.png',
    nextScreen: FireTrolleyChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'fire_trolley',
    moduleName: 'Fire Trolley',
    primaryColor: const Color(0xFFD84315),
    eventIdPrefix: 'fire_trolley',
    fetchChecklist: () => ModuleApiService.fireTrolley.getChecklist(),
  );
}
