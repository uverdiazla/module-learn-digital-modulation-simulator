import 'package:modulearn/core/utils/text_converter.dart';
import 'package:modulearn/features/modulation/domain/entities/modulated_signal.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:modulearn/features/modulation/domain/repositories/modulation_repository.dart';

class ModulationRepositoryImpl implements ModulationRepository {
  @override
  ModulatedSignal generateModulatedSignal({
    required String text,
    required ModulationType modulationType,
  }) {
    // Convert text to binary
    final binaryString = TextConverter.textToBinary(text);

    // Remove spaces to process the binary
    final cleanBinary = binaryString.replaceAll(' ', '');

    // Generate phases and amplitudes based on modulation type
    final List<double> phases = [];
    final List<double> amplitudes = [];

    if (modulationType == ModulationType.bpsk) {
      // For BPSK: 0° for bit 0, 180° for bit 1
      for (int i = 0; i < cleanBinary.length; i++) {
        final bit = cleanBinary[i];
        phases.add(bit == '0' ? 0.0 : 180.0);
        amplitudes.add(1.0); // Constant amplitude for PSK
      }
    } else if (modulationType == ModulationType.qpsk) {
      // For QPSK: Process 2 bits at a time
      // 00: 45°, 01: 135°, 10: 225°, 11: 315°

      // Pad the binary string if needed to make its length a multiple of 2
      String paddedBinary = cleanBinary;
      if (cleanBinary.length % 2 != 0) {
        paddedBinary = cleanBinary + '0';
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

    return ModulatedSignal(
      originalText: text,
      binaryRepresentation: binaryString,
      modulationType: modulationType,
      phases: phases,
      amplitudes: amplitudes,
    );
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

    // Generate phases and amplitudes based on modulation type
    final List<double> phases = [];
    final List<double> amplitudes = [];

    if (currentStep <= 0) {
      return ModulatedSignal(
        originalText: text,
        binaryRepresentation: binaryString,
        modulationType: modulationType,
        phases: [],
        amplitudes: [],
      );
    }

    // Determine how many bits to process based on the current step
    int bitsToProcess = 0;

    if (modulationType == ModulationType.bpsk) {
      // For BPSK: process one bit at a time
      bitsToProcess = currentStep;
      if (bitsToProcess > cleanBinary.length) {
        bitsToProcess = cleanBinary.length;
      }

      for (int i = 0; i < bitsToProcess; i++) {
        final bit = cleanBinary[i];
        phases.add(bit == '0' ? 0.0 : 180.0);
        amplitudes.add(1.0);
      }
    } else if (modulationType == ModulationType.qpsk) {
      // For QPSK: process two bits at a time
      bitsToProcess = currentStep * 2;
      if (bitsToProcess > cleanBinary.length) {
        bitsToProcess = cleanBinary.length;
      }

      for (int i = 0; i < bitsToProcess; i += 2) {
        final bit1 = cleanBinary[i];
        final bit2 = i + 1 < bitsToProcess ? cleanBinary[i + 1] : '0';
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

    return ModulatedSignal(
      originalText: text,
      binaryRepresentation: binaryString,
      modulationType: modulationType,
      phases: phases,
      amplitudes: amplitudes,
    );
  }
}
