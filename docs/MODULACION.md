# Modulación Digital: Principios y Algoritmos

Este documento técnico explica los principios y algoritmos detrás de las técnicas de modulación digital implementadas en ModuLearn.

## Contenido

- [Introducción a la Modulación Digital](#introducción-a-la-modulación-digital)
- [Representación de Señales](#representación-de-señales)
- [BPSK (Binary Phase Shift Keying)](#bpsk-binary-phase-shift-keying)
- [QPSK (Quadrature Phase Shift Keying)](#qpsk-quadrature-phase-shift-keying)
- [Implementación en ModuLearn](#implementación-en-modulearn)
- [Referencias](#referencias)

## Introducción a la Modulación Digital

La modulación digital es el proceso mediante el cual se modifica una señal portadora (generalmente una onda sinusoidal) para transmitir información digital. Este proceso es fundamental en las comunicaciones digitales modernas, incluyendo Wi-Fi, comunicaciones móviles, y televisión digital.

### ¿Por qué es necesaria la modulación?

- **Eficiencia en la transmisión**: Las técnicas de modulación permiten aprovechar mejor el ancho de banda disponible.
- **Resistencia al ruido**: Las señales moduladas pueden diseñarse para resistir mejor las interferencias.
- **Multiplexación**: Permite transmitir múltiples señales simultáneamente.
- **Adaptación al medio**: Facilita la transmisión de señales a través de diferentes medios (aire, cable, fibra óptica).

## Representación de Señales

En ModuLearn, las señales moduladas se representan matemáticamente mediante:

### Señal Portadora

La señal portadora básica se define como:

```
s(t) = A * cos(2πft + φ)
```

Donde:
- `A` es la amplitud
- `f` es la frecuencia
- `φ` es la fase
- `t` es el tiempo

### Representación Digital de la Señal

En el contexto de la aplicación, la señal se representa como una secuencia de puntos muestreados:

```dart
List<double> generateSignalPoints(int totalSamples) {
  List<double> signalPoints = [];
  final symbolCount = phases.length;
  final samplesPerSymbolActual = totalSamples ~/ symbolCount;
  
  for (int symbolIndex = 0; symbolIndex < symbolCount; symbolIndex++) {
    final phase = phases[symbolIndex];
    final amplitude = amplitudes[symbolIndex];
    
    for (int sample = 0; sample < samplesPerSymbolActual; sample++) {
      final t = sample / samplesPerSymbolActual;
      final y = amplitude * math.sin(2 * math.pi * frequency * t + phase * math.pi / 180);
      signalPoints.add(y);
    }
  }
  
  return signalPoints;
}
```

## BPSK (Binary Phase Shift Keying)

BPSK es una forma de modulación de fase donde la fase de la portadora cambia entre dos valores separados por 180° (típicamente 0° y 180°) para representar bits binarios (0 y 1).

### Mapeo de Bits a Fases

| Bit | Fase |
|-----|------|
| 0   | 0°   |
| 1   | 180° |

### Algoritmo de Modulación BPSK

El algoritmo para modular una secuencia de bits usando BPSK es:

1. Para cada bit en la secuencia:
   - Si el bit es 0, asignar fase = 0°
   - Si el bit es 1, asignar fase = 180°
2. Generar la señal usando la fase asignada para cada símbolo

```dart
// Para BPSK: 0° para bit 0, 180° para bit 1
for (int i = 0; i < cleanBinary.length; i++) {
  final bit = cleanBinary[i];
  phases.add(bit == '0' ? 0.0 : 180.0);
  amplitudes.add(1.0); // Amplitud constante para PSK
}
```

### Representación Matemática

Para un bit 'b' (0 o 1), la señal BPSK es:

```
s(t) = A * cos(2πft + π*b)
```

## QPSK (Quadrature Phase Shift Keying)

QPSK es una modulación de fase donde la fase de la portadora puede tomar uno de cuatro valores, generalmente separados por 90°. Esto permite transmitir 2 bits por símbolo.

### Mapeo de Dibits a Fases

| Dibit | Fase |
|-------|------|
| 00    | 45°  |
| 01    | 135° |
| 10    | 225° |
| 11    | 315° |

### Algoritmo de Modulación QPSK

El algoritmo para modular una secuencia de bits usando QPSK es:

1. Agrupar los bits en pares (dibits)
2. Para cada dibit:
   - Si el dibit es 00, asignar fase = 45°
   - Si el dibit es 01, asignar fase = 135°
   - Si el dibit es 10, asignar fase = 225°
   - Si el dibit es 11, asignar fase = 315°
3. Generar la señal usando la fase asignada para cada símbolo

```dart
// Para QPSK: Procesar 2 bits a la vez
for (int i = 0; i < paddedBinary.length; i += 2) {
  final bit1 = paddedBinary[i];
  final bit2 = i + 1 < paddedBinary.length ? paddedBinary[i + 1] : '0';
  final dibit = '$bit1$bit2';
  
  double phase = 0.0;
  switch (dibit) {
    case '00':
      phase = 45.0;
      break;
    case '01':
      phase = 135.0;
      break;
    case '10':
      phase = 225.0;
      break;
    case '11':
      phase = 315.0;
      break;
  }
  
  phases.add(phase);
  amplitudes.add(1.0); // Amplitud constante para PSK
}
```

### Representación Matemática

Para un par de bits 'b1b2', la señal QPSK es:

```
s(t) = A * cos(2πft + φ(b1b2))
```

Donde φ(b1b2) es el ángulo de fase correspondiente al dibit.

## Implementación en ModuLearn

### Proceso de Modulación

1. **Conversión de texto a binario**: El mensaje de texto se convierte a una representación binaria usando codificación ASCII (8 bits por carácter).
   ```dart
   String textToBinary(String text) {
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
   ```

2. **Generación de la señal modulada**: Se asignan fases a los bits o dibits según el tipo de modulación, y se genera la señal correspondiente.

3. **Visualización**: La señal modulada se visualiza utilizando fl_chart para mostrar la forma de onda resultante.

### Modo Paso a Paso

El modo paso a paso permite visualizar cómo se construye la señal modulada bit por bit o símbolo por símbolo:

```dart
ModulatedSignal generateStepByStepModulatedSignal({
  required String text,
  required ModulationType modulationType,
  required int currentStep,
}) {
  // Convertir texto a binario
  final binaryString = TextConverter.textToBinary(text);
  
  // Eliminar espacios para procesar el binario
  final cleanBinary = binaryString.replaceAll(' ', '');
  
  // Generar fases y amplitudes según el tipo de modulación
  final List<double> phases = [];
  final List<double> amplitudes = [];
  
  // Determinar cuántos bits procesar según el paso actual
  int bitsToProcess = 0;
  
  if (modulationType == ModulationType.bpsk) {
    // Para BPSK: procesar un bit a la vez
    bitsToProcess = currentStep;
    if (bitsToProcess > cleanBinary.length) {
      bitsToProcess = cleanBinary.length;
    }
    
    // ... lógica de procesamiento BPSK ...
  } else if (modulationType == ModulationType.qpsk) {
    // Para QPSK: procesar dos bits a la vez
    bitsToProcess = currentStep * 2;
    if (bitsToProcess > cleanBinary.length) {
      bitsToProcess = cleanBinary.length;
    }
    
    // ... lógica de procesamiento QPSK ...
  }
  
  // ... crear y retornar la señal modulada ...
}
```

## Referencias

1. Proakis, J. G., & Salehi, M. (2008). *Digital Communications* (5th ed.). McGraw-Hill.
2. Haykin, S. (2014). *Communication Systems* (5th ed.). Wiley.
3. Sklar, B. (2017). *Digital Communications: Fundamentals and Applications* (2nd ed.). Prentice Hall.
4. [Introduction to Digital Modulation - National Instruments](https://www.ni.com/en-us/innovations/white-papers/06/introduction-to-digital-modulation.html)
5. [Phase Shift Keying - Wikipedia](https://en.wikipedia.org/wiki/Phase-shift_keying) 