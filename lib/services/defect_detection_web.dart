import 'defect_detection_service.dart';

class DefectDetectionService {
  static Future<void> init() async {
    // Web doesn't need to load the TFLite model since it uses a mock analyzer fallback.
    print("DefectDetectionService (Web): Web bypass initialized.");
  }

  static Future<DefectDetectionResult> analyzeImage(String imagePath) async {
    // Return mock successful result on Web to prevent crash on non-supported platforms
    return DefectDetectionResult(
      isDefective: false,
      label: "Good Condition (Web Bypass)",
      confidence: 1.0,
    );
  }
}
