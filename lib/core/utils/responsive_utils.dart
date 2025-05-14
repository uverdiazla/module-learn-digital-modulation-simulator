import 'package:flutter/material.dart';
import 'package:modulearn/core/utils/platform_utils.dart';

/// Utility class for responsive design
class ResponsiveUtils {
  /// Returns true if the device is considered a small screen
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Returns true if the device is considered a medium screen
  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1200;
  }

  /// Returns true if the device is considered a large screen
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Returns appropriate padding for input fields based on platform and screen size
  static EdgeInsets getInputPadding(BuildContext context) {
    // Use more compact padding on web
    if (PlatformUtils.isWeb) {
      if (isSmallScreen(context)) {
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      } else {
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      }
    }
    // Use standard padding on mobile
    else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
  }

  /// Returns appropriate max width for input fields
  static double getInputMaxWidth(BuildContext context) {
    if (PlatformUtils.isWeb) {
      if (isLargeScreen(context)) {
        return 600; // Limit width on large screens
      } else if (isMediumScreen(context)) {
        return 450; // Slightly smaller on medium screens
      }
    }
    return double.infinity; // Full width on small screens and mobile
  }
}
