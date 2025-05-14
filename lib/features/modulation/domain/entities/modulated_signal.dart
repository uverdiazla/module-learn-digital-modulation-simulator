import 'dart:math' as math;
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';

class ModulatedSignal {
  final String originalText;
  final String binaryRepresentation;
  final ModulationType modulationType;
  final List<double> phases;
  final List<double> amplitudes;
  final List<double> frequencies;
  final int samplesPerSymbol;
  final double baseFrequency;

  ModulatedSignal({
    required this.originalText,
    required this.binaryRepresentation,
    required this.modulationType,
    required this.phases,
    required this.amplitudes,
    this.frequencies = const [],
    this.samplesPerSymbol = 16,
    this.baseFrequency = 1.0,
  });

  /// Generates a list of y-values for the modulated signal
  List<double> generateSignalPoints(int totalSamples) {
    List<double> signalPoints = [];
    final symbolCount = phases.length;

    if (symbolCount == 0) {
      return List.filled(totalSamples, 0.0);
    }

    final samplesPerSymbolActual = totalSamples ~/ symbolCount;

    // Add additional check to prevent division by zero
    if (samplesPerSymbolActual <= 0) {
      return List.filled(totalSamples, 0.0);
    }

    switch (modulationType) {
      case ModulationType.bpsk:
      case ModulationType.qpsk:
        return _generatePSKSignalPoints(
            totalSamples, samplesPerSymbolActual, symbolCount);
      case ModulationType.ask:
        return _generateASKSignalPoints(
            totalSamples, samplesPerSymbolActual, symbolCount);
      case ModulationType.fsk:
        return _generateFSKSignalPoints(
            totalSamples, samplesPerSymbolActual, symbolCount);
    }
  }

  /// Generates PSK (Phase Shift Keying) signal points
  List<double> _generatePSKSignalPoints(
      int totalSamples, int samplesPerSymbolActual, int symbolCount) {
    List<double> signalPoints = [];

    for (int symbolIndex = 0; symbolIndex < symbolCount; symbolIndex++) {
      final phase = phases[symbolIndex];
      final amplitude = amplitudes[symbolIndex];

      for (int sample = 0; sample < samplesPerSymbolActual; sample++) {
        final t = sample / samplesPerSymbolActual;
        // Generate sinusoidal wave with the given phase and amplitude
        final y = amplitude *
            math.sin(2 * math.pi * baseFrequency * t + phase * math.pi / 180);
        signalPoints.add(y);
      }
    }

    return signalPoints;
  }

  /// Generates ASK (Amplitude Shift Keying) signal points
  List<double> _generateASKSignalPoints(
      int totalSamples, int samplesPerSymbolActual, int symbolCount) {
    List<double> signalPoints = [];

    for (int symbolIndex = 0; symbolIndex < symbolCount; symbolIndex++) {
      final amplitude = amplitudes[symbolIndex];

      for (int sample = 0; sample < samplesPerSymbolActual; sample++) {
        final t = sample / samplesPerSymbolActual;
        // Generate sinusoidal wave with varying amplitude
        final y = amplitude * math.sin(2 * math.pi * baseFrequency * t);
        signalPoints.add(y);
      }
    }

    return signalPoints;
  }

  /// Generates FSK (Frequency Shift Keying) signal points
  List<double> _generateFSKSignalPoints(
      int totalSamples, int samplesPerSymbolActual, int symbolCount) {
    List<double> signalPoints = [];

    if (frequencies.isEmpty || frequencies.length != symbolCount) {
      // Fallback if frequencies not provided
      return _generatePSKSignalPoints(
          totalSamples, samplesPerSymbolActual, symbolCount);
    }

    for (int symbolIndex = 0; symbolIndex < symbolCount; symbolIndex++) {
      final frequency = frequencies[symbolIndex];
      final amplitude = amplitudes[symbolIndex];

      for (int sample = 0; sample < samplesPerSymbolActual; sample++) {
        final t = sample / samplesPerSymbolActual;
        // Generate sinusoidal wave with varying frequency
        final y = amplitude * math.sin(2 * math.pi * frequency * t);
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

    // Special case for single point to avoid division by zero
    if (yPoints.length == 1) {
      return [
        [0.0, yPoints[0]]
      ];
    }

    // Ensure we have at least two points to calculate proper x intervals
    final pointCount = yPoints.length;
    if (pointCount < 2) {
      return [
        [0.0, 0.0]
      ];
    }

    for (int i = 0; i < pointCount; i++) {
      final x = i / (pointCount - 1);
      points.add([x, yPoints[i]]);
    }

    return points;
  }
}
