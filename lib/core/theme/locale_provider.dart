import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
  }

  void toggleLocale() {
    _locale = (_locale.languageCode == 'en')
        ? const Locale('es')
        : const Locale('en');
    notifyListeners();
  }

  static const supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
  ];
}
