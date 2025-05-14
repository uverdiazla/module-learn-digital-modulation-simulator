import 'package:modulearn/core/utils/text_converter.dart';
import 'package:modulearn/features/modulation/domain/entities/modulated_signal.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/domain/repositories/modulation_repository.dart';

class ModulationRepositoryImpl implements ModulationRepository {
  // Constants for ASK and FSK modulation
  static const double _lowAmplitude = 0.2;
  static const double _highAmplitude = 1.0;
  static const double _lowFrequency = 0.5;
  static const double _highFrequency = 2.0;

  @override
  ModulatedSignal generateModulatedSignal({
    required String text,
    required ModulationType modulationType,
  }) {
    // Convert text to binary
    final binaryString = TextConverter.textToBinary(text);

    // Remove spaces to process the binary
    final cleanBinary = binaryString.replaceAll(' ', '');

    // Generate phases, amplitudes and frequencies based on modulation type
    List<double> phases = [];
    List<double> amplitudes = [];
    List<double> frequencies = [];

    switch (modulationType) {
      case ModulationType.bpsk:
        _generateBPSKModulation(cleanBinary, phases, amplitudes);
        break;
      case ModulationType.qpsk:
        _generateQPSKModulation(cleanBinary, phases, amplitudes);
        break;
      case ModulationType.ask:
        _generateASKModulation(cleanBinary, phases, amplitudes);
        break;
      case ModulationType.fsk:
        _generateFSKModulation(cleanBinary, phases, amplitudes, frequencies);
        break;
    }

    return ModulatedSignal(
      originalText: text,
      binaryRepresentation: binaryString,
      modulationType: modulationType,
      phases: phases,
      amplitudes: amplitudes,
      frequencies: frequencies,
    );
  }

  /// Generate BPSK modulation parameters
  void _generateBPSKModulation(
      String binary, List<double> phases, List<double> amplitudes) {
    // For BPSK: 0° for bit 0, 180° for bit 1
    for (int i = 0; i < binary.length; i++) {
      final bit = binary[i];
      phases.add(bit == '0' ? 0.0 : 180.0);
      amplitudes.add(1.0); // Constant amplitude for PSK
    }
  }

  /// Generate QPSK modulation parameters
  void _generateQPSKModulation(
      String binary, List<double> phases, List<double> amplitudes) {
    // For QPSK: Process 2 bits at a time
    // 00: 45°, 01: 135°, 10: 225°, 11: 315°

    // Pad the binary string if needed to make its length a multiple of 2
    String paddedBinary = binary;
    if (binary.length % 2 != 0) {
      paddedBinary = binary + '0';
    }

    for (int i = 0; i < paddedBinary.length; i += 2) {
      final bit1 = paddedBinary[i];
      final bit2 = i + 1 < paddedBinary.length ? paddedBinary[i + 1] : '0';
      final dibit = '$bit1$bit2';

      double phase = 0.0;
      switch (dibit) {
        case '00':
          phase = 45.0;
          break;
        case '01':
          phase = 135.0;
          break;
        case '10':
          phase = 225.0;
          break;
        case '11':
          phase = 315.0;
          break;
      }

      phases.add(phase);
      amplitudes.add(1.0); // Constant amplitude for PSK
    }
  }

  /// Generate ASK modulation parameters
  void _generateASKModulation(
      String binary, List<double> phases, List<double> amplitudes) {
    // For ASK: Low amplitude for bit 0, high amplitude for bit 1
    for (int i = 0; i < binary.length; i++) {
      final bit = binary[i];
      phases.add(0.0); // Constant phase for ASK
      amplitudes.add(bit == '0' ? _lowAmplitude : _highAmplitude);
    }
  }

  /// Generate FSK modulation parameters
  void _generateFSKModulation(String binary, List<double> phases,
      List<double> amplitudes, List<double> frequencies) {
    // For FSK: Low frequency for bit 0, high frequency for bit 1
    for (int i = 0; i < binary.length; i++) {
      final bit = binary[i];
      phases.add(0.0); // Constant phase for FSK
      amplitudes.add(1.0); // Constant amplitude for FSK
      frequencies.add(bit == '0' ? _lowFrequency : _highFrequency);
    }
  }

