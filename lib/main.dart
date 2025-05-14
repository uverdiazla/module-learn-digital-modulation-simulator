import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:modulearn/core/theme/app_theme.dart';
import 'package:modulearn/core/theme/theme_provider.dart';
import 'package:modulearn/core/theme/locale_provider.dart';
import 'package:modulearn/features/modulation/presentation/providers/audio_provider.dart';
import 'package:modulearn/features/modulation/presentation/providers/history_provider.dart';
import 'package:modulearn/features/modulation/presentation/providers/modulation_provider.dart';
import 'package:modulearn/features/modulation/presentation/screens/audio_screen.dart';
import 'package:modulearn/features/modulation/presentation/screens/modulation_screen.dart';
import 'package:modulearn/features/modulation/presentation/screens/history_screen.dart';
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
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
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
            home: AppNavigation(key: AppNavigationState.navigationKey),
          );
        },
      ),
    );
  }
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => AppNavigationState();
}

// Exposing this class for the navigation service
class AppNavigationState extends State<AppNavigation> {
  int _selectedIndex = 0;

  // Método para permitir cambiar la pestaña activa desde fuera
  static final GlobalKey<AppNavigationState> navigationKey =
      GlobalKey<AppNavigationState>();

  void switchToTab(int index) {
    if (index >= 0 && index < 2) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Define screens based on platform
    final List<Widget> screens = [
      const ModulationScreen(),
      PlatformUtils.isWeb ? const HistoryScreen() : const AudioScreen(),
    ];

    // Get bottom navigation items based on platform
    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.tune),
        label: l10n.modulationTab,
      ),
      PlatformUtils.isWeb
          ? BottomNavigationBarItem(
              icon: const Icon(Icons.history),
              label: l10n.history,
            )
          : BottomNavigationBarItem(
              icon: const Icon(Icons.mic),
              label: l10n.audioTab,
            ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: navItems,
      ),
    );
  }
}
