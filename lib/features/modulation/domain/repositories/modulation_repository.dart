import 'package:modulearn/features/modulation/domain/entities/modulated_signal.dart';
import 'package:modulearn/features/modulation/domain/entities/modulation_type.dart';

abstract class ModulationRepository {
  ModulatedSignal generateModulatedSignal({
    required String text,
    required ModulationType modulationType,
  });

  ModulatedSignal generateStepByStepModulatedSignal({
    required String text,
    required ModulationType modulationType,
    required int currentStep,
  });
}
