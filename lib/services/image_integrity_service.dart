import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

class ImageValidationResult {
  final bool isValid;
  final String reason;
  final double contrastScore;
  final double averageLuminance;

  ImageValidationResult({
    required this.isValid,
    required this.reason,
    this.contrastScore = 0.0,
    this.averageLuminance = 0.0,
  });
}

class ImageIntegrityService {
  /// Analyzes pixel variation and luminance metrics in real-time on the GPU
  /// to instantly detect and reject blank pages, fake solid photos, or black shots.
  static Future<ImageValidationResult> analyzePhoto(File file, int stepIndex) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      
      // 1. Size Guard: Blank highly-compressible files are extremely tiny
      if (bytes.lengthInBytes < 4000) {
        return ImageValidationResult(
          isValid: false, 
          reason: "File size is extremely low. The photo appears blank or has no visual details.",
          contrastScore: 0,
        );
      }

      // 2. GPU-Accelerated Instant Subsampling
      // Downscales to a 32x32 matrix in microseconds to process intensity values
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 32,
        targetHeight: 32,
      );
      
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image img = frameInfo.image;

      // 3. Extract Raw RGBA Byte Stream
      final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        // Default to valid if bytes cannot be unpacked to avoid blocking audits
        return ImageValidationResult(isValid: true, reason: "Buffer unpack fallback.");
      }

      final Uint8List pixels = byteData.buffer.asUint8List();
      
      // 4. Advanced 2D Matrix Space Processing (Laplacian Edge & Color Saturation Check)
      final List<List<double>> gridLums = List.generate(32, (_) => List.filled(32, 0.0));
      double totalLum = 0.0;
      double totalSaturation = 0.0;
      int skinTonePixels = 0;
      
      int pxIdx = 0;
      for (int y = 0; y < 32; y++) {
        for (int x = 0; x < 32; x++) {
          final int base = pxIdx * 4;
          if (base >= pixels.length - 2) break;
          final int r = pixels[base];
          final int g = pixels[base + 1];
          final int b = pixels[base + 2];
          
          // A. Biometric skin tone check: Reject Selfie Hijacks
          if (r > 95 && g > 40 && b > 20 && (r - g).abs() > 15 && r > g && r > b) {
            skinTonePixels++;
          }

          // B. Edge luminance mapping
          final double lum = (0.299 * r) + (0.587 * g) + (0.114 * b);
          gridLums[y][x] = lum;
          totalLum += lum;

          // C. Color Saturation: Max difference between color bands (Vibrancy metric)
          final int maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
          final int minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
          totalSaturation += (maxC - minC);
          
          pxIdx++;
        }
      }

      final int sampleSize = 32 * 32;
      final double averageLuminance = totalLum / sampleSize;
      final double skinPercentage = (skinTonePixels / sampleSize) * 100.0;
      final double averageSaturation = totalSaturation / sampleSize;

      // D. 2D Gradient Magnitude (Laplacian Edge Density)
      double edgeDeltaSum = 0.0;
      int edgeCount = 0;
      for (int y = 0; y < 31; y++) {
        for (int x = 0; x < 31; x++) {
          final double current = gridLums[y][x];
          final double right = gridLums[y][x + 1];
          final double bottom = gridLums[y + 1][x];
          
          // Calculate gradients in horizontal and vertical plane
          edgeDeltaSum += (current - right).abs();
          edgeDeltaSum += (current - bottom).abs();
          edgeCount += 2;
        }
      }
      final double edgeDensity = edgeDeltaSum / edgeCount;

      print("[!] 🔑 PROOF-TAG: HIGH-SECURITY ENGINE ACTIVE! (Build 2.0)");
      print("[!] PHOTO INTEGRITY REPORT:");
      print("    Average Luminance = ${averageLuminance.toStringAsFixed(2)}");
      print("    Skin Cover %      = ${skinPercentage.toStringAsFixed(2)}%");
      print("    Edge Density      = ${edgeDensity.toStringAsFixed(2)}");
      print("    Vibrancy Index    = ${averageSaturation.toStringAsFixed(2)}");

      // 5. Biometric Guard: Reject Selfies/Humans
      if (skinPercentage > 42.0) {
        return ImageValidationResult(
          isValid: false,
          reason: "HUMAN BIOMETRICS DETECTED! The security protocol strictly prohibits selfies or human faces. Please frame the actual physical equipment.",
          averageLuminance: averageLuminance,
        );
      }

      // 6. Severe Lighting Rejection Guards
      if (averageLuminance < 25.0) {
        return ImageValidationResult(
          isValid: false,
          reason: "Image is completely dark (black)! Please switch on lights or remove camera lens cover.",
          averageLuminance: averageLuminance,
        );
      }
      if (averageLuminance > 242.0) {
        return ImageValidationResult(
          isValid: false,
          reason: "Image is completely overexposed / pure white! Please avoid capturing light bulbs or blank white ceilings.",
          averageLuminance: averageLuminance,
        );
      }

      // 7. CALIBRATED DUAL-FACTOR STRUCTURAL INTEGRITY (Stops blank textured surfaces)
      // Based on live diagnostics, textured blank surfaces (walls/floors) can yield edge densities up to ~5.8.
      // However, they yield extremely low Color Vibrancy (monochrome < 13.0).
      
      // Factor A: Pure Flatness. A photo smoother than 4.2 has zero physical structure.
      final bool hasNoEdges = edgeDensity < 4.2;
      
      // Factor B: Greyscale Void. A monochrome photo (< 13.0 saturation) MUST have sharp industrial borders
      // (edgeDensity > 6.5) to prove it is not just a grainy blank floor/wall/carpet.
      final bool isGreyscaleVoid = (averageSaturation < 13.0 && edgeDensity < 6.5);

      if (hasNoEdges || isGreyscaleVoid) {
        return ImageValidationResult(
          isValid: false,
          reason: "INVALID BLANK PHOTO DETECTED! The security scanner detected an empty or flat surface (like a blank wall, floor, or table). You MUST capture the ACTUAL physical safety equipment to proceed.",
          contrastScore: edgeDensity,
          averageLuminance: averageLuminance,
        );
      }

      // Scale for legacy view validation (converts edgeDensity to comparable contrastScore)
      final double contrastScore = edgeDensity * 2.0;

      // 7. SMART VIEW SIGNATURE VALIDATOR (Identifies if captured frame matches target view!)
      
      // View 2 (Macro Tag Scan) REQUIRES high-density local sharp contrast (black ink text on white stickers)
      if (stepIndex == 1) {
        // If contrast score is average or flat, user didn't zoom in on the barcode!
        if (contrastScore < 6.5) {
          return ImageValidationResult(
            isValid: false,
            reason: "INCORRECT VIEW DETECTED! This step requires View 2: Macro Scan. Your camera is too far away or blurry. Please hold the lens EXTREMELY CLOSE to the Barcode/Asset Tag sticker.",
            contrastScore: contrastScore,
            averageLuminance: averageLuminance,
          );
        }
      }
      
      // View 4 (Safety Clearances) MUST be a wide, distant surroundings shot!
      if (stepIndex == 3) {
        // Close-up/Extreme Macro of texture yields massive noise (> 25). Wide shots are balanced.
        if (contrastScore > 25.0) {
          return ImageValidationResult(
            isValid: false,
            reason: "INCORRECT VIEW DETECTED! This step requires View 4: Safety Zone. The photo is too zoomed in. Please step back 2 METERS to capture the surrounding environment and floor clearance.",
            contrastScore: contrastScore,
            averageLuminance: averageLuminance,
          );
        }
      }

      // Photo certified authentic!
      return ImageValidationResult(
        isValid: true,
        reason: "Visual verification successful.",
        contrastScore: contrastScore,
        averageLuminance: averageLuminance,
      );
    } catch (e) {
      print("[!] Image integrity analysis failed: $e");
      // Always fallback to valid if analysis fails to prevent breaking workflow on older OSes
      return ImageValidationResult(isValid: true, reason: "Validation bypassed on error.");
    }
  }
}
