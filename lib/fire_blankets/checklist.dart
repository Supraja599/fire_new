import 'package:flutter/material.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
import 'services/api_service.dart';

class FireBlanketsChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const FireBlanketsChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/fire_blankets.png',
    nextScreen: FireBlanketsChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'fire_blanket',
    moduleName: 'Fire Blankets',
    primaryColor: const Color(0xFFD84315),
    eventIdPrefix: 'fire_blankets',
    fetchChecklist: () => FireBlanketsApiService().getChecklist(),
  );
}
