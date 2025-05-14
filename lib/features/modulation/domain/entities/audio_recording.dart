import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';

/// Represents an audio recording to use with modulation
class AudioRecording {
  /// Unique identifier for the recording
  final String id;

  /// Path to the audio file
  final String audioFilePath;

  /// Duration of the recording in seconds
  final double duration;

  /// Timestamp of when it was recorded
  final DateTime timestamp;

  /// Audio waveform (amplitudes for visualization)
  final List<double>? waveform;

  /// Binary data of the audio (used for modulation)
  final String? binaryData;

  /// Associated modulation type (optional)
  final ModulationType? modulationType;

  AudioRecording({
    required this.id,
    required this.audioFilePath,
    required this.duration,
    required this.timestamp,
    this.waveform,
    this.binaryData,
    this.modulationType,
  });

  /// Creates a copy with modified properties
  AudioRecording copyWith({
    String? id,
    String? audioFilePath,
    double? duration,
    DateTime? timestamp,
    List<double>? waveform,
    String? binaryData,
    ModulationType? modulationType,
  }) {
    return AudioRecording(
      id: id ?? this.id,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      waveform: waveform ?? this.waveform,
      binaryData: binaryData ?? this.binaryData,
      modulationType: modulationType ?? this.modulationType,
    );
  }

  /// Formats the timestamp as a readable string
  String get formattedTimestamp {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
