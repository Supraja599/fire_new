import 'package:flutter/material.dart';
import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
class HeatDetectorChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const HeatDetectorChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/heat_detector.webp',
    nextScreen: HeatDetectorChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'heat_detector',
    moduleName: 'Heat Detector',
    primaryColor: const Color(0xFFE65100),
    eventIdPrefix: 'heat_detector',
    fetchChecklist: () => ModuleApiService.heatDetector.getChecklist(),
  );
}
