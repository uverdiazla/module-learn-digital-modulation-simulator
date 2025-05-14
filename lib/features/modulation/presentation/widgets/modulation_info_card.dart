import 'package:flutter/material.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ModulationInfoCard extends StatelessWidget {
  final ModulationType modulationType;
  final AppLocalizations l10n;

  const ModulationInfoCard({
    super.key,
    required this.modulationType,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  l10n.about(modulationType.name),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(modulationType == ModulationType.bpsk
                ? l10n.bpsk_description
                : l10n.qpsk_description),
            const SizedBox(height: 12),
            _buildDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    switch (modulationType) {
      case ModulationType.bpsk:
        return _buildBpskDetails();
      case ModulationType.qpsk:
        return _buildQpskDetails();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBpskDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bitToPhaseMapping,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildMappingRow('0', '0°'),
        const SizedBox(height: 4),
        _buildMappingRow('1', '180°'),
        const SizedBox(height: 12),
        Text(
          l10n.advantages,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBulletPoint(l10n.bpsk_advantage1),
        _buildBulletPoint(l10n.bpsk_advantage2),
        _buildBulletPoint(l10n.bpsk_advantage3),
        const SizedBox(height: 12),
        Text(
          l10n.disadvantages,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBulletPoint(l10n.bpsk_disadvantage1),
      ],
    );
  }

  Widget _buildQpskDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dibitToPhaseMapping,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildMappingRow('00', '45°'),
        const SizedBox(height: 4),
        _buildMappingRow('01', '135°'),
        const SizedBox(height: 4),
        _buildMappingRow('10', '225°'),
        const SizedBox(height: 4),
        _buildMappingRow('11', '315°'),
        const SizedBox(height: 12),
        Text(
          l10n.advantages,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBulletPoint(l10n.qpsk_advantage1),
        _buildBulletPoint(l10n.qpsk_advantage2),
        const SizedBox(height: 12),
        Text(
          l10n.disadvantages,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBulletPoint(l10n.qpsk_disadvantage1),
        _buildBulletPoint(l10n.qpsk_disadvantage2),
      ],
    );
  }

  Widget _buildMappingRow(String bits, String phase) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            bits,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.arrow_forward, size: 16),
        const SizedBox(width: 16),
        Container(
          width: 54,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            phase,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
