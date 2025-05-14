import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modulearn/core/theme/theme_provider.dart';
import 'package:modulearn/core/theme/locale_provider.dart';
import 'package:modulearn/core/utils/platform_utils.dart';
import 'package:modulearn/core/utils/responsive_utils.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/presentation/providers/modulation_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
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
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.isLargeScreen(context) ? 1200 : 900,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputSection(modulationProvider, l10n),
                const SizedBox(height: 24),
                _buildControls(modulationProvider, l10n),
                const SizedBox(height: 24),
                if (modulationProvider.hasResult) ...[
                  _buildResultSection(modulationProvider, l10n),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(
      ModulationProvider provider, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.enterMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: l10n.messageHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.edit),
                contentPadding: ResponsiveUtils.getInputPadding(context),
              ),
              style: TextStyle(
                fontSize: PlatformUtils.isWeb ? 14 : 16,
              ),
              maxLines: 1,
              onChanged: provider.setInputText,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(width: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.restart_alt),
          label: Text(l10n.reset),
          onPressed: () {
            provider.reset();
            _textController.clear();
          },
        ),
      ],
    );
  }

  Widget _buildResultSection(
      ModulationProvider provider, AppLocalizations l10n) {
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
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
