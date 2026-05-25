import 'package:flutter/material.dart';
import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
class SCBAUnitsChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const SCBAUnitsChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/scba_unit.png',
    nextScreen: SCBAUnitsChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'scba_unit',
    moduleName: 'SCBA Units',
    primaryColor: const Color(0xFF1976D2),
    eventIdPrefix: 'scba_units',
    fetchChecklist: () => ModuleApiService.scbaUnit.getChecklist(),
  );
}
