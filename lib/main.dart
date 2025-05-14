import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:modulearn/core/theme/app_theme.dart';
import 'package:modulearn/core/theme/theme_provider.dart';
import 'package:modulearn/core/theme/locale_provider.dart';
import 'package:modulearn/features/modulation/presentation/providers/modulation_provider.dart';
import 'package:modulearn/features/modulation/presentation/screens/modulation_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:modulearn/core/utils/platform_utils.dart';

// Handle web platform issues
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize any platform-specific settings
  if (PlatformUtils.isAndroid) {
    // Android-specific initializations would go here
    // The flutter_displaymode package would be used here if needed
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ModulationProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          // We need to get localized title, but context.l10n isn't available yet
          // The app title will be localized in the MaterialApp's title, and in the AppBar
          return MaterialApp(
            title: 'ModuLearn', // Simple title for the window/tab
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LocaleProvider.supportedLocales,
            home: const ModulationScreen(),
          );
        },
      ),
    );
  }
}
