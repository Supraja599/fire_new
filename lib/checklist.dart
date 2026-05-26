import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
import 'services/apiservice.dart';

class ChecklistPage extends StatelessWidget {
  final String? equipmentId;
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const ChecklistPage({super.key, this.equipmentId, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/extinguisher.webp',
    nextScreen: const ChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    equipmentId: equipmentId,
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'fire_extinguisher',
    moduleName: 'Fire Extinguisher',
    primaryColor: const Color(0xFFD32F2F),
    eventIdPrefix: 'extinguisher',
    fetchChecklist: ApiService.getFireChecklist,
  );
}
