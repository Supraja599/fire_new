import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true);

  int modifiedCount = 0;

  // Regular expression matching the standard barcode scanner callback across all modules
  final regex = RegExp(
    r'onDetect\s*:\s*\(c\)\s*\{\s*'
    r'if\s*\(c\.barcodes\.isNotEmpty\)\s*\{\s*'
    r'idController\.text\s*=\s*c\.barcodes\.first\.rawValue\s*\?\?\s*"";\s*'
    r'fetchDetails\((?:idController\.text|c\.barcodes\.first\.rawValue\s*\?\?\s*"")\);\s*'
    r'\}\s*\},',
    multiLine: true,
  );

  final replacement = '''onDetect: (c) async {
                      if (c.barcodes.isNotEmpty) {
                        final raw = c.barcodes.first.rawValue ?? "";
                        final canProceed = await LocationService.checkGeofenceAndShowDialog(context: context, sosCode: raw);
                        if (!canProceed || !mounted) return;
                        idController.text = raw;
                        fetchDetails(raw);
                      }
                    },''';

  for (final file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      final path = file.path;
      // Skip main inspection.dart and global_scanner.dart since they were modified manually
      if (path.endsWith('lib/inspection.dart') || path.endsWith('lib\\inspection.dart') ||
          path.endsWith('lib/global_scanner.dart') || path.endsWith('lib\\global_scanner.dart')) {
        continue;
      }

      String content = file.readAsStringSync();
      bool modified = false;

      if (regex.hasMatch(content)) {
        content = content.replaceFirst(regex, replacement);
        modified = true;
      }

      if (modified) {
        // Inject import statement if not already present
        final importStatement = "import 'package:fire_new/services/location_service.dart';";
        if (!content.contains(importStatement)) {
          if (content.contains("import 'package:mobile_scanner/mobile_scanner.dart';")) {
            content = content.replaceFirst(
              "import 'package:mobile_scanner/mobile_scanner.dart';",
              "import 'package:mobile_scanner/mobile_scanner.dart';\nimport 'package:fire_new/services/location_service.dart';"
            );
          } else {
            content = importStatement + "\n" + content;
          }
        }

        file.writeAsStringSync(content);
        print("Modified: $path");
        modifiedCount++;
      }
    }
  }

  print("Total modified files: $modifiedCount");
}
