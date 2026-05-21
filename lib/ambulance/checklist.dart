import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
import 'services/api_service.dart';

class AmbulanceChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const AmbulanceChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/ambulance.png',
    nextScreen: AmbulanceChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'ambulance',
    moduleName: 'Ambulance',
    primaryColor: const Color(0xFF1976D2),
    eventIdPrefix: 'ambulance',
    fetchChecklist: () => AmbulanceApiService().getChecklist(),
  );
}
