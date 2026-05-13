import 'package:flutter/material.dart';

class Responsive {
  /// Mobile: width < 600
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Tablet: 600 <= width < 1200
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  /// Desktop/Laptop: width >= 1200
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  /// Returns a multiplier for padding and spacing based on device
  static double spacingMultiplier(BuildContext context) {
    if (isDesktop(context)) return 2.0;
    if (isTablet(context)) return 1.5;
    return 1.0;
  }

  /// Returns an appropriate font scale factor
  static double textScaleFactor(BuildContext context) {
    // Get the system text scale factor
    double systemScale = MediaQuery.of(context).textScaler.scale(1.0);
    
    if (isDesktop(context)) return systemScale * 1.3;
    if (isTablet(context)) return systemScale * 1.2;
    return systemScale * 1.1; // Slight boost for mobile readability
  }
}
