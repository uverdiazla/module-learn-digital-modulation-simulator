enum ModulationType {
  bpsk(
    name: 'BPSK',
    descriptionKey: 'bpsk_description',
    bitsPerSymbol: 1,
  ),
  qpsk(
    name: 'QPSK',
    descriptionKey: 'qpsk_description',
    bitsPerSymbol: 2,
  );

  final String name;
  final String descriptionKey;
  final int bitsPerSymbol;

  const ModulationType({
    required this.name,
    required this.descriptionKey,
    required this.bitsPerSymbol,
  });
}
