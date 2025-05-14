import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modulearn/core/utils/responsive_utils.dart';
import 'package:modulearn/features/modulation/domain/entities/history_entry.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/presentation/providers/history_provider.dart';
import 'package:modulearn/features/modulation/presentation/widgets/signal_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load history entries when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = Provider.of<HistoryProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    // Detectar si estamos en un dispositivo móvil
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          // Clear all history button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: historyProvider.hasEntries
                ? () => _showClearHistoryDialog(context, historyProvider, l10n)
                : null,
            tooltip: l10n.clearAllHistory,
          ),
        ],
      ),
      body: historyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyProvider.hasEntries
              ? _buildHistoryContent(context, historyProvider, l10n, isMobile)
              : Center(
                  child: Text(
                    l10n.noHistoryEntries,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
    );
  }

  Widget _buildHistoryContent(BuildContext context, HistoryProvider provider,
      AppLocalizations l10n, bool isMobile) {
    // En móvil, usar un diseño diferente con lista en la parte superior y detalles abajo
    if (isMobile) {
      return Column(
        children: [
          // Lista de entradas (aproximadamente 30% de la altura)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: _buildHistoryList(context, provider, l10n),
          ),

          // Divider
          const Divider(height: 1),

          // Área de detalles (el resto de la altura)
          Expanded(
            child: provider.selectedEntry != null
                ? _buildEntryDetail(context, provider, l10n, isMobile)
                : Center(
                    child: Text(
                      l10n.selectHistoryEntry,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
          ),
        ],
      );
    } else {
      // En escritorio/tablet, mantener el diseño de fila
      return Row(
        children: [
          // History list (sidebar)
          SizedBox(
            width: ResponsiveUtils.isLargeScreen(context) ? 300 : 200,
            child: _buildHistoryList(context, provider, l10n),
          ),

          // Vertical divider
          const VerticalDivider(width: 1),

          // Detail view
          Expanded(
            child: provider.selectedEntry != null
                ? _buildEntryDetail(context, provider, l10n, isMobile)
                : Center(
                    child: Text(
                      l10n.selectHistoryEntry,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
          ),
        ],
      );
    }
  }

  Widget _buildHistoryList(
      BuildContext context, HistoryProvider provider, AppLocalizations l10n) {
    return ListView.builder(
      itemCount: provider.entries.length,
      itemBuilder: (context, index) {
        final entry = provider.entries[index];
        final isSelected = provider.selectedEntry?.id == entry.id;

        return ListTile(
          title: Text(
            entry.originalText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            l10n.historyEntry(
              entry.formattedTimestamp,
              entry.originalText,
              entry.modulationType.name,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          selected: isSelected,
          selectedColor: Theme.of(context).colorScheme.primary,
          tileColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          onTap: () => provider.selectEntry(entry),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () =>
                _showDeleteEntryDialog(context, provider, entry.id, l10n),
            tooltip: l10n.deleteEntry,
          ),
        );
      },
    );
  }

  Widget _buildEntryDetail(BuildContext context, HistoryProvider provider,
      AppLocalizations l10n, bool isMobile) {
    final entry = provider.selectedEntry!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header information
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.originalText}: ${entry.originalText}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('${l10n.timestamp}: ${entry.formattedTimestamp}'),
                  const SizedBox(height: 8),
                  Text('${l10n.modulationType}: ${entry.modulationType.name}'),
                ],
              ),
            ),
          ),
          SizedBox(height: isMobile ? 8.0 : 16.0),

          // Signal visualization
          Text(
            l10n.signalVisualization,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14.0 : 16.0,
            ),
          ),
          SizedBox(height: isMobile ? 4.0 : 8.0),
          SizedBox(
            height: isMobile ? 150 : 200,
            child: SignalChart(
              signal: entry.modulatedSignal,
              showSymbolBoundaries: true,
            ),
          ),
          SizedBox(height: isMobile ? 8.0 : 16.0),

          // Demodulation section
          _buildDemodulationSection(context, provider, l10n, isMobile),
        ],
      ),
    );
  }

  Widget _buildDemodulationSection(BuildContext context,
      HistoryProvider provider, AppLocalizations l10n, bool isMobile) {
    final entry = provider.selectedEntry!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.demodulation,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16.0 : 18.0,
              ),
            ),
            SizedBox(height: isMobile ? 8.0 : 16.0),

            // Step by step toggle
            Row(
              children: [
                Text(l10n.stepByStepMode),
                const SizedBox(width: 8),
                Switch(
                  value: provider.stepByStepDemodulation,
                  onChanged: (_) {
                    provider.toggleStepByStepDemodulation();
                  },
                ),
              ],
            ),
            SizedBox(height: isMobile ? 4.0 : 8.0),

            // Noise level slider
            Text(
                '${l10n.noiseLevel}: ${(provider.noiseLevel * 100).toStringAsFixed(0)}%'),
            Slider(
              value: provider.noiseLevel,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '${(provider.noiseLevel * 100).toStringAsFixed(0)}%',
              onChanged: provider.setNoiseLevel,
            ),
            SizedBox(height: isMobile ? 4.0 : 8.0),

            if (provider.stepByStepDemodulation)
              _buildStepByStepControls(context, provider, l10n, isMobile)
            else
              // Full demodulation button
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.transform),
                  label: Text(l10n.demodulate),
                  onPressed: provider.isLoading
                      ? null
                      : provider.demodulateSelectedEntry,
                ),
              ),
            SizedBox(height: isMobile ? 8.0 : 16.0),

            // Demodulation results (if available)
            if (entry.demodulatedText != null) ...[
              const Divider(),
              const SizedBox(height: 8),

              // Progress indicator for step-by-step mode
              if (entry.isStepByStepDemodulation &&
                  entry.demodulationProgress != null) ...[
                Row(
                  children: [
                    Text(
                      '${l10n.demodulation} ${entry.demodulationProgress}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('${entry.currentDemodulationStep}')
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: entry.demodulationProgress! / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(
                l10n.demodulatedText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Formatted demodulated text
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)),
                child: Text(entry.demodulatedText!),
              ),
              const SizedBox(height: 16),

              if (entry.errorRate != null) ...[
                Text(
                  'Error rate: ${(entry.errorRate! * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: entry.errorRate! > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Only show visual error rate if greater than zero
                if (entry.errorRate! > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Original: \"${entry.originalText}\"",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Side-by-side character comparison
                  if (!isMobile &&
                      entry.originalText.length > 0 &&
                      entry.demodulatedText!.length > 0)
                    _buildCharacterComparisonTable(entry),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Step-by-step controls widget
  Widget _buildStepByStepControls(BuildContext context,
      HistoryProvider provider, AppLocalizations l10n, bool isMobile) {
    // Calculate max steps based on binary length and modulation type
    final entry = provider.selectedEntry!;
    final binaryLength =
        entry.modulatedSignal.binaryRepresentation.replaceAll(' ', '').length;

    final bitsPerSymbol = entry.modulationType == ModulationType.qpsk ? 2 : 1;
    final maxSteps = (binaryLength / bitsPerSymbol).ceil();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.previous,
              onPressed: provider.currentDemodulationStep > 0
                  ? provider.previousDemodulationStep
                  : null,
            ),
            Text(
              '${provider.currentDemodulationStep}/$maxSteps',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: l10n.next,
              onPressed: provider.currentDemodulationStep < maxSteps
                  ? provider.nextDemodulationStep
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.transform),
            label: Text('${l10n.demodulate} ${l10n.stepByStepMode}'),
            onPressed: provider.isLoading
                ? null
                : provider.demodulateSelectedEntryStepByStep,
          ),
        ),
      ],
    );
  }

  // Build character comparison table to show differences
  Widget _buildCharacterComparisonTable(HistoryEntry entry) {
    final originalText = entry.originalText;
    final demodulatedText = entry.demodulatedText!;
    final maxLen = originalText.length > demodulatedText.length
        ? originalText.length
        : demodulatedText.length;

    return Wrap(
      spacing: 2,
      children: List.generate(maxLen, (index) {
        final originalChar =
            index < originalText.length ? originalText[index] : '';
        final demodulatedChar =
            index < demodulatedText.length ? demodulatedText[index] : '';
        final isDifferent = originalChar != demodulatedChar;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDifferent
                ? Colors.red.withOpacity(0.2)
                : Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                originalChar,
                style: TextStyle(
                  fontWeight: isDifferent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Divider(height: 8, thickness: 1),
              Text(
                demodulatedChar,
                style: TextStyle(
                  fontWeight: isDifferent ? FontWeight.bold : FontWeight.normal,
                  color: isDifferent ? Colors.red : Colors.black,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Dialog to confirm deletion of an entry
  Future<void> _showDeleteEntryDialog(BuildContext context,
      HistoryProvider provider, String entryId, AppLocalizations l10n) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteEntry),
        content: Text(l10n.deleteEntryConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.deleteEntry(entryId);
              Navigator.of(context).pop();
            },
            child: Text(l10n.delete),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to confirm clearing all history
  Future<void> _showClearHistoryDialog(BuildContext context,
      HistoryProvider provider, AppLocalizations l10n) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllHistory),
        content: Text(l10n.clearAllHistoryConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllHistory();
              Navigator.of(context).pop();
            },
            child: Text(l10n.clear),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
