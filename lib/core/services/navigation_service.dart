import 'package:flutter/material.dart';
import 'package:modulearn/main.dart';

class NavigationService {
  // Singleton pattern
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  // Método para navegar a la pestaña de modulación (índice 0)
  void navigateToModulationTab() {
    AppNavigationState.navigationKey.currentState?.switchToTab(0);
  }

  // Método para navegar a la pestaña de audio/historial (índice 1)
  void navigateToSecondTab() {
    AppNavigationState.navigationKey.currentState?.switchToTab(1);
  }
}