  @override
  ModulatedSignal generateStepByStepModulatedSignal({
    required String text,
    required ModulationType modulationType,
    required int currentStep,
  }) {
    // Convert text to binary
    final binaryString = TextConverter.textToBinary(text);

    // Remove spaces to process the binary
    final cleanBinary = binaryString.replaceAll(' ', '');

    // Generate phases, amplitudes and frequencies based on modulation type
    List<double> phases = [];
    List<double> amplitudes = [];
    List<double> frequencies = [];

    if (currentStep <= 0) {
      return ModulatedSignal(
        originalText: text,
        binaryRepresentation: binaryString,
        modulationType: modulationType,
        phases: [],
        amplitudes: [],
        frequencies: [],
      );
    }

    // Determine how many bits to process based on the current step and modulation type
    int bitsToProcess =
        _calculateBitsToProcess(modulationType, currentStep, cleanBinary);

    switch (modulationType) {
      case ModulationType.bpsk:
        _generateBPSKStepByStep(cleanBinary, bitsToProcess, phases, amplitudes);
        break;
      case ModulationType.qpsk:
        _generateQPSKStepByStep(cleanBinary, bitsToProcess, phases, amplitudes);
        break;
      case ModulationType.ask:
        _generateASKStepByStep(cleanBinary, bitsToProcess, phases, amplitudes);
        break;
      case ModulationType.fsk:
        _generateFSKStepByStep(
            cleanBinary, bitsToProcess, phases, amplitudes, frequencies);
        break;
    }

    return ModulatedSignal(
      originalText: text,
      binaryRepresentation: binaryString,
      modulationType: modulationType,
      phases: phases,
      amplitudes: amplitudes,
      frequencies: frequencies,
    );
  }

  /// Calculate how many bits to process in step-by-step mode
  int _calculateBitsToProcess(
      ModulationType modulationType, int currentStep, String binary) {
    int bitsToProcess = 0;

    if (modulationType == ModulationType.qpsk) {
      // For QPSK: process two bits at a time
      bitsToProcess = currentStep * 2;
    } else {
      // For BPSK, ASK, FSK: process one bit at a time
      bitsToProcess = currentStep;
    }

    if (bitsToProcess > binary.length) {
      bitsToProcess = binary.length;
    }

    return bitsToProcess;
  }

  /// Generate BPSK modulation parameters for step-by-step mode
  void _generateBPSKStepByStep(String binary, int bitsToProcess,
      List<double> phases, List<double> amplitudes) {
    for (int i = 0; i < bitsToProcess; i++) {
      final bit = binary[i];
      phases.add(bit == '0' ? 0.0 : 180.0);
      amplitudes.add(1.0);
    }
  }

  /// Generate QPSK modulation parameters for step-by-step mode
  void _generateQPSKStepByStep(String binary, int bitsToProcess,
      List<double> phases, List<double> amplitudes) {
    for (int i = 0; i < bitsToProcess; i += 2) {
      final bit1 = binary[i];
      final bit2 = i + 1 < bitsToProcess ? binary[i + 1] : '0';
      final dibit = '$bit1$bit2';

      double phase = 0.0;
      switch (dibit) {
        case '00':
          phase = 45.0;
          break;
        case '01':
          phase = 135.0;
          break;
        case '10':
          phase = 225.0;
          break;
        case '11':
          phase = 315.0;
          break;
      }

      phases.add(phase);
      amplitudes.add(1.0);
    }
  }

  /// Generate ASK modulation parameters for step-by-step mode
  void _generateASKStepByStep(String binary, int bitsToProcess,
      List<double> phases, List<double> amplitudes) {
    for (int i = 0; i < bitsToProcess; i++) {
      final bit = binary[i];
      phases.add(0.0); // Constant phase for ASK
      amplitudes.add(bit == '0' ? _lowAmplitude : _highAmplitude);
    }
  }

  /// Generate FSK modulation parameters for step-by-step mode
  void _generateFSKStepByStep(String binary, int bitsToProcess,
      List<double> phases, List<double> amplitudes, List<double> frequencies) {
    for (int i = 0; i < bitsToProcess; i++) {
      final bit = binary[i];
      phases.add(0.0); // Constant phase for FSK
      amplitudes.add(1.0); // Constant amplitude for FSK
      frequencies.add(bit == '0' ? _lowFrequency : _highFrequency);
    }
  }
}
