class TextConverter {
  /// Converts text to binary representation (8 bits per character)
  static String textToBinary(String text) {
    if (text.isEmpty) return '';

    final StringBuffer binary = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      String charBinary = text.codeUnitAt(i).toRadixString(2).padLeft(8, '0');
      binary.write(charBinary);
      if (i < text.length - 1) {
        binary.write(' ');
      }
    }

    return binary.toString();
  }

  /// Converts binary string back to text (assumes 8 bits per character)
  static String binaryToText(String binary) {
    if (binary.isEmpty) return '';

    // Remove any spaces
    final cleanBinary = binary.replaceAll(' ', '');

    // Ensure the binary string length is a multiple of 8
    if (cleanBinary.length % 8 != 0) {
      throw const FormatException('Binary string length must be a multiple of 8');
    }

    final StringBuffer text = StringBuffer();

    for (int i = 0; i < cleanBinary.length; i += 8) {
      final byte = cleanBinary.substring(i, i + 8);
      final charCode = int.parse(byte, radix: 2);
      text.write(String.fromCharCode(charCode));
    }

    return text.toString();
  }
}
