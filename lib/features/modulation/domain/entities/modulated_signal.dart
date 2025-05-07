import 'dart:math' as math;
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';

class ModulatedSignal {
  final String originalText;
  final String binaryRepresentation;
  final ModulationType modulationType;
  final List<double> phases;
  final List<double> amplitudes;
  final int samplesPerSymbol;
  final double frequency;

  ModulatedSignal({
    required this.originalText,
    required this.binaryRepresentation,
    required this.modulationType,
    required this.phases,
    required this.amplitudes,
    this.samplesPerSymbol = 16,
    this.frequency = 1.0,
  });

  /// Generates a list of y-values for the modulated signal
  List<double> generateSignalPoints(int totalSamples) {
    List<double> signalPoints = [];
    final symbolCount = phases.length;

    if (symbolCount == 0) {
      return List.filled(totalSamples, 0.0);
    }

    final samplesPerSymbolActual = totalSamples ~/ symbolCount;

    for (int symbolIndex = 0; symbolIndex < symbolCount; symbolIndex++) {
      final phase = phases[symbolIndex];
      final amplitude = amplitudes[symbolIndex];

      for (int sample = 0; sample < samplesPerSymbolActual; sample++) {
        final t = sample / samplesPerSymbolActual;
        // Generate sinusoidal wave with the given phase and amplitude
        final y = amplitude *
            math.sin(2 * math.pi * frequency * t + phase * math.pi / 180);
        signalPoints.add(y);
      }
    }

    return signalPoints;
  }

  /// Generates a list of [x,y] points for the modulated signal
  List<List<double>> generateXYPoints(int totalSamples) {
    List<List<double>> points = [];
    final yPoints = generateSignalPoints(totalSamples);

    if (yPoints.isEmpty) {
      return [];
    }

    if (yPoints.length == 1) {
      return [
        [0.0, yPoints[0]]
      ];
    }

    for (int i = 0; i < yPoints.length; i++) {
      final x = i / (yPoints.length - 1);
      points.add([x, yPoints[i]]);
    }

    return points;
  }
}
