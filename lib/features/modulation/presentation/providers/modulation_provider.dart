import 'package:flutter/material.dart';
import 'package:modulearn/features/modulation/data/models/modulation_repository_impl.dart';
import 'package:modulearn/features/modulation/domain/entities/modulated_signal.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/domain/repositories/modulation_repository.dart';

class ModulationProvider extends ChangeNotifier {
  final ModulationRepository _repository = ModulationRepositoryImpl();

  // Input parameters
  String _inputText = '';
  ModulationType _modulationType = ModulationType.bpsk;
  bool _stepByStepMode = false;
  int _currentStep = 0;

  // Output results
  ModulatedSignal? _modulatedSignal;

  // Getters
  String get inputText => _inputText;
  ModulationType get modulationType => _modulationType;
  bool get stepByStepMode => _stepByStepMode;
  int get currentStep => _currentStep;
  ModulatedSignal? get modulatedSignal => _modulatedSignal;
  bool get hasResult => _modulatedSignal != null;

  // Methods to update state
  void setInputText(String text) {
    _inputText = text;
    _resetStepByStep();
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
      _modulatedSignal = _repository.generateStepByStepModulatedSignal(
        text: _inputText,
        modulationType: _modulationType,
        currentStep: _currentStep,
      );
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
    notifyListeners();
  }
}
