import 'package:flutter/material.dart';
import 'package:modulearn/core/utils/platform_utils.dart';
import 'package:modulearn/core/utils/responsive_utils.dart';
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
      if (modulationType == ModulationType.qpsk) {
        processedBits = currentStep * 2;
      } else {
        // BPSK, ASK, FSK process one bit at a time
        processedBits = currentStep;
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
        padding: EdgeInsets.all(PlatformUtils.isWeb ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.binaryRepresentation,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: PlatformUtils.isWeb ? 14 : 16,
              ),
            ),
            SizedBox(height: PlatformUtils.isWeb ? 6 : 8),
            _buildBinaryText(cleanBinary, processedBits, context),
            if (stepByStepMode)
              _buildStepInfo(cleanBinary, processedBits, context),
          ],
        ),
      ),
    );
  }

  Widget _buildBinaryText(
      String binary, int processedBits, BuildContext context) {
    List<Widget> binaryChars = [];
    
    // Determine font size based on platform and screen size
    final double fontSize = PlatformUtils.isWeb
        ? (ResponsiveUtils.isSmallScreen(context) ? 12 : 14)
        : 16;

    // Adjust spacing for better display on web
    final double spacing = PlatformUtils.isWeb ? 1 : 2;

    for (int i = 0; i < binary.length; i++) {
      // Add a space every 8 bits (byte)
      if (i > 0 && i % 8 == 0) {
        binaryChars.add(Text(' ', style: TextStyle(letterSpacing: spacing)));
      }

      // Determine if this bit is processed in the current step
      final bool isProcessed = i < processedBits;

      // For QPSK, highlight pairs of bits
      final bool isCurrentlyProcessing;

      if (modulationType == ModulationType.qpsk) {
        isCurrentlyProcessing = stepByStepMode &&
            (i == processedBits - 1 || i == processedBits - 2);
      } else {
        // For BPSK, ASK, FSK - just highlight the current bit
        isCurrentlyProcessing = stepByStepMode && i == processedBits - 1;
      }

      binaryChars.add(
        Text(
          binary[i],
          style: TextStyle(
            color: isProcessed
                ? (isCurrentlyProcessing ? Colors.red : Colors.blue)
                : Colors.grey,
            fontWeight:
                isCurrentlyProcessing ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(spacing: spacing, children: binaryChars),
    );
  }

  Widget _buildStepInfo(
      String binary, int processedBits, BuildContext context) {
    if (!stepByStepMode || processedBits <= 0) {
      return const SizedBox.shrink();
    }

    String currentBits;
    String paramValue;
    String paramName;

    // Get parameter name based on modulation type
    switch (modulationType) {
      case ModulationType.bpsk:
      case ModulationType.qpsk:
        paramName = l10n.phase;
        break;
      case ModulationType.ask:
        paramName = l10n.amplitude;
        break;
      case ModulationType.fsk:
        paramName = l10n.frequency;
        break;
    }

    if (modulationType == ModulationType.bpsk) {
      // Get the last processed bit
      final bit = binary[processedBits - 1];
      currentBits = bit;
      paramValue = bit == '0' ? '0°' : '180°';
    } else if (modulationType == ModulationType.qpsk) {
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
          paramValue = '45°';
          break;
        case '01':
          paramValue = '135°';
          break;
        case '10':
          paramValue = '225°';
          break;
        case '11':
          paramValue = '315°';
          break;
        default:
          paramValue = 'N/A';
      }
    } else if (modulationType == ModulationType.ask) {
      // ASK: bit 0 = low amplitude, bit 1 = high amplitude
      final bit = binary[processedBits - 1];
      currentBits = bit;
      paramValue = bit == '0' ? '0.2A' : '1.0A';
    } else {
      // FSK: bit 0 = low frequency, bit 1 = high frequency
      final bit = binary[processedBits - 1];
      currentBits = bit;
      paramValue = bit == '0' ? '0.5f' : '2.0f';
    }

    // More compact spacing on web
    final double topPadding = PlatformUtils.isWeb ? 12.0 : 16.0;
    final double fontSize = PlatformUtils.isWeb ? 13.0 : 14.0;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            modulationType == ModulationType.qpsk
                ? l10n.currentDibit
                : l10n.currentBit,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
          Text(
            currentBits,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$paramName ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
          Text(
            paramValue,
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
