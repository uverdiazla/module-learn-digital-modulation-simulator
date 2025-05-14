import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'package:modulearn/features/modulation/domain/entities/audio_recording.dart';
import 'package:modulearn/features/modulation/domain/repositories/audio_repository.dart';

class AudioRepositoryImpl implements AudioRepository {
  final _player = AudioPlayer();
  final _uuid = Uuid();

  // Recorder instance
  final _audioRecorder = Record();

  // Maximum recording duration in seconds
  static const int maxRecordingDuration = 10;

  // In-memory storage for recordings
  final List<AudioRecording> _recordings = [];

  // Recording state
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentFilePath;
  DateTime? _recordingStartTime;
  double _recordingDuration = 0.0;
  final List<double> _recordingAmplitudes = [];

  // Timer to stop recording after maximum duration
  Future<void>? _maxDurationTimer;

  @override
  Future<void> startRecording() async {
    if (await hasPermission()) {
      // Create directory to store recordings if it doesn't exist
      final appDir = await getApplicationDocumentsDirectory();
      final dirPath = '${appDir.path}/audio_recordings';
      final directory = Directory(dirPath);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      // Generate a unique name for the audio file
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentFilePath = '$dirPath/$fileName';

      if (kIsWeb) {
        // Fallback to mock recording for web
        // Create an empty file to simulate recording
        File(_currentFilePath!).writeAsBytesSync([]);

        // Start mock recording
        _isRecording = true;
        _isPaused = false;
        _recordingStartTime = DateTime.now();
        _recordingDuration = 0.0;
        _recordingAmplitudes.clear();

        // Generate mock amplitude data
        _generateMockAmplitudes();
      } else {
        // Real audio recording for mobile
        try {
          // Configure the recorder
          await _audioRecorder.start(
            path: _currentFilePath!,
            encoder: AudioEncoder.aacLc, // AAC codec
            bitRate: 128000, // 128 kbps
            samplingRate: 44100, // 44.1 kHz
          );

          _isRecording = true;
          _isPaused = false;
          _recordingStartTime = DateTime.now();
          _recordingDuration = 0.0;
          _recordingAmplitudes.clear();

          // Set up monitoring of amplitude for waveform visualization
          Stream.periodic(const Duration(milliseconds: 100)).listen((_) async {
            if (_isRecording && !_isPaused) {
              final amplitude = await _audioRecorder.getAmplitude();
              final normalized =
                  (amplitude.current + 60) / 60; // Normalize from dB
              _recordingAmplitudes.add(normalized.clamp(0.1, 1.0));
              _recordingDuration += 0.1;

              // Auto-stop recording after max duration
              if (_recordingDuration >= maxRecordingDuration) {
                stopRecording();
              }
            }
          });
        } catch (e) {
          debugPrint('Error starting real recording: $e');
          // Fallback to mock if real recording fails
          _isRecording = true;
          _isPaused = false;
          _recordingAmplitudes.clear();
          _generateMockAmplitudes();
        }
      }
    }
  }

  @override
  Future<void> pauseRecording() async {
    if (!_isRecording) return;

    if (!kIsWeb) {
      try {
        await _audioRecorder.pause();
      } catch (e) {
        debugPrint('Error pausing recording: $e');
      }
    }

    _isPaused = true;
  }

  @override
  Future<void> resumeRecording() async {
    if (!_isRecording || !_isPaused) return;

    if (!kIsWeb) {
      try {
        await _audioRecorder.resume();
      } catch (e) {
        debugPrint('Error resuming recording: $e');
      }
    }

    _isPaused = false;

    // Continue generating mock amplitude data on web
    if (kIsWeb) {
      _generateMockAmplitudes();
    }
  }

  @override
  Future<AudioRecording> stopRecording() async {
    if (!_isRecording) {
      throw Exception('No active recording');
    }

    _isRecording = false;
    _isPaused = false;

    if (kIsWeb) {
      // Generate mock audio data for web
      await _generateMockAudioFile(_currentFilePath!);
    } else {
      // Stop real recording on mobile
      try {
        await _audioRecorder.stop();
      } catch (e) {
        debugPrint('Error stopping recording: $e');
        // If error occurs when stopping, generate mock data as fallback
        await _generateMockAudioFile(_currentFilePath!);
      }
    }

    // Create an AudioRecording object with the collected data
    final recording = AudioRecording(
      id: _uuid.v4(),
      audioFilePath: _currentFilePath!,
      duration: _recordingDuration,
      timestamp: DateTime.now(),
      waveform: _recordingAmplitudes,
    );

    // Save the recording to the list
    _recordings.add(recording);

    return recording;
  }

