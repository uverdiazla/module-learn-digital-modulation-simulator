import 'package:flutter/foundation.dart';

/// Utility class for platform-specific code
class PlatformUtils {
  /// Returns true if the app is running on the web platform
  static bool get isWeb => kIsWeb;

  /// Returns true if the app is running on a mobile platform (Android or iOS)
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Returns true if the app is running on Android
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Returns true if the app is running on iOS
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns true if the app is running on desktop (Windows, macOS, Linux)
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);
}
