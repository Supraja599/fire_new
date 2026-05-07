import 'dart:io';

void main() async {
  final modules = [
    'ambulance',
    'chemical_shower',
    'co2_system',
    'emergency_comm',
    'emergency_exits',
    'emergency_lighting',
    'emergency_shower',
    'eye_wash',
    'fire_blankets',
    'first_aid',
    'muster_points',
    'pa_system',
    'ppe_cabinets',
    'scba_units',
    'signage',
    'spill_kits',
    'wind_sock'
  ];

  final hrMaint = File('lib/hosereel/maintaince.dart').readAsStringSync();
  final hrAlerts = File('lib/hosereel/alerts.dart').readAsStringSync();

  for (var mod in modules) {
    final maintFile = File('lib/$mod/maintaince.dart');
    final alertsFile = File('lib/$mod/alerts.dart');
    
    if (!maintFile.existsSync() || !alertsFile.existsSync()) {
      print('Skipping $mod - files not found');
      continue;
    }

    final oldMaint = maintFile.readAsStringSync();
    final oldAlerts = alertsFile.readAsStringSync();

    // extract prefix from maint: class (.*)MaintenancePage
    final prefixMatch = RegExp(r'class\s+(\w+)MaintenancePage').firstMatch(oldMaint);
    if (prefixMatch == null) {
      print('Could not find prefix for $mod');
      continue;
    }
    final prefix = prefixMatch.group(1)!;

    // extract asset path from maint: Image.asset\("assets/([^"]+)"
    final assetMatch = RegExp(r'Image.asset\("assets/([^"]+)"').firstMatch(oldMaint);
    final assetName = assetMatch != null ? assetMatch.group(1)! : '$mod.png';

    // extract api service from alerts: final api = (.*)ApiService\(\);
    final apiMatch = RegExp(r'final api = (\w+)ApiService\(\);').firstMatch(oldAlerts);
    if (apiMatch == null) {
      print('Could not find API service for $mod');
      continue;
    }
    final apiPrefix = apiMatch.group(1)!;

    print('Processing $mod: prefix=$prefix, api=$apiPrefix, asset=$assetName');

    // Maint replacement
    var newMaint = hrMaint
      .replaceAll('HoseReel', prefix)
      .replaceAll('hosereel.png', assetName)
      .replaceAll("import 'services/apiservice.dart';", "import 'services/api_service.dart';")
      .replaceAll('hose reel', mod.replaceAll('_', ' '));

    // generic fields replace
    newMaint = newMaint.replaceAll('"hose_length":', '"brand":')
      .replaceAll('item["details"]?["hose_length_m"]?.toString() ?? "N/A"', 'item["brand"]?.toString() ?? "N/A"')
      .replaceAll('"pressure":', '"model":')
      .replaceAll('item["details"]?["pressure_rating"]?.toString() ?? "N/A"', 'item["model"]?.toString() ?? "N/A"')
      .replaceAll('_chip("Hose \${item["hose_length"]}", color)', '_chip(item["brand"] != "N/A" ? item["brand"] : "Standard", color)')
      .replaceAll('_chip("Pressure \${item["pressure"]}", Colors.grey.shade700)', '_chip(item["model"] != "N/A" ? item["model"] : "Unit", Colors.grey.shade700)')
      .replaceAll('_row("Pressure", item["pressure"], color)', '_row("Brand", item["brand"], color)')
      .replaceAll('_row("Hose Length", item["hose_length"], color)', '_row("Model", item["model"], color)');

    // alerts replacement
    var newAlerts = hrAlerts
      .replaceAll('HoseReel', prefix)
      .replaceAll('hosereel.png', assetName)
      .replaceAll("import 'services/apiservice.dart';", "import 'services/api_service.dart';");

    maintFile.writeAsStringSync(newMaint);
    alertsFile.writeAsStringSync(newAlerts);
  }
}