  @override
  Future<void> cancelRecording() async {
    // Delete the file if it exists
    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentFilePath = null;
    }

    if (!kIsWeb) {
      try {
        await _audioRecorder.stop();
      } catch (e) {
        debugPrint('Error stopping recording on cancel: $e');
      }
    }

    _isRecording = false;
    _isPaused = false;
    _recordingAmplitudes.clear();
    _recordingDuration = 0.0;
  }

  @override
  Future<List<AudioRecording>> getAllRecordings() async {
    return List.from(
        _recordings); // Returns a copy to avoid external modifications
  }

  @override
  Future<void> playRecording(String id) async {
    try {
      final recording = _recordings.firstWhere(
        (rec) => rec.id == id,
        orElse: () => throw Exception('Recording not found'),
      );

      // For a real file, we'd use setFilePath
      final file = File(recording.audioFilePath);
      if (await file.exists()) {
        // Check file size to ensure it's a valid audio file
        final fileSize = await file.length();
        if (fileSize < 100) {
          throw Exception('Invalid audio file: file is too small');
        }

        await _player.setFilePath(recording.audioFilePath);
        await _player.play();
      } else {
        throw Exception(
            'Audio file not found on disk: ${recording.audioFilePath}');
      }
    } catch (e) {
      debugPrint('Error playing recording: $e');
      rethrow; // Rethrow to allow UI to handle the error
    }
  }

  @override
  Future<void> pausePlayback() async {
    await _player.pause();
  }

  @override
  Future<void> resumePlayback() async {
    await _player.play();
  }

  @override
  Future<void> stopPlayback() async {
    await _player.stop();
  }

  @override
  Future<bool> deleteRecording(String id) async {
    final initialLength = _recordings.length;
    final recording = _recordings.firstWhere(
      (rec) => rec.id == id,
      orElse: () => throw Exception('Recording not found'),
    );

    // Delete the file
    final file = File(recording.audioFilePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Remove from in-memory list
    _recordings.removeWhere((rec) => rec.id == id);

    return _recordings.length < initialLength;
  }

  @override
  Future<bool> hasPermission() async {
    if (Platform.isIOS || Platform.isAndroid) {
      return await Permission.microphone.isGranted;
    }

    return true; // Assume granted on other platforms
  }

  @override
  Future<bool> requestPermission() async {
    if (Platform.isIOS || Platform.isAndroid) {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    }

    return true; // Assume granted on other platforms
  }

  @override
  Future<String> convertAudioToBinary(String id) async {
    final recording = _recordings.firstWhere(
      (rec) => rec.id == id,
      orElse: () => throw Exception('Recording not found'),
    );

    if (recording.binaryData != null) {
      return recording.binaryData!;
    }

    // Convert the real audio file to binary
    final file = File(recording.audioFilePath);
    if (!await file.exists()) {
      throw Exception('Audio file not found');
    }

    try {
      // Read the file bytes
      final bytes = await file.readAsBytes();

      // For WAV/M4A files, skip the header (first 44 bytes for WAV)
      // and take significant samples of the actual audio
      int startOffset = 44; // Typical WAV header size

      // If the file is very small, use all available bytes
      if (bytes.length <= startOffset) {
        startOffset = 0;
      }

      // Take significant samples at intervals to represent the audio
      // This better represents the audio waveform
      List<int> significantSamples = [];

      // Determine sampling interval (take 32 representative samples)
      final sampleInterval = (bytes.length - startOffset) ~/ 32;

      if (sampleInterval > 0) {
        // Extract samples at regular intervals
        for (int i = 0;
            i < 32 && startOffset + i * sampleInterval < bytes.length;
            i++) {
          significantSamples.add(bytes[startOffset + i * sampleInterval]);
        }
      } else {
        // If the file is very small, use the first 32 bytes or less
        significantSamples =
            bytes.sublist(0, bytes.length > 32 ? 32 : bytes.length);
      }

      // Convert each sample to its binary representation (4 bits to reduce length)
      final binaryValues = significantSamples.map((sample) {
        // Use only the 4 most significant bits to reduce size
        final reduced =
            (sample & 0xF0) >> 4; // Take the 4 most significant bits
        return reduced.toRadixString(2).padLeft(4, '0');
      }).toList();

      // Join the binary values with spaces every 8 bits (2 samples)
      final buffer = StringBuffer();
      for (int i = 0; i < binaryValues.length; i++) {
        buffer.write(binaryValues[i]);

        // Add space every 8 bits (2 samples of 4 bits each)
        if (i % 2 == 1 && i < binaryValues.length - 1) {
          buffer.write(' ');
        }
      }

      final binaryString = buffer.toString();

      // Update recording with binary data
      final updatedRecording = recording.copyWith(binaryData: binaryString);

      // Update in the list
      final index = _recordings.indexWhere((rec) => rec.id == id);
      if (index >= 0) {
        _recordings[index] = updatedRecording;
      }

      return binaryString;
    } catch (e) {
      debugPrint('Error converting audio to binary: $e');
      throw Exception('Failed to convert audio to binary: $e');
    }
  }

  // Generate mock amplitude data while "recording"
  void _generateMockAmplitudes() {
    if (!_isRecording || _isPaused) return;

    // Update every 100ms to simulate real recording
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isRecording && !_isPaused) {
        _recordingDuration += 0.1;
        // Add a random amplitude value between 0.1 and 0.8
        _recordingAmplitudes.add(0.1 + (math.Random().nextDouble() * 0.7));

        // Continue generating data
        _generateMockAmplitudes();
      }
    });
  }

  // Generate mock audio file data
  Future<void> _generateMockAudioFile(String filePath) async {
    // Create a simple WAV file with a tone
    final file = File(filePath);

    // WAV parameters
    const int sampleRate = 44100;
    const int numChannels = 1; // Mono
    const int bitsPerSample = 16;
    const int seconds = 3;

    // Calculate sizes
    final int dataSize =
        sampleRate * numChannels * bitsPerSample ~/ 8 * seconds;
    final int fileSize = 36 + dataSize;

    // Create buffer for WAV file
    final buffer = ByteData(44 + dataSize);

    // Write WAV header
    // "RIFF" chunk descriptor
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'

    // File size minus 8 bytes for RIFF and size fields
    buffer.setUint32(4, fileSize - 8, Endian.little);

    // "WAVE" format
    buffer.setUint8(8, 0x57); // 'W'
    buffer.setUint8(9, 0x41); // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // "fmt " sub-chunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '

    // Sub-chunk size (16 for PCM)
    buffer.setUint32(16, 16, Endian.little);

    // Audio format (1 for PCM)
    buffer.setUint16(20, 1, Endian.little);

    // Number of channels
    buffer.setUint16(22, numChannels, Endian.little);

    // Sample rate
    buffer.setUint32(24, sampleRate, Endian.little);

    // Byte rate
    buffer.setUint32(
        28, sampleRate * numChannels * bitsPerSample ~/ 8, Endian.little);

    // Block align
    buffer.setUint16(32, numChannels * bitsPerSample ~/ 8, Endian.little);

    // Bits per sample
    buffer.setUint16(34, bitsPerSample, Endian.little);

    // "data" sub-chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'

    // Data size
    buffer.setUint32(40, dataSize, Endian.little);

    // Generate a simple sine wave
    const double frequency = 440.0; // A note
    const double amplitude = 0.5 * 32767; // Half volume

    for (int i = 0; i < sampleRate * seconds; i++) {
      final double t = i / sampleRate;
      final double angle = 2 * math.pi * frequency * t;
      final int sample = (amplitude * math.sin(angle)).toInt();

      // Write sample with offset 44 (header size)
      final int offset = 44 + i * 2;
      buffer.setInt16(offset, sample, Endian.little);
    }

    // Write the buffer to the file
    await file.writeAsBytes(buffer.buffer.asUint8List());
  }

  // Generate mock binary string
  String _generateMockBinaryString(int length) {
    final buffer = StringBuffer();
    final random = math.Random();

    // Use a seed for more consistent and meaningful binary patterns
    final seed = DateTime.now().millisecondsSinceEpoch;
    final seededRandom = math.Random(seed);

    for (int i = 0; i < length; i++) {
      // Generate alternating patterns for better visualization
      if (i % 16 < 8) {
        buffer.write(seededRandom.nextBool() ? '1' : '0');
      } else {
        // Create patterns that will be visually more distinct in modulation
        buffer.write(i % 4 == 0 ? '1' : '0');
      }

      // Add space every 8 bits for readability
      if ((i + 1) % 8 == 0 && i < length - 1) {
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  // Don't forget to release resources when no longer needed
  void dispose() {
    _player.dispose();
    _audioRecorder.dispose();
  }
}
