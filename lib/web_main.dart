import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:modulearn/main.dart' as app;

void main() {
  // Configure the URL strategy for web
  setUrlStrategy(PathUrlStrategy());

  // Run the main app
  app.main();
}
