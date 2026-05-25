import 'package:flutter/material.dart';
import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/generic_checklist_page.dart';
import 'package:fire_new/guided_capture_wizard.dart';
class AlarmPanelChecklistPage extends StatelessWidget {
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  const AlarmPanelChecklistPage({super.key, this.selectedEquipment, this.fromScan = true});

  /// Direct open from dashboard: wrap in 4-image wizard first.
  static Widget direct() => GuidedCaptureWizardPage(
    equipmentImage: 'assets/alarm_panel.png',
    nextScreen: AlarmPanelChecklistPage(fromScan: false),
  );

  @override
  Widget build(BuildContext context) => GenericChecklistPage(
    selectedEquipment: selectedEquipment,
    fromScan: fromScan,
    moduleCode: 'fire_alarm',
    moduleName: 'Alarm Panel',
    primaryColor: const Color(0xFFD50000),
    eventIdPrefix: 'alarm',
    fetchChecklist: () => ModuleApiService.alarmPanel.getChecklist(),
  );
}
