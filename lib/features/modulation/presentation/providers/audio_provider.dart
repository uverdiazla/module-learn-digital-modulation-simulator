import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:modulearn/features/modulation/data/repositories/audio_repository_impl.dart';
import 'package:modulearn/features/modulation/domain/entities/audio_recording.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/domain/repositories/audio_repository.dart';
import 'package:modulearn/features/modulation/presentation/providers/modulation_provider.dart';

enum AudioRecordingState {
  initial,
  recording,
  paused,
  stopped,
  playing,
  playingPaused,
}

class AudioProvider with ChangeNotifier {
  final AudioRepository _repository = AudioRepositoryImpl();

  // Current recording state
  AudioRecordingState _state = AudioRecordingState.initial;

  // List of available recordings
  List<AudioRecording> _recordings = [];

  // Currently selected recording
  AudioRecording? _selectedRecording;

  // Reference to the modulation provider to avoid circular dependency
  ModulationProvider? _modulationProvider;

  // Loading state
  bool _isLoading = false;

  // Current amplitude during recording
  double _currentAmplitude = 0.0;

  // Current duration during recording
  double _currentDuration = 0.0;

  // Maximum recording duration in seconds (from repository)
  int get maxRecordingDuration => AudioRepositoryImpl.maxRecordingDuration;

  // Time remaining in seconds before auto-stop
  double get timeRemaining => maxRecordingDuration - _currentDuration;

  // Current position during playback
  Duration _playbackPosition = Duration.zero;

  // Total duration of audio being played
  Duration _playbackDuration = Duration.zero;

  // Last error message
  String? _lastError;

  // Getters
  AudioRecordingState get state => _state;
  List<AudioRecording> get recordings => _recordings;
  AudioRecording? get selectedRecording => _selectedRecording;
  bool get isLoading => _isLoading;
  double get currentAmplitude => _currentAmplitude;
  double get currentDuration => _currentDuration;
  Duration get playbackPosition => _playbackPosition;
  Duration get playbackDuration => _playbackDuration;
  bool get hasRecordings => _recordings.isNotEmpty;
  bool get isRecording => _state == AudioRecordingState.recording;
  bool get isPaused => _state == AudioRecordingState.paused;
  bool get isPlaying => _state == AudioRecordingState.playing;
  bool get isPlayingPaused => _state == AudioRecordingState.playingPaused;
  ModulationProvider? get modulationProvider => _modulationProvider;
  String? get lastError => _lastError;

  // Set the modulation provider
  void setModulationProvider(ModulationProvider provider) {
    _modulationProvider = provider;
  }

