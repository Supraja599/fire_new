export 'defect_detection_stub.dart'
    if (dart.library.io) 'defect_detection_native.dart'
    if (dart.library.html) 'defect_detection_web.dart';

class DefectDetectionResult {
  final bool isDefective;
  final String label;
  final double confidence;

  DefectDetectionResult({
    required this.isDefective,
    required this.label,
    required this.confidence,
  });
}
