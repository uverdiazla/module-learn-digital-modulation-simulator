enum ModulationType {
  bpsk(
    name: 'BPSK',
    description:
        'Binary Phase Shift Keying - Uses 2 phase states (0° and 180°) to represent binary 0 and 1',
    bitsPerSymbol: 1,
  ),
  qpsk(
    name: 'QPSK',
    description:
        'Quadrature Phase Shift Keying - Uses 4 phase states (0°, 90°, 180°, 270°) to represent 2 bits per symbol',
    bitsPerSymbol: 2,
  );

  final String name;
  final String description;
  final int bitsPerSymbol;

  const ModulationType({
    required this.name,
    required this.description,
    required this.bitsPerSymbol,
  });
}
