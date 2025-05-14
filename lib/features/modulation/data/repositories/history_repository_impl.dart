import 'dart:math';
import 'package:modulearn/core/utils/text_converter.dart';
import 'package:modulearn/features/modulation/domain/entities/history_entry.dart';
import 'package:modulearn/features/modulation/domain/entities/modulated_signal.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/domain/repositories/history_repository.dart';
import 'package:uuid/uuid.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  // In-memory storage for history entries
  final List<HistoryEntry> _entries = [];
  final _uuid = Uuid();
  final _random = Random();

  @override
  Future<List<HistoryEntry>> getAllEntries() async {
    // Return a copy of the list to prevent external modification
    return List.from(_entries);
  }

  @override
  Future<HistoryEntry> saveModulation({
    required String originalText,
    required ModulationType modulationType,
    required ModulatedSignal modulatedSignal,
  }) async {
    final entry = HistoryEntry(
      id: _uuid.v4(),
      originalText: originalText,
      modulationType: modulationType,
      modulatedSignal: modulatedSignal,
      timestamp: DateTime.now(),
    );

    // Add to the beginning of the list (most recent first)
    _entries.insert(0, entry);

    return entry;
  }

  @override
  Future<HistoryEntry> demodulateEntry({
    required HistoryEntry entry,
    double noiseLevel = 0.0,
  }) async {
    // Get the binary representation from the modulated signal
    String binaryRepresentation = entry.modulatedSignal.binaryRepresentation;

    // Apply noise if specified
    if (noiseLevel > 0.0) {
      binaryRepresentation =
          _applyNoiseToBinary(binaryRepresentation, noiseLevel);
    }

    // Remove spaces for processing
    final cleanBinary = binaryRepresentation.replaceAll(' ', '');

    try {
      // Perform demodulation (convert back to text)
      final demodulatedText = TextConverter.binaryToText(cleanBinary);

      // Calculate error rate (percentage of characters that differ)
      final errorRate =
          _calculateErrorRate(entry.originalText, demodulatedText);

      // Create a new entry with demodulation results
      return entry.copyWith(
        demodulatedText: demodulatedText,
        errorRate: errorRate,
      );
    } catch (e) {
      // If demodulation fails, return the entry with an error
      return entry.copyWith(
        demodulatedText: "Error: $e",
        errorRate: 1.0, // 100% error
      );
    }
  }

  @override
  Future<HistoryEntry> demodulateEntryStepByStep({
    required HistoryEntry entry,
    required int currentStep,
    double noiseLevel = 0.0,
  }) async {
    // Get the binary representation from the modulated signal
    String binaryRepresentation = entry.modulatedSignal.binaryRepresentation;

    // Apply noise if specified
    if (noiseLevel > 0.0) {
      binaryRepresentation =
          _applyNoiseToBinary(binaryRepresentation, noiseLevel);
    }

    // Remove spaces for processing
    final cleanBinary = binaryRepresentation.replaceAll(' ', '');

    try {
      // For step by step, we only process up to the current step
      // Calculate how many bits per symbol based on modulation type
      final bitsPerSymbol = entry.modulationType == ModulationType.qpsk ? 2 : 1;

      // Calculate how many bits to process in the current step
      final bitsToProcess = currentStep * bitsPerSymbol;

      // Ensure we don't exceed the binary length
      final actualBitsToProcess = bitsToProcess < cleanBinary.length
          ? bitsToProcess
          : cleanBinary.length;

      // If no bits to process, return entry with empty demodulated text
      if (actualBitsToProcess <= 0) {
        return entry.copyWith(
          demodulatedText: "",
          errorRate: 0.0,
          demodulationProgress: 0,
        );
      }

      // Get the binary substring up to the current step
      final processedBinary = cleanBinary.substring(0, actualBitsToProcess);

      // Pad the binary to make it a multiple of 8 (for text conversion)
      String paddedBinary = processedBinary;
      if (processedBinary.length % 8 != 0) {
        final padding = 8 - (processedBinary.length % 8);
        paddedBinary =
            processedBinary.padRight(processedBinary.length + padding, '0');
      }

      // Perform demodulation on the padded binary
      final demodulatedText = TextConverter.binaryToText(paddedBinary);

      // Calculate how much of the original text is demodulated
      final originalText = entry.originalText;
      final expectedDemodulatedLength = (processedBinary.length / 8).ceil();
      final expectedOriginalLength =
          min(expectedDemodulatedLength, originalText.length);

      // Calculate error rate for the processed portion
      final partialErrorRate = expectedOriginalLength > 0
          ? _calculateErrorRate(
              originalText.substring(0, expectedOriginalLength),
              demodulatedText)
          : 0.0;

      // Calculate progress percentage
      final progress = (actualBitsToProcess / cleanBinary.length * 100).round();

      // Create a new entry with step-by-step demodulation results
      return entry.copyWith(
        demodulatedText: demodulatedText,
        errorRate: partialErrorRate,
        demodulationProgress: progress,
      );
    } catch (e) {
      // If demodulation fails, return the entry with an error
      return entry.copyWith(
        demodulatedText: "Error en paso $currentStep: $e",
        errorRate: 1.0, // 100% error
        demodulationProgress: (currentStep *
                100 ~/
                (cleanBinary.length /
                    (entry.modulationType == ModulationType.qpsk ? 2 : 1)))
            .toInt(),
      );
    }
  }

  @override
  Future<bool> deleteEntry(String id) async {
    final initialLength = _entries.length;
    _entries.removeWhere((entry) => entry.id == id);
    return _entries.length < initialLength;
  }

  @override
  Future<bool> clearAllHistory() async {
    _entries.clear();
    return true;
  }

  // Apply random bit flips based on the noise level
  String _applyNoiseToBinary(String binary, double noiseLevel) {
    // Remove spaces
    final cleanBinary = binary.replaceAll(' ', '');

    // Convert to character list for easier modification
    List<String> bits = cleanBinary.split('');

    // Apply noise (bit flips) based on noise level
    for (int i = 0; i < bits.length; i++) {
      // Probability of a bit flip is proportional to the noise level
      if (_random.nextDouble() < noiseLevel) {
        // Flip the bit
        bits[i] = bits[i] == '0' ? '1' : '0';
      }
    }

    // Reconstruct the binary string with spaces every 8 bits
    final StringBuffer result = StringBuffer();
    for (int i = 0; i < bits.length; i++) {
      result.write(bits[i]);
      if ((i + 1) % 8 == 0 && i < bits.length - 1) {
        result.write(' ');
      }
    }

    return result.toString();
  }

  // Calculate the error rate between original and demodulated text
  double _calculateErrorRate(String original, String demodulated) {
    // If lengths differ, account for this in the error calculation
    final int maxLength = max(original.length, demodulated.length);

    if (maxLength == 0) return 0.0; // Both strings empty

    int errors = 0;
    final int minLength = min(original.length, demodulated.length);

    // Count character differences
    for (int i = 0; i < minLength; i++) {
      if (original[i] != demodulated[i]) {
        errors++;
      }
    }

    // Add errors for length difference
    errors += (maxLength - minLength);

    // Return error rate as percentage
    return errors / maxLength;
  }
}
