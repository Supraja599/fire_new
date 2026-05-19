import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/widgets/permission_dialog.dart';

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
    double maxAllowedDistanceMeters = 100.0,
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
}
