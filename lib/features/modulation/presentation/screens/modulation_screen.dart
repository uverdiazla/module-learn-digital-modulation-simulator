import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modulearn/core/theme/theme_provider.dart';
import 'package:modulearn/core/theme/locale_provider.dart';
import 'package:modulearn/core/utils/platform_utils.dart';
import 'package:modulearn/core/utils/responsive_utils.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/presentation/providers/history_provider.dart';
import 'package:modulearn/features/modulation/presentation/providers/modulation_provider.dart';
import 'package:modulearn/features/modulation/presentation/screens/history_screen.dart';
import 'package:modulearn/features/modulation/presentation/widgets/binary_display.dart';
import 'package:modulearn/features/modulation/presentation/widgets/modulation_info_card.dart';
import 'package:modulearn/features/modulation/presentation/widgets/signal_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ModulationScreen extends StatefulWidget {
  const ModulationScreen({super.key});

  @override
  State<ModulationScreen> createState() => _ModulationScreenState();
}

class _ModulationScreenState extends State<ModulationScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Connect the modulation provider with the history provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final modulationProvider =
          Provider.of<ModulationProvider>(context, listen: false);
      final historyProvider =
          Provider.of<HistoryProvider>(context, listen: false);
      modulationProvider.setHistoryProvider(historyProvider);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modulationProvider = Provider.of<ModulationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    // Detectar si estamos en un dispositivo móvil
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          // History button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
            tooltip: l10n.history,
          ),
          // Language toggle button
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: localeProvider.toggleLocale,
            tooltip: l10n.changeLanguage,
          ),
          // Theme toggle button
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Ajustar el ancho máximo basado en el tamaño de pantalla
              maxWidth: ResponsiveUtils.isLargeScreen(context)
                  ? 1200
                  : (isMobile ? MediaQuery.of(context).size.width : 900),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputSection(modulationProvider, l10n, isMobile),
                SizedBox(height: isMobile ? 16 : 24),
                _buildControls(modulationProvider, l10n),
                SizedBox(height: isMobile ? 16 : 24),
                if (modulationProvider.hasResult) ...[
                  _buildResultSection(modulationProvider, l10n, isMobile),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(
      ModulationProvider provider, AppLocalizations l10n, bool isMobile) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.enterMessage,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 8.0 : 16.0),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: l10n.messageHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.edit),
                contentPadding: ResponsiveUtils.getInputPadding(context),
              ),
              style: TextStyle(
                fontSize: PlatformUtils.isWeb ? 14 : (isMobile ? 14 : 16),
              ),
              maxLines: 1,
              onChanged: provider.setInputText,
            ),
            SizedBox(height: isMobile ? 8.0 : 16.0),
            DropdownButtonFormField<ModulationType>(
              decoration: InputDecoration(
                labelText: l10n.modulationType,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.tune),
                contentPadding: ResponsiveUtils.getInputPadding(context),
              ),
              value: provider.modulationType,
              items: ModulationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.setModulationType(value);
                }
              },
            ),
            SizedBox(height: isMobile ? 8.0 : 16.0),
            Row(
              children: [
                Text(l10n.stepByStepMode),
                const SizedBox(width: 8),
                Switch(
                  value: provider.stepByStepMode,
                  onChanged: (_) => provider.toggleStepByStepMode(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ModulationProvider provider, AppLocalizations l10n) {
    int totalSteps = 0;
    if (provider.hasResult) {
      final binaryLength = provider.modulatedSignal!.binaryRepresentation
          .replaceAll(' ', '')
          .length;
      totalSteps = provider.modulationType == ModulationType.bpsk
          ? binaryLength
          : (binaryLength + 1) ~/ 2;
    }

    // Usar Wrap en lugar de Row para que los elementos se ajusten en pantallas pequeñas
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16, // Espacio horizontal entre widgets
      runSpacing: 16, // Espacio vertical entre líneas
      children: [
        if (!provider.stepByStepMode || !provider.hasResult)
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.simulate),
            onPressed:
                provider.inputText.isEmpty ? null : provider.generateModulation,
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.previous,
                onPressed:
                    provider.currentStep > 0 ? provider.previousStep : null,
              ),
              Text('${provider.currentStep}/$totalSteps',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                tooltip: l10n.next,
                onPressed: provider.currentStep < totalSteps
                    ? provider.nextStep
                    : null,
              ),
            ],
          ),
        ElevatedButton.icon(
          icon: const Icon(Icons.restart_alt),
          label: Text(l10n.reset),
          onPressed: () {
            provider.reset();
            _textController.clear();
          },
        ),
        if (provider.hasResult)
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(l10n.saveToHistory),
            onPressed: provider.saveToHistory,
          ),
      ],
    );
  }

  Widget _buildResultSection(
      ModulationProvider provider, AppLocalizations l10n, bool isMobile) {
    final signal = provider.modulatedSignal!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Binary display
        BinaryDisplay(
          binaryString: signal.binaryRepresentation,
          modulationType: signal.modulationType,
          stepByStepMode: provider.stepByStepMode,
          currentStep: provider.currentStep,
          l10n: l10n,
        ),

        // Signal chart
        Text(
          l10n.signalVisualization,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        SizedBox(height: isMobile ? 4 : 8),
        SizedBox(
          height: isMobile ? 200 : 300,
          child: SignalChart(
            signal: signal,
            showSymbolBoundaries: true,
          ),
        ),

        // Modulation info
        ModulationInfoCard(
          modulationType: signal.modulationType,
          l10n: l10n,
        ),
      ],
    );
  }
}
