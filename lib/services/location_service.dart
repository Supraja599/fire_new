import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/widgets/permission_dialog.dart';
import 'package:fire_new/services/apiservice.dart';

class ProximityResult {
  final bool success;
  final bool withinRange;
  final double? distanceMeters;
  final String? errorMessage;

  ProximityResult({
    required this.success,
    this.withinRange = false,
    this.distanceMeters,
    this.errorMessage,
  });
}

class LocationService {
  /// Verifies device permissions and calculates distance from the target coordinates.
  /// Returns a [ProximityResult] indicating success, range, and exact distance.
  static Future<ProximityResult> verifyProximity({
    required double targetLat,
    required double targetLng,
    double maxAllowedDistanceMeters = 10.0,
    BuildContext? context,
  }) async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. Test if location services are enabled on the device
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return ProximityResult(
          success: false,
          errorMessage: "Location services are disabled on this device. Please turn on GPS/Location in settings.",
        );
      }

      // 2. Check and request runtime permission from the user
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (context != null) {
          final proceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (c) => const EltrivePermissionDialog(
              title: "GPS Location Access Required",
              description: "Eltrive Safety requires access to your high-precision device GPS coordinates during checklist submission. This ensures that safety inspections are physically performed on-site at the correct equipment location for safety compliance.",
              icon: Icons.location_on_rounded,
            ),
          ) ?? false;
          if (!proceed) {
            return ProximityResult(
              success: false,
              errorMessage: "Location permission request was cancelled.",
            );
          }
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return ProximityResult(
            success: false,
            errorMessage: "Location permission was denied. High-precision GPS is required to submit checklist.",
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return ProximityResult(
          success: false,
          errorMessage: "Location permissions are permanently denied. Please grant Location permissions in your app settings to proceed.",
        );
      }

      // 3. Fetch the technician's exact current position
      // Using high accuracy with an 8-second limit to prevent UI lock
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      // 4. Calculate physical distance in meters between coordinates
      double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLat,
        targetLng,
      );

      bool isWithin = distance <= maxAllowedDistanceMeters;

      return ProximityResult(
        success: true,
        withinRange: isWithin,
        distanceMeters: distance,
      );
    } catch (e) {
      return ProximityResult(
        success: false,
        errorMessage: "Failed to acquire GPS location. Ensure you are outdoors or near a window, or try again later. ($e)",
      );
    }
  }

  /// Centralized Geofence Verification and Alert flow.
  /// Compares scanning position against target coordinates resolved from API details.
  /// Falls back to 17.5021988, 78.3530868 and a 10-meter limit if not found.
  static Future<bool> checkGeofenceAndShowDialog({
    required BuildContext context,
    required String sosCode,
  }) async {
    try {
      // 1. Verify location service availability
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("GPS/Location services are disabled. Please enable GPS in your device settings."),
            backgroundColor: Colors.red,
          ),
        );
        return true; // GPS disabled - fallback to allowing inspection
      }

      // 2. Resolve or request location permissions
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          return true; // permission denied - fallback to allowing inspection
        }
      }
      if (perm == LocationPermission.deniedForever) {
        return true; // permission denied forever - fallback to allowing inspection
      }

      // 3. Acquire current device coordinates
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      // Fetch equipment details from API (or local cache/fallback)
      final eqData = await ApiService.searchAny(sosCode);
      if (eqData == null) {
        return true; // if not found, allow scan (fallback)
      }

      double? targetLat;
      double? targetLng;
      double maxAllowedDistanceMeters = 10.0; // default fallback

      if (eqData.containsKey("geofence") && eqData["geofence"] is Map) {
        final gf = eqData["geofence"] as Map;
        targetLat = double.tryParse((gf["stored_latitude"] ?? "").toString());
        targetLng = double.tryParse((gf["stored_longitude"] ?? "").toString());
        maxAllowedDistanceMeters = double.tryParse((gf["geofence_radius_meters"] ?? "").toString()) ?? 10.0;
      } else {
        targetLat = double.tryParse((eqData["latitude"] ?? eqData["lat"] ?? eqData["stored_latitude"] ?? "").toString());
        targetLng = double.tryParse((eqData["longitude"] ?? eqData["lng"] ?? eqData["stored_longitude"] ?? "").toString());
        maxAllowedDistanceMeters = double.tryParse((eqData["geofence_radius_meters"] ?? eqData["geofence_radius"] ?? "").toString()) ?? 10.0;
      }

      // If coordinates are not configured, allow scan to proceed or use the fallback coordinates
      if (targetLat == null || targetLng == null) {
        targetLat = 17.5021988;
        targetLng = 78.3530868;
        maxAllowedDistanceMeters = 10.0;
      }

      double distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        targetLat,
        targetLng,
      );

      // Submit check to API in background (optional/logging)
      try {
        await ApiService.checkScanLocation(
          sosCode: sosCode,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      } catch (_) {}

      // 5. Determine compliance based on the retrieved threshold
      bool isOutside = distance > maxAllowedDistanceMeters;

      if (isOutside) {
        final msg = "You are out of the geofence. Please go and scan within the authorized location.\n(Distance: ${distance.toStringAsFixed(1)}m away, Limit: ${maxAllowedDistanceMeters.toStringAsFixed(0)}m)";
        return await _showOutOfRangeDialog(context, msg);
      } else {
        // Within the limit - proceed directly without showing any dialog
        return true;
      }
    } catch (_) {
      return true; // Fallback to allowing inspection on errors
    }
  }

  static Future<bool> _showOutOfRangeDialog(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_off_rounded, color: Colors.red.shade700, size: 26),
            const SizedBox(width: 10),
            const Text("Out of Geofence",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Do you want to proceed anyway?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Proceed Anyway",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
