import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
import 'services/api_service.dart';

class FireDoorChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const FireDoorChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/fire_door.png',
    nextScreen: FireDoorChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'fire_door',
    moduleName: 'Fire Door',
    primaryColor: const Color(0xFF1565C0),
    eventIdPrefix: 'fire_door',
    fetchChecklist: () => FireDoorApiService().getChecklist(),
  );
}
