import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:modulearn/core/utils/responsive_utils.dart';
import 'package:modulearn/core/services/navigation_service.dart';
import 'package:modulearn/features/modulation/domain/entities/audio_recording.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/presentation/providers/audio_provider.dart';
import 'package:modulearn/features/modulation/presentation/providers/modulation_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  // For creating a custom waveform visualization during recording
  final List<double> _waveData = [];
  final int _maxWaveDataPoints = 100;

  @override
  void initState() {
    super.initState();
    // Load existing recordings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioProvider>(context, listen: false).loadRecordings();

      // Initialize waveform array
      for (int i = 0; i < _maxWaveDataPoints; i++) {
        _waveData.add(0.05);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final modulationProvider =
        Provider.of<ModulationProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    // Check if we're on a mobile device
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Connect providers if not already connected
    if (audioProvider.modulationProvider == null) {
      audioProvider.setModulationProvider(modulationProvider);
    }

    // Update waveform during recording
    if (audioProvider.isRecording) {
      // Add new data point and remove oldest
      if (_waveData.length >= _maxWaveDataPoints) {
        _waveData.removeAt(0);
      }
      _waveData.add(0.05 + audioProvider.currentAmplitude);
    }

    // Show error toast if there's an error
    if (audioProvider.lastError != null) {
      // Show a toast with the error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorToast(context, audioProvider.lastError!);
        audioProvider.clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.audioScreen),
        actions: [
          // Clear recordings history
          if (audioProvider.hasRecordings)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () =>
                  _showClearRecordingsDialog(context, audioProvider, l10n),
              tooltip: l10n.clearAllRecordings,
            ),
        ],
      ),
      body: audioProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(
              context, audioProvider, modulationProvider, l10n, isMobile),
    );
  }

  Widget _buildContent(
      BuildContext context,
      AudioProvider audioProvider,
      ModulationProvider modulationProvider,
      AppLocalizations l10n,
      bool isMobile) {
    // On mobile, use vertical layout, on desktop horizontal
    if (isMobile) {
      return Column(
        children: [
          // Recording area (approximately 60% of height)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildRecordingArea(context, audioProvider, l10n),
          ),

          // Separator
          const Divider(height: 1),

          // Recordings list (rest of the space)
          Expanded(
            child: _buildRecordingsList(
                context, audioProvider, modulationProvider, l10n),
          ),
        ],
      );
    } else {
      // On desktop/tablet, maintain row layout
      return Row(
        children: [
          // Recording area
          Expanded(
            flex: 3,
            child: _buildRecordingArea(context, audioProvider, l10n),
          ),

          // Vertical separator
          const VerticalDivider(width: 1),

          // Recordings list
          Expanded(
            flex: 2,
            child: _buildRecordingsList(
                context, audioProvider, modulationProvider, l10n),
          ),
        ],
      );
    }
  }

  Widget _buildRecordingArea(BuildContext context, AudioProvider audioProvider,
      AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Section title
          Text(
            audioProvider.isRecording || audioProvider.isPaused
                ? l10n.recording
                : l10n.newRecording,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Max duration info
          Text(
            '${l10n.maxDuration}: ${audioProvider.maxRecordingDuration} ${l10n.seconds}',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Waveform visualization
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: audioProvider.isRecording || audioProvider.isPaused
                  ? _buildWaveformAnimation()
                  : Center(
                      child: Text(
                        l10n.startRecording,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Recording duration and time remaining
          if (audioProvider.isRecording || audioProvider.isPaused) ...[
            // Current duration
            Text(
              _formatDuration(audioProvider.currentDuration),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),

            // Time remaining with color indicator
            Text(
              '${l10n.timeRemaining}: ${_formatDuration(audioProvider.timeRemaining)}',
              style: TextStyle(
                color:
                    audioProvider.timeRemaining < 3 ? Colors.red : Colors.green,
                fontWeight: audioProvider.timeRemaining < 3
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),

            // Progress bar
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: audioProvider.currentDuration /
                  audioProvider.maxRecordingDuration,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                audioProvider.timeRemaining < 3
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Recording controls
          _buildRecordingControls(context, audioProvider, l10n),
        ],
      ),
    );
  }

  Widget _buildWaveformAnimation() {
    return CustomPaint(
      painter: WaveformPainter(
        waveData: _waveData,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).cardColor,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildRecordingControls(BuildContext context,
      AudioProvider audioProvider, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main recording/pause button
        if (!audioProvider.isRecording && !audioProvider.isPaused)
          // Button to start recording
          FloatingActionButton(
            onPressed: () => audioProvider.startRecording(),
            backgroundColor: Colors.red,
            child: const Icon(Icons.mic, color: Colors.white),
          )
        else
          // Controls during recording
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Button to pause/resume
              FloatingActionButton(
                onPressed: audioProvider.isPaused
                    ? () => audioProvider.resumeRecording()
                    : () => audioProvider.pauseRecording(),
                backgroundColor: Colors.orange,
                mini: true,
                child: Icon(
                  audioProvider.isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),

              // Button to stop
              FloatingActionButton(
                onPressed: () => audioProvider.stopRecording(),
                backgroundColor: Colors.red,
                child: const Icon(Icons.stop, color: Colors.white),
              ),
              const SizedBox(width: 16),

              // Button to cancel
              FloatingActionButton(
                onPressed: () => audioProvider.cancelRecording(),
                backgroundColor: Colors.grey,
                mini: true,
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecordingsList(BuildContext context, AudioProvider audioProvider,
      ModulationProvider modulationProvider, AppLocalizations l10n) {
    if (!audioProvider.hasRecordings) {
      return Center(
        child: Text(
          l10n.noRecordings,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return ListView.builder(
      itemCount: audioProvider.recordings.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final recording = audioProvider.recordings[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            title: Text('Recording ${index + 1}'),
            subtitle: Text(
              'Duration: ${_formatDuration(recording.duration)} - ${recording.formattedTimestamp}',
            ),
            leading: const CircleAvatar(child: Icon(Icons.mic)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Playback button
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => audioProvider.playRecording(recording.id),
                ),

                // Options menu
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      _showDeleteRecordingDialog(
                          context, audioProvider, recording.id, l10n);
                    } else if (value == 'modulate') {
                      _showModulationTypeDialog(
                          context, audioProvider, recording.id, l10n);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'modulate',
                      child: Row(
                        children: [
                          const Icon(Icons.electric_bolt),
                          const SizedBox(width: 8),
                          Text(l10n.useForModulation),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete),
                          const SizedBox(width: 8),
                          Text(l10n.delete),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => audioProvider.selectRecording(recording),
            // Highlight if selected
            selected: audioProvider.selectedRecording?.id == recording.id,
            selectedColor: Theme.of(context).colorScheme.primary,
            tileColor: audioProvider.selectedRecording?.id == recording.id
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3)
                : null,
          ),
        );
      },
    );
  }

  // Dialog to select modulation type
  Future<void> _showModulationTypeDialog(
      BuildContext context,
      AudioProvider audioProvider,
      String recordingId,
      AppLocalizations l10n) async {
    // Instancia del servicio de navegación
    final NavigationService navigationService = NavigationService();

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectModulationType),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("BPSK"),
                  subtitle: Text(l10n.bpsk_description),
                  leading: const Icon(Icons.waves),
                  onTap: () {
                    audioProvider.useAudioForModulation(
                        recordingId, ModulationType.bpsk, onComplete: () {
                      // Navegar a la pestaña de modulación al terminar
                      navigationService.navigateToModulationTab();
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text("QPSK"),
                  subtitle: Text(l10n.qpsk_description),
                  leading: const Icon(Icons.waves),
                  onTap: () {
                    audioProvider.useAudioForModulation(
                        recordingId, ModulationType.qpsk, onComplete: () {
                      // Navegar a la pestaña de modulación al terminar
                      navigationService.navigateToModulationTab();
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text("ASK"),
                  subtitle: Text(l10n.ask_description),
                  leading: const Icon(Icons.waves),
                  onTap: () {
                    audioProvider.useAudioForModulation(
                        recordingId, ModulationType.ask, onComplete: () {
                      // Navegar a la pestaña de modulación al terminar
                      navigationService.navigateToModulationTab();
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text("FSK"),
                  subtitle: Text(l10n.fsk_description),
                  leading: const Icon(Icons.waves),
                  onTap: () {
                    audioProvider.useAudioForModulation(
                        recordingId, ModulationType.fsk, onComplete: () {
                      // Navegar a la pestaña de modulación al terminar
                      navigationService.navigateToModulationTab();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  // Dialog to confirm deletion of a recording
  Future<void> _showDeleteRecordingDialog(
      BuildContext context,
      AudioProvider audioProvider,
      String recordingId,
      AppLocalizations l10n) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRecording),
        content: Text(l10n.deleteRecordingConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              audioProvider.deleteRecording(recordingId);
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

  // Dialog to confirm deletion of all recordings
  Future<void> _showClearRecordingsDialog(BuildContext context,
      AudioProvider audioProvider, AppLocalizations l10n) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllRecordings),
        content: Text(l10n.clearAllRecordingsConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Delete all recordings one by one
              List<String> recordingIds = audioProvider.recordings
                  .map((recording) => recording.id)
                  .toList();

              for (String id in recordingIds) {
                await audioProvider.deleteRecording(id);
              }

              // Refresh list
              await audioProvider.loadRecordings();
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

  // Format duration in seconds to mm:ss format
  String _formatDuration(double durationInSeconds) {
    final duration = Duration(milliseconds: (durationInSeconds * 1000).round());
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // Show a toast with the error message
  void _showErrorToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Custom painter for waveform
class WaveformPainter extends CustomPainter {
  final List<double> waveData;
  final Color color;
  final Color backgroundColor;

  WaveformPainter({
    required this.waveData,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final middle = size.height / 2;

    if (waveData.isEmpty) return;

    final width = size.width;
    final pointWidth = width / (waveData.length - 1);

    // Start the path
    path.moveTo(0, middle);

    for (int i = 0; i < waveData.length; i++) {
      // The amplitude determines how much it deviates from center
      final amplitude = waveData[i] * middle;
      final x = i * pointWidth;
      final y = middle + amplitude * math.sin(i * 0.15);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
