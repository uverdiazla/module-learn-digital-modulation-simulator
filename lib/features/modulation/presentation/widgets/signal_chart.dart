import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:modulearn/features/modulation/domain/entities/modulated_signal.dart';

class SignalChart extends StatelessWidget {
  final ModulatedSignal signal;
  final int samplePoints;
  final bool showSymbolBoundaries;
  final Color signalColor;
  final Color gridColor;
  final Color boundaryColor;

  const SignalChart({
    super.key,
    required this.signal,
    this.samplePoints = 500,
    this.showSymbolBoundaries = true,
    this.signalColor = Colors.blue,
    this.gridColor = Colors.grey,
    this.boundaryColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: LineChart(
          LineChartData(
            gridData: _buildGridData(),
            titlesData: _buildTitlesData(),
            borderData: _buildBorderData(),
            lineBarsData: [_buildSignalData()],
            extraLinesData:
                showSymbolBoundaries ? _buildSymbolBoundaries() : null,
            minX: 0,
            maxX: 1,
            minY: -1.2,
            maxY: 1.2,
          ),
        ),
      ),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawHorizontalLine: true,
      drawVerticalLine: true,
      horizontalInterval: 0.5,
      verticalInterval: 0.1,
      getDrawingHorizontalLine: (value) {
        // Draw a special line for y=0
        if (value == 0) {
          return FlLine(
            color: gridColor,
            strokeWidth: 1.5,
          );
        }
        return FlLine(
          color: gridColor.withOpacity(0.3),
          strokeWidth: 0.5,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: gridColor.withOpacity(0.3),
          strokeWidth: 0.5,
        );
      },
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: 0.5,
          getTitlesWidget: (value, meta) {
            if (value == 0) {
              return const Text('0');
            }
            if (value == 1) {
              return const Text('1');
            }
            if (value == -1) {
              return const Text('-1');
            }
            return const Text('');
          },
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(
        color: gridColor,
        width: 1,
      ),
    );
  }

  LineChartBarData _buildSignalData() {
    final points = signal.generateXYPoints(samplePoints);
    List<FlSpot> spots = [];

    for (var point in points) {
      spots.add(FlSpot(point[0], point[1]));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: signalColor,
      barWidth: 2,
      isStrokeCapRound: false,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  ExtraLinesData _buildSymbolBoundaries() {
    final symbolCount = signal.phases.length;
    if (symbolCount <= 1) return const ExtraLinesData();

    List<VerticalLine> verticalLines = [];

    // Create a vertical line at each symbol boundary
    for (int i = 1; i < symbolCount; i++) {
      final x = i / symbolCount;
      verticalLines.add(
        VerticalLine(
          x: x,
          color: boundaryColor.withOpacity(0.7),
          strokeWidth: 1,
          dashArray: [5, 5], // Dashed line
        ),
      );
    }

    return ExtraLinesData(
      verticalLines: verticalLines,
    );
  }
}
