import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
import 'services/api_service.dart';

class EmergencyCommChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const EmergencyCommChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/emergency_comm.png',
    nextScreen: EmergencyCommChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'emergency_comm',
    moduleName: 'Emergency Comm',
    primaryColor: const Color(0xFF303F9F),
    eventIdPrefix: 'emergency_comm',
    fetchChecklist: () => EmergencyCommApiService().getChecklist(),
  );
}
