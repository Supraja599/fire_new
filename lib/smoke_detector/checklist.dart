import 'package:flutter/material.dart';
import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
class SmokeDetectorChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const SmokeDetectorChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/smoke_detector.webp',
    nextScreen: SmokeDetectorChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'smoke_detector',
    moduleName: 'Smoke Detector',
    primaryColor: const Color(0xFF1976D2),
    eventIdPrefix: 'smoke_detector',
    fetchChecklist: () => ModuleApiService.smokeDetector.getChecklist(),
  );
}
