import 'package:flutter/material.dart';
import 'package:modulearn/features/modulation/data/repositories/history_repository_impl.dart';
import 'package:modulearn/features/modulation/domain/entities/history_entry.dart';
import 'package:modulearn/features/modulation/domain/entities/modulated_signal.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/domain/repositories/history_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _repository = HistoryRepositoryImpl();

  // History entries
  List<HistoryEntry> _entries = [];

  // Currently selected entry for demodulation
  HistoryEntry? _selectedEntry;

  // Noise level for demodulation simulation (0.0 to 1.0)
  double _noiseLevel = 0.0;

  // Step-by-step demodulation control
  bool _stepByStepDemodulation = false;
  int _currentDemodulationStep = 0;

  // Loading state
  bool _isLoading = false;

  // Getters
  List<HistoryEntry> get entries => _entries;
  HistoryEntry? get selectedEntry => _selectedEntry;
  double get noiseLevel => _noiseLevel;
  bool get isLoading => _isLoading;
  bool get hasEntries => _entries.isNotEmpty;
  bool get stepByStepDemodulation => _stepByStepDemodulation;
  int get currentDemodulationStep => _currentDemodulationStep;

  // Toggle step-by-step demodulation mode
  void toggleStepByStepDemodulation() {
    _stepByStepDemodulation = !_stepByStepDemodulation;

    // Reset step if we toggle off
    if (!_stepByStepDemodulation) {
      _currentDemodulationStep = 0;
    }

    notifyListeners();
  }

  // Reset demodulation step
  void resetDemodulationStep() {
    _currentDemodulationStep = 0;
    notifyListeners();
  }

  // Move to next demodulation step
  void nextDemodulationStep() {
    if (_selectedEntry == null || !_stepByStepDemodulation) return;

    // Calculate max steps based on binary length and modulation type
    final binaryLength = _selectedEntry!.modulatedSignal.binaryRepresentation
        .replaceAll(' ', '')
        .length;

    final bitsPerSymbol =
        _selectedEntry!.modulationType == ModulationType.qpsk ? 2 : 1;
    final maxSteps = (binaryLength / bitsPerSymbol).ceil();

    if (_currentDemodulationStep < maxSteps) {
      _currentDemodulationStep++;
      demodulateSelectedEntryStepByStep();
    }
  }

  // Move to previous demodulation step
  void previousDemodulationStep() {
    if (_selectedEntry == null || !_stepByStepDemodulation) return;

    if (_currentDemodulationStep > 0) {
      _currentDemodulationStep--;
      demodulateSelectedEntryStepByStep();
    }
  }

  // Load all history entries
  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _repository.getAllEntries();
    } catch (e) {
      debugPrint('Error loading history entries: $e');
      _entries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save a new modulation to history
  Future<void> saveModulation({
    required String originalText,
    required ModulationType modulationType,
    required ModulatedSignal modulatedSignal,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final entry = await _repository.saveModulation(
        originalText: originalText,
        modulationType: modulationType,
        modulatedSignal: modulatedSignal,
      );

      // Refresh entries
      await loadEntries();
    } catch (e) {
      debugPrint('Error saving modulation: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select an entry for demodulation
  void selectEntry(HistoryEntry entry) {
    _selectedEntry = entry;

    // Reset demodulation step when selecting a new entry
    _currentDemodulationStep = 0;

    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedEntry = null;
    _currentDemodulationStep = 0;
    notifyListeners();
  }

  // Update noise level
  void setNoiseLevel(double value) {
    if (value >= 0.0 && value <= 1.0) {
      _noiseLevel = value;
      notifyListeners();
    }
  }

  // Demodulate the selected entry
  Future<void> demodulateSelectedEntry() async {
    if (_selectedEntry == null) return;

    // If in step-by-step mode, use that method instead
    if (_stepByStepDemodulation) {
      await demodulateSelectedEntryStepByStep();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final updatedEntry = await _repository.demodulateEntry(
        entry: _selectedEntry!,
        noiseLevel: _noiseLevel,
      );

      // Update the entry with step-by-step flag (off)
      final finalEntry = updatedEntry.copyWith(
        isStepByStepDemodulation: false,
        currentDemodulationStep: 0,
        demodulationProgress: 100, // Full progress
      );

      // Update the entry in the list
      final index = _entries.indexWhere((e) => e.id == finalEntry.id);
      if (index >= 0) {
        _entries[index] = finalEntry;
      }

      // Update the selected entry
      _selectedEntry = finalEntry;
    } catch (e) {
      debugPrint('Error demodulating entry: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Demodulate the selected entry step by step
  Future<void> demodulateSelectedEntryStepByStep() async {
    if (_selectedEntry == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedEntry = await _repository.demodulateEntryStepByStep(
        entry: _selectedEntry!,
        currentStep: _currentDemodulationStep,
        noiseLevel: _noiseLevel,
      );

      // Update with step-by-step information
      final finalEntry = updatedEntry.copyWith(
        isStepByStepDemodulation: true,
        currentDemodulationStep: _currentDemodulationStep,
      );

      // Update the entry in the list
      final index = _entries.indexWhere((e) => e.id == finalEntry.id);
      if (index >= 0) {
        _entries[index] = finalEntry;
      }

      // Update the selected entry
      _selectedEntry = finalEntry;
    } catch (e) {
      debugPrint('Error demodulating entry step-by-step: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete an entry
  Future<void> deleteEntry(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.deleteEntry(id);
      if (success) {
        // Remove from local list
        _entries.removeWhere((entry) => entry.id == id);

        // Clear selection if the deleted entry was selected
        if (_selectedEntry?.id == id) {
          _selectedEntry = null;
          _currentDemodulationStep = 0;
        }
      }
    } catch (e) {
      debugPrint('Error deleting entry: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear all history
  Future<void> clearAllHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.clearAllHistory();
      if (success) {
        _entries.clear();
        _selectedEntry = null;
        _currentDemodulationStep = 0;
      }
    } catch (e) {
      debugPrint('Error clearing history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