  // Load all recordings
  Future<void> loadRecordings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _recordings = await _repository.getAllRecordings();
    } catch (e) {
      debugPrint('Error loading recordings: $e');
      _recordings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check microphone permissions
  Future<bool> checkPermission() async {
    bool hasPermission = await _repository.hasPermission();
    if (!hasPermission) {
      hasPermission = await _repository.requestPermission();
    }
    return hasPermission;
  }

  // Start recording
  Future<void> startRecording() async {
    if (await checkPermission()) {
      _isLoading = true;
      notifyListeners();

      try {
        await _repository.startRecording();
        _state = AudioRecordingState.recording;
        _currentAmplitude = 0.0;
        _currentDuration = 0.0;

        // Periodically update UI
        Stream.periodic(const Duration(milliseconds: 100)).listen((_) {
          if (_state == AudioRecordingState.recording) {
            _currentDuration += 0.1;

            // Update UI even if amplitude is handled by repository
            notifyListeners();

            // Auto-stop at max duration (handled in repository, this is just a safety)
            if (_currentDuration >= maxRecordingDuration) {
              stopRecording();
            }
          }
        });
      } catch (e) {
        debugPrint('Error starting recording: $e');
        _lastError = 'Failed to start recording';
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      _lastError = 'Microphone permission denied';
      notifyListeners();
    }
  }

  // Pause recording
  Future<void> pauseRecording() async {
    if (_state != AudioRecordingState.recording) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.pauseRecording();
      _state = AudioRecordingState.paused;
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resume recording
  Future<void> resumeRecording() async {
    if (_state != AudioRecordingState.paused) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.resumeRecording();
      _state = AudioRecordingState.recording;
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stop recording
  Future<void> stopRecording() async {
    if (_state != AudioRecordingState.recording &&
        _state != AudioRecordingState.paused) return;

    _isLoading = true;
    notifyListeners();

    try {
      final recording = await _repository.stopRecording();
      _state = AudioRecordingState.stopped;
      _selectedRecording = recording;
      await loadRecordings(); // Reload the list
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _state = AudioRecordingState.initial;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    if (_state != AudioRecordingState.recording &&
        _state != AudioRecordingState.paused) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.cancelRecording();
      _state = AudioRecordingState.initial;
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    } finally {
      _currentAmplitude = 0.0;
      _currentDuration = 0.0;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select a recording
  void selectRecording(AudioRecording recording) {
    _selectedRecording = recording;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedRecording = null;
    notifyListeners();
  }

  // Play a recording
  Future<void> playRecording(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final recording = _recordings.firstWhere((r) => r.id == id);
      _selectedRecording = recording;
      await _repository.playRecording(id);
      _state = AudioRecordingState.playing;

      // Periodically update playback position
      Stream.periodic(const Duration(milliseconds: 200)).listen((_) async {
        if (_state == AudioRecordingState.playing) {
          _playbackPosition =
              Duration(milliseconds: (_currentDuration * 1000).round());
          _playbackDuration =
              Duration(milliseconds: (recording.duration * 1000).round());
          notifyListeners();

          // Detect end of playback
          if (_playbackPosition >= _playbackDuration) {
            _state = AudioRecordingState.stopped;
            _playbackPosition = Duration.zero;
            notifyListeners();
          }
        }
      });
    } catch (e) {
      debugPrint('Error playing recording: $e');
      _state = AudioRecordingState.stopped;

      // Create a user-friendly error message
      String errorMessage = 'Failed to play recording';
      if (e.toString().contains('Invalid audio file')) {
        errorMessage = 'Invalid audio file';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Audio file not found';
      }

      // Notify listeners with error
      _lastError = errorMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Pause playback
  Future<void> pausePlayback() async {
    if (_state != AudioRecordingState.playing) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.pausePlayback();
      _state = AudioRecordingState.playingPaused;
    } catch (e) {
      debugPrint('Error pausing playback: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resume playback
  Future<void> resumePlayback() async {
    if (_state != AudioRecordingState.playingPaused) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.resumePlayback();
      _state = AudioRecordingState.playing;
    } catch (e) {
      debugPrint('Error resuming playback: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stop playback
  Future<void> stopPlayback() async {
    if (_state != AudioRecordingState.playing &&
        _state != AudioRecordingState.playingPaused) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.stopPlayback();
      _state = AudioRecordingState.stopped;
      _playbackPosition = Duration.zero;
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a recording
  Future<void> deleteRecording(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool success = await _repository.deleteRecording(id);
      if (success) {
        if (_selectedRecording?.id == id) {
          _selectedRecording = null;
        }
        await loadRecordings(); // Reload the list
      }
    } catch (e) {
      debugPrint('Error deleting recording: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert audio to binary representation and send to modulator
  Future<void> useAudioForModulation(String id, ModulationType modulationType,
      {Function? onComplete}) async {
    if (_modulationProvider == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Get the recording
      final recording = _recordings.firstWhere(
        (rec) => rec.id == id,
        orElse: () => throw Exception('Recording not found'),
      );

      // Convert to binary - do this in a compute function to keep UI responsive
      final binaryString = await _repository.convertAudioToBinary(id);

      // Update modulation type
      _modulationProvider!.setModulationType(modulationType);

      // Set binary as input text with additional audio information
      _modulationProvider!.setInputTextFromAudio(
        binaryString,
        recordingId: recording.id
            .substring(0, 8), // Use only the first 8 characters of the ID
        timestamp: recording.formattedTimestamp,
      );

      // Generate modulation
      _modulationProvider!.generateModulation();

      // Call the callback after successful completion to navigate
      if (onComplete != null) {
        onComplete();
      }
    } catch (e) {
      debugPrint('Error using audio for modulation: $e');
      _lastError = 'Error modulating audio: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear the last error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void dispose() {
    (_repository as AudioRepositoryImpl).dispose();
    super.dispose();
  }
}
