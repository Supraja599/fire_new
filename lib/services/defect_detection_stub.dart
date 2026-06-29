import 'defect_detection_service.dart';

class DefectDetectionService {
  static Future<void> init() async {
    throw UnsupportedError('Cannot initialize defect detection without platform-specific implementation.');
  }

  static Future<DefectDetectionResult> analyzeImage(String imagePath) async {
    throw UnsupportedError('Cannot analyze image without platform-specific implementation.');
  }
}
