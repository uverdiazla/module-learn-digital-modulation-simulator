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
  ),
  ask(
    name: 'ASK',
    descriptionKey: 'ask_description',
    bitsPerSymbol: 1,
  ),
  fsk(
    name: 'FSK',
    descriptionKey: 'fsk_description',
    bitsPerSymbol: 1,
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
