import 'package:flutter/material.dart';
import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
class SpillKitsChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const SpillKitsChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/spill_kits.png',
    nextScreen: SpillKitsChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'spill_kit',
    moduleName: 'Spill Kits',
    primaryColor: const Color(0xFF33691E),
    eventIdPrefix: 'spill_kits',
    fetchChecklist: () => ModuleApiService.spillKit.getChecklist(),
  );
}
