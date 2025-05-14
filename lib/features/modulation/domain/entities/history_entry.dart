import 'package:modulearn/features/modulation/domain/entities/modulated_signal.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';

/// Represents a saved modulation entry in the history
class HistoryEntry {
  /// Unique identifier for the entry
  final String id;

  /// Original text that was modulated
  final String originalText;

  /// Type of modulation used
  final ModulationType modulationType;

  /// The modulated signal
  final ModulatedSignal modulatedSignal;

  /// When the modulation was performed
  final DateTime timestamp;

  /// Optional demodulated text
  final String? demodulatedText;

  /// Optional error rate from demodulation
  final double? errorRate;

  /// Demodulation progress (percentage 0-100)
  final int? demodulationProgress;

  /// Whether demodulation is in step-by-step mode
  final bool isStepByStepDemodulation;

  /// Current step in step-by-step demodulation
  final int currentDemodulationStep;

  HistoryEntry({
    required this.id,
    required this.originalText,
    required this.modulationType,
    required this.modulatedSignal,
    required this.timestamp,
    this.demodulatedText,
    this.errorRate,
    this.demodulationProgress,
    this.isStepByStepDemodulation = false,
    this.currentDemodulationStep = 0,
  });

  /// Create a copy with optional modified properties
  HistoryEntry copyWith({
    String? id,
    String? originalText,
    ModulationType? modulationType,
    ModulatedSignal? modulatedSignal,
    DateTime? timestamp,
    String? demodulatedText,
    double? errorRate,
    int? demodulationProgress,
    bool? isStepByStepDemodulation,
    int? currentDemodulationStep,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      modulationType: modulationType ?? this.modulationType,
      modulatedSignal: modulatedSignal ?? this.modulatedSignal,
      timestamp: timestamp ?? this.timestamp,
      demodulatedText: demodulatedText ?? this.demodulatedText,
      errorRate: errorRate ?? this.errorRate,
      demodulationProgress: demodulationProgress ?? this.demodulationProgress,
      isStepByStepDemodulation:
          isStepByStepDemodulation ?? this.isStepByStepDemodulation,
      currentDemodulationStep:
          currentDemodulationStep ?? this.currentDemodulationStep,
    );
  }

  /// Format timestamp as a human-readable string
  String get formattedTimestamp {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
