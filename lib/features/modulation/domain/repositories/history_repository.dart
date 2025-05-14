import 'package:modulearn/features/modulation/domain/entities/history_entry.dart';
import 'package:modulearn/features/modulation/domain/entities/modulated_signal.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';

abstract class HistoryRepository {
  /// Get all history entries
  Future<List<HistoryEntry>> getAllEntries();

  /// Save a new modulation to history
  Future<HistoryEntry> saveModulation({
    required String originalText,
    required ModulationType modulationType,
    required ModulatedSignal modulatedSignal,
  });

  /// Perform demodulation on a history entry and save the result
  Future<HistoryEntry> demodulateEntry({
    required HistoryEntry entry,
    double noiseLevel = 0.0,
  });

  /// Perform step-by-step demodulation on a history entry
  /// [currentStep] indicates which symbol is being demodulated
  Future<HistoryEntry> demodulateEntryStepByStep({
    required HistoryEntry entry,
    required int currentStep,
    double noiseLevel = 0.0,
  });

  /// Delete a history entry
  Future<bool> deleteEntry(String id);

  /// Clear all history
  Future<bool> clearAllHistory();
}
