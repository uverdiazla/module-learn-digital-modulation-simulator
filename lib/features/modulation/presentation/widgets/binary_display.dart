import 'package:flutter/material.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BinaryDisplay extends StatelessWidget {
  final String binaryString;
  final ModulationType modulationType;
  final bool stepByStepMode;
  final int currentStep;
  final AppLocalizations l10n;

  const BinaryDisplay({
    super.key,
    required this.binaryString,
    required this.modulationType,
    this.stepByStepMode = false,
    this.currentStep = 0,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // Remove spaces for processing but keep them for display
    final cleanBinary = binaryString.replaceAll(' ', '');

    // Calculate how many bits are processed in the current step
    int processedBits = 0;
    if (stepByStepMode) {
      if (modulationType == ModulationType.bpsk) {
        processedBits = currentStep;
      } else if (modulationType == ModulationType.qpsk) {
        processedBits = currentStep * 2;
      }

      if (processedBits > cleanBinary.length) {
        processedBits = cleanBinary.length;
      }
    } else {
      processedBits = cleanBinary.length; // All bits are processed
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.binaryRepresentation,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildBinaryText(cleanBinary, processedBits),
            if (stepByStepMode) _buildStepInfo(cleanBinary, processedBits),
          ],
        ),
      ),
    );
  }

  Widget _buildBinaryText(String binary, int processedBits) {
    List<Widget> binaryChars = [];

    for (int i = 0; i < binary.length; i++) {
      // Add a space every 8 bits (byte)
      if (i > 0 && i % 8 == 0) {
        binaryChars.add(const Text(' ', style: TextStyle(letterSpacing: 2)));
      }

      // Determine if this bit is processed in the current step
      final bool isProcessed = i < processedBits;

      // For QPSK, highlight pairs of bits
      final bool isCurrentlyProcessing = stepByStepMode &&
          ((modulationType == ModulationType.bpsk && i == processedBits - 1) ||
              (modulationType == ModulationType.qpsk &&
                  (i == processedBits - 1 || i == processedBits - 2)));

      binaryChars.add(
        Text(
          binary[i],
          style: TextStyle(
            color: isProcessed
                ? (isCurrentlyProcessing ? Colors.red : Colors.blue)
                : Colors.grey,
            fontWeight:
                isCurrentlyProcessing ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 2,
      children: binaryChars
    );
  }

  Widget _buildStepInfo(String binary, int processedBits) {
    if (!stepByStepMode || processedBits <= 0) {
      return const SizedBox.shrink();
    }

    String currentBits;
    String phaseInfo;

    if (modulationType == ModulationType.bpsk) {
      // Get the last processed bit
      final bit = binary[processedBits - 1];
      currentBits = bit;
      phaseInfo = bit == '0' ? '0°' : '180°';
    } else {
      // Get the last processed pair of bits for QPSK
      final int startIndex =
          (processedBits % 2 == 0) ? processedBits - 2 : processedBits - 1;

      final bit1 = (startIndex < binary.length) ? binary[startIndex] : '0';
      final bit2 =
          (startIndex + 1 < binary.length) ? binary[startIndex + 1] : '0';
      final dibit = '$bit1$bit2';

      currentBits = dibit;

      // Determine the phase based on the dibit
      switch (dibit) {
        case '00':
          phaseInfo = '45°';
          break;
        case '01':
          phaseInfo = '135°';
          break;
        case '10':
          phaseInfo = '225°';
          break;
        case '11':
          phaseInfo = '315°';
          break;
        default:
          phaseInfo = 'N/A';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          Text(
            modulationType == ModulationType.bpsk
                ? l10n.currentBit
                : l10n.currentDibit,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            currentBits,
            style:
                const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Text(
            '${l10n.phase} ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            phaseInfo,
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
