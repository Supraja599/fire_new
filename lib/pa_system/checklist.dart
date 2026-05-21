import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
import 'services/api_service.dart';

class PASystemChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const PASystemChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/pa_system.png',
    nextScreen: PASystemChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'pa_system',
    moduleName: 'PA System',
    primaryColor: const Color(0xFF1976D2),
    eventIdPrefix: 'pa_system',
    fetchChecklist: () => PASystemApiService().getChecklist(),
  );
}
