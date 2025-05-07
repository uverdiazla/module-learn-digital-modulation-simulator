# ModuLearn - Simulador de Modulación Digital

Un simulador educativo de modulación digital desarrollado en Flutter que permite visualizar cómo se modula un mensaje de texto en señales digitales mediante técnicas como BPSK y QPSK.

![ModuLearn App](https://via.placeholder.com/800x400?text=ModuLearn+App)

## 📱 Características

- **Conversión de texto a binario**: Transforma automáticamente un mensaje de texto en su representación binaria (ASCII de 8 bits)
- **Múltiples técnicas de modulación**: Soporte para BPSK y QPSK con posibilidad de expansión futura
- **Visualización gráfica**: Representación visual de la señal modulada utilizando gráficos interactivos
- **Modo paso a paso**: Permite ver cómo se construye la señal bit por bit o símbolo por símbolo
- **Información educativa**: Explica los detalles de cada técnica de modulación con sus ventajas y desventajas
- **Soporte multiidioma**: Disponible en español e inglés, fácilmente extensible a más idiomas
- **Tema claro/oscuro**: Soporte para cambiar entre temas claro y oscuro

## 🚀 Instalación

### Requisitos

- Flutter SDK 3.0+
- Dart 3.0+

### Pasos

1. Clona el repositorio:
```bash
git clone https://github.com/tuusuario/modulearn.git
cd modulearn
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Genera los archivos de localización:
```bash
flutter gen-l10n
```

4. Ejecuta la aplicación:
```bash
flutter run
```

## 🔧 Arquitectura

ModuLearn está construido siguiendo una arquitectura limpia (Clean Architecture) para separar claramente las capas de la aplicación:

### Estructura de carpetas

```
lib/
├── core/                 # Componentes y utilidades principales
│   ├── theme/            # Configuración de temas y proveedores
│   └── utils/            # Utilitarios comunes (ej: conversión de texto)
├── features/             # Características de la aplicación
│   └── modulation/       # Característica principal - modulación digital
│       ├── data/         # Capa de datos
│       │   └── models/   # Implementaciones de repositorios
│       ├── domain/       # Capa de dominio
│       │   ├── entities/ # Entidades de dominio (ModulationType, ModulatedSignal)
│       │   └── repositories/ # Interfaces de repositorio
│       └── presentation/ # Capa de presentación
│           ├── providers/# Gestores de estado usando Provider
│           ├── screens/  # Pantallas de la aplicación
│           └── widgets/  # Widgets reutilizables
└── l10n/                 # Archivos de internacionalización
    ├── app_en.arb       # Traducciones en inglés
    └── app_es.arb       # Traducciones en español
```

### Capas

1. **Capa de dominio**: Contiene las entidades principales y las reglas de negocio, independientes de cualquier framework.
   - `ModulationType`: Enumeración que define los tipos de modulación (BPSK, QPSK).
   - `ModulatedSignal`: Representa una señal modulada con sus propiedades.
   - `ModulationRepository`: Interface que define operaciones de modulación.

2. **Capa de datos**: Implementa las interfaces definidas en la capa de dominio.
   - `ModulationRepositoryImpl`: Implementa la lógica para generar señales moduladas.

3. **Capa de presentación**: Gestiona la UI y la interacción del usuario.
   - `ModulationProvider`: Gestiona el estado de la aplicación usando el patrón Provider.
   - `ModulationScreen`: Pantalla principal de la aplicación.
   - Widgets especializados: `SignalChart`, `BinaryDisplay`, `ModulationInfoCard`.

4. **Core**: Contiene componentes reutilizables y utilidades.
   - `TextConverter`: Convierte texto a binario y viceversa.
   - `AppTheme`: Define los temas claro y oscuro de la aplicación.
   - `ThemeProvider`: Gestiona el cambio de tema.
   - `LocaleProvider`: Gestiona el cambio de idioma.

## 📊 Técnicas de Modulación

### BPSK (Binary Phase Shift Keying)

- **Descripción**: Modulación por desplazamiento de fase binaria que utiliza 2 estados de fase (0° y 180°) para representar bits 0 y 1.
- **Eficiencia**: 1 bit por símbolo
- **Ventajas**: Simple de implementar, robusta contra el ruido, menor tasa de errores
- **Desventajas**: Baja eficiencia espectral

### QPSK (Quadrature Phase Shift Keying)

- **Descripción**: Modulación por desplazamiento de fase en cuadratura que utiliza 4 estados de fase (45°, 135°, 225°, 315°) para representar 2 bits por símbolo.
- **Eficiencia**: 2 bits por símbolo
- **Ventajas**: Mayor eficiencia espectral, misma tasa de error que BPSK para la misma energía por bit
- **Desventajas**: Implementación más compleja, más sensible al ruido de fase

## 🌐 Internacionalización

La aplicación soporta múltiples idiomas utilizando el framework de localización de Flutter:

- Inglés (predeterminado)
- Español

Para agregar nuevos idiomas:

1. Crea un nuevo archivo en la carpeta `lib/l10n/` siguiendo el patrón `app_[código_idioma].arb`
2. Copia y traduce el contenido de `app_en.arb`
3. Regenera los archivos de localización con `flutter gen-l10n`

## 📚 Dependencias principales

- **flutter_localizations**: Soporte para internacionalización
- **provider**: Gestión de estado
- **fl_chart**: Visualización de gráficos para las señales moduladas
- **google_fonts**: Tipografías para mejorar la UI
- **intl**: Soporte para internacionalización

## 🤝 Contribuciones

Las contribuciones son bienvenidas:

1. Haz un fork del repositorio
2. Crea una nueva rama (`git checkout -b feature/amazing-feature`)
3. Haz tus cambios
4. Haz commit de tus cambios (`git commit -m 'Add amazing feature'`)
5. Haz push a la rama (`git push origin feature/amazing-feature`)
6. Abre un Pull Request

## 📝 Licencia

Distribuido bajo la licencia MIT. Consulta `LICENSE` para más información.

## 📞 Contacto

Tu Nombre - [@tuusuario](https://twitter.com/tuusuario) - email@example.com

Enlace del proyecto: [https://github.com/tuusuario/modulearn](https://github.com/tuusuario/modulearn)
