import 'package:flutter/material.dart';
import 'package:modulearn/features/modulation/data/models/modulation_repository_impl.dart';
import 'package:modulearn/features/modulation/domain/entities/modulated_signal.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/domain/repositories/modulation_repository.dart';
import 'package:modulearn/features/modulation/presentation/providers/history_provider.dart';

class ModulationProvider extends ChangeNotifier {
  final ModulationRepository _repository = ModulationRepositoryImpl();
  
  // Reference to HistoryProvider to avoid circular dependencies
  HistoryProvider? _historyProvider;

  // Input parameters
  String _inputText = '';
  ModulationType _modulationType = ModulationType.bpsk;
  bool _stepByStepMode = false;
  int _currentStep = 0;
  
  // Information about the audio source
  String? _audioSource;
  String? _audioTimestamp;

  // Output results
  ModulatedSignal? _modulatedSignal;

  // Getters
  String get inputText => _inputText;
  ModulationType get modulationType => _modulationType;
  bool get stepByStepMode => _stepByStepMode;
  int get currentStep => _currentStep;
  ModulatedSignal? get modulatedSignal => _modulatedSignal;
  bool get hasResult => _modulatedSignal != null;
  
  // Getters for audio information
  String? get audioSource => _audioSource;
  String? get audioTimestamp => _audioTimestamp;
  bool get isFromAudio => _audioSource != null;

  // Set the history provider
  void setHistoryProvider(HistoryProvider provider) {
    _historyProvider = provider;
  }

  // Methods to update state
  void setInputText(String text) {
    _inputText = text;
    _resetStepByStep();
    notifyListeners();
  }
  
  // Update text and mark it as coming from an audio recording
  void setInputTextFromAudio(String text,
      {required String recordingId, required String timestamp}) {
    _inputText = text;
    _audioSource = "Recording #$recordingId";
    _audioTimestamp = timestamp;
    _resetStepByStep();
    notifyListeners();
  }

  // Clear audio source information
  void clearAudioSource() {
    _audioSource = null;
    _audioTimestamp = null;
    notifyListeners();
  }

  void setModulationType(ModulationType type) {
    _modulationType = type;
    _resetStepByStep();
    notifyListeners();
  }

  void toggleStepByStepMode() {
    _stepByStepMode = !_stepByStepMode;
    _resetStepByStep();
    notifyListeners();
  }

  void _resetStepByStep() {
    _currentStep = 0;
    _modulatedSignal = null;
  }

  // Generate modulated signal
  void generateModulation() {
    if (_inputText.isEmpty) return;

    if (_stepByStepMode) {
      // For the initial step, ensure we have a valid but empty signal
      if (_currentStep == 0) {
        _modulatedSignal = _repository.generateStepByStepModulatedSignal(
          text: _inputText,
          modulationType: _modulationType,
          currentStep: 0,
        );
      } else {
        _modulatedSignal = _repository.generateStepByStepModulatedSignal(
          text: _inputText,
          modulationType: _modulationType,
          currentStep: _currentStep,
        );
      }
    } else {
      _modulatedSignal = _repository.generateModulatedSignal(
        text: _inputText,
        modulationType: _modulationType,
      );
    }

    notifyListeners();
  }

  // For step by step mode: move to next step
  void nextStep() {
    if (!_stepByStepMode) return;

    // Calculate max steps based on modulation type and binary length
    final binaryLength = _inputText.isEmpty
        ? 0
        : _modulatedSignal!.binaryRepresentation.replaceAll(' ', '').length;

    final maxSteps = _modulationType == ModulationType.bpsk
        ? binaryLength
        : (binaryLength + 1) ~/ 2; // For QPSK (handles odd lengths)

    if (_currentStep < maxSteps) {
      _currentStep++;
      generateModulation();
    }
  }

  // For step by step mode: move to previous step
  void previousStep() {
    if (!_stepByStepMode) return;

    if (_currentStep > 0) {
      _currentStep--;
      generateModulation();
    }
  }

  // Reset everything
  void reset() {
    _inputText = '';
    _modulationType = ModulationType.bpsk;
    _stepByStepMode = false;
    _currentStep = 0;
    _modulatedSignal = null;
    _audioSource = null;
    _audioTimestamp = null;
    notifyListeners();
  }
  
  // Save the current modulation to history
  Future<void> saveToHistory() async {
    if (!hasResult || _historyProvider == null) return;

    await _historyProvider!.saveModulation(
      originalText: _inputText,
      modulationType: _modulationType,
      modulatedSignal: _modulatedSignal!,
    );
  }
}
