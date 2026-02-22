// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FTG Racing Manager';

  @override
  String get loading => 'Cargando...';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Añadir';

  @override
  String get name => 'Nombre';

  @override
  String get description => 'Descripción';

  @override
  String get paddockTitle => 'PADDOCK';

  @override
  String get garageTitle => 'GARAJE';

  @override
  String get hqTitle => 'SEDE';

  @override
  String get standingsTitle => 'CLASIFICACIÓN';

  @override
  String get newsTitle => 'PRENSA';

  @override
  String get officeTitle => 'OFICINA';

  @override
  String get settingsTitle => 'AJUSTES';

  @override
  String get nextRace => 'PRÓXIMA CARRERA';

  @override
  String get raceDaySundayTime => 'DOMINGO, 14:00 LOCAL';

  @override
  String raceDayRaceTime(Object time) {
    return 'CARRERA: $time';
  }

  @override
  String get raceDaySunday => 'DOMINGO';

  @override
  String get raceDayLive => 'EN VIVO';

  @override
  String get raceDayLoadingData => 'Cargando datos de carrera...';

  @override
  String get raceDayTitle => 'DÍA DE CARRERA';

  @override
  String get raceDayLap => 'VUELTA';

  @override
  String get raceDayFastestLap => 'VUELTA RÁPIDA';

  @override
  String get raceDayRacePositions => 'POSICIONES DE CARRERA';

  @override
  String get raceDayInBoxes => 'EN BOXES';

  @override
  String get raceDayRaceLabel => 'CARRERA';

  @override
  String get raceDayPitBoard => 'PIZARRA';

  @override
  String get raceDayCommentary => 'COMENTARIOS';

  @override
  String get raceCompletedResults => 'CARRERA COMPLETADA — RESULTADOS';

  @override
  String get raceFinished => 'FINALIZADA';

  @override
  String get racePreRace => 'PRE-CARRERA';

  @override
  String get raceLightsOutSoon => 'SEMÁFOROS PRONTO';

  @override
  String get noEventsYet => 'Sin eventos aún. Esperando semáforos.';

  @override
  String get raceWaitingStart => 'Esperando inicio...';

  @override
  String get retired => 'RETIRADO';

  @override
  String get leader => 'LÍDER';

  @override
  String get standingsInterval => 'INTERVALO';

  @override
  String get standingsPos => 'POS';

  @override
  String get standingsDriver => 'PILOTO';

  @override
  String get navDrivers => 'PILOTOS';

  @override
  String get navEvents => 'EVENTOS';

  @override
  String get garageEvents => 'EVENTOS DE GARAJE';

  @override
  String get waitingForLightsOut => 'Esperando el apagado de luces...';

  @override
  String get commentatorsStandingBy => 'Comentaristas esperando el inicio...';

  @override
  String get practiceTab => 'PRÁCTICA';

  @override
  String get qualifyingTab => 'CLASIFICACIÓN';

  @override
  String get raceTab => 'CARRERA';

  @override
  String get garageRaceSetupSubmitted => 'Configuración enviada ✓';

  @override
  String garageError(String message) {
    return 'Error: $message';
  }

  @override
  String get garageDriverCrashedSessionOver =>
      'Este piloto se ha accidentado y no puede volver a salir esta sesión.';

  @override
  String get garageDriverCrashedSessionOverDetails =>
      'Se han aplicado costes médicos y de reparación. El piloto no puede volver a salir esta sesión.';

  @override
  String get garageOutLap => 'VUELTA DE SALIDA...';

  @override
  String get garagePushing => 'EMPUJANDO...';

  @override
  String garageCrashAccident(String name) {
    return '¡CHOQUE! ¡$name HA TENIDO UN ACCIDENTE!';
  }

  @override
  String get garageCrashedQualifying => '¡ACCIDENTADO! CLASIFICACIÓN TERMINADA';

  @override
  String get garageInLap => 'VUELTA DE ENTRADA...';

  @override
  String garageImprovedTime(String time, int current, int total) {
    return '✓ $time — ¡Nuevo mejor tiempo! (Intento $current/$total)';
  }

  @override
  String garageNoImprovement(String time, int current, int total) {
    return '⏱ $time — Sin mejora (Intento $current/$total)';
  }

  @override
  String get garageTabPractice => 'PRÁCTICA';

  @override
  String get garageTabQualifying => 'CLASIFICACIÓN';

  @override
  String get garageTabRace => 'CARRERA';

  @override
  String get garageSelectDriver => 'Selecciona un piloto para configurar';

  @override
  String get garageCircuitIntel => 'INTEL DEL CIRCUITO';

  @override
  String get garageSetupPractice => 'CONFIGURACIÓN DE PRÁCTICA';

  @override
  String get garageSetupQualifying => 'CONFIGURACIÓN DE CLASIFICACIÓN';

  @override
  String get garageSetupRace => 'CONFIGURACIÓN DE CARRERA';

  @override
  String get garageDriverStyle => 'ESTILO DE CONDUCCIÓN';

  @override
  String get garageStartSeries => 'COMENZAR SERIE';

  @override
  String garageRunQualyAttempt(int current, int total) {
    return 'CORRER INTENTO DE CLASIF. ($current/$total)';
  }

  @override
  String get garageParcFermeLabel => 'PARC FERMÉ';

  @override
  String garageParcFerme(int current, int total) {
    return 'PARC FERMÉ: Solo alerón delantero y neumáticos pueden cambiarse. (Intento $current/$total)';
  }

  @override
  String garageQualyAttempts(int current, int total) {
    return 'Intentos: $current/$total';
  }

  @override
  String get garageAllAttemptsUsed => 'TODOS LOS INTENTOS USADOS';

  @override
  String get garageMaxQualifyingAttemptsReached =>
      'Límite de intentos de clasificación alcanzado.';

  @override
  String garageBestTime(String time) {
    return 'MEJOR: $time';
  }

  @override
  String get garageLastLap => 'ÚLT. VUELTA';

  @override
  String get garagePos => 'POS';

  @override
  String get garageGap => 'GAP';

  @override
  String get garageTyre => 'NEUM.';

  @override
  String get garageTime => 'TIEMPO';

  @override
  String get garageLaps => 'VUELTAS';

  @override
  String get garageLoadingParticipants => 'Cargando participantes...';

  @override
  String get garageQualySessionOpen => 'SESIÓN DE CLASIFICACIÓN ABIERTA';

  @override
  String get garageQualySessionClosed => 'SESIÓN DE CLASIFICACIÓN CERRADA';

  @override
  String get garageRaceStrategyDesc =>
      'Configura tu estrategia completa y estilos de conducción. Esta configuración se usará en carrera.';

  @override
  String get garageRaceRegulationTyre =>
      'Regla: Los neumáticos DUROS DEBEN usarse al menos una vez.';

  @override
  String get garageSubmitRaceSetup => 'ENVIAR CONFIG. DE CARRERA';

  @override
  String get garageCarConfiguration => 'CONFIGURACIÓN DEL COCHE';

  @override
  String get garageRaceStrategy => 'ESTRATEGIA DE CARRERA';

  @override
  String get garageRaceStart => 'SALIDA DE CARRERA';

  @override
  String garagePitStop(int number) {
    return 'PARADA $number';
  }

  @override
  String get garageAddPitStop => 'AÑADIR PARADA EN BOXES';

  @override
  String garageFitness(int value) {
    return 'FORMA FÍSICA: $value%';
  }

  @override
  String get garageDnf => 'DNF';

  @override
  String get garageRepairMedicalCosts =>
      'Se han aplicado costes médicos y de reparación. El piloto no puede volver a salir esta sesión.';

  @override
  String get garageConfidence => 'CONFIANZA';

  @override
  String get garageRestoreSetup => 'RESTAURAR ESTA CONFIGURACIÓN';

  @override
  String get garageSetupRestored =>
      'Configuración restaurada para la sesión actual';

  @override
  String garageLapTimes(String name) {
    return 'TIEMPOS DE VUELTA — $name';
  }

  @override
  String get garageNoLapsYet => 'Sin vueltas registradas aún';

  @override
  String get garageNoFeedbackYet => 'Sin retroalimentación aún';

  @override
  String get garageSetQualy => 'SET CLASIF.';

  @override
  String get garageSetRace => 'SET CARRERA';

  @override
  String get setupFrontWing => 'Alerón Del.';

  @override
  String get setupRearWing => 'Alerón Tras.';

  @override
  String get setupSuspension => 'Suspensión';

  @override
  String get setupGearRatio => 'Relación Marchas';

  @override
  String get styleRisky => 'RIESGO';

  @override
  String get styleAttack => 'ATAQUE';

  @override
  String get styleNormal => 'NORMAL';

  @override
  String get styleConserve => 'CONSERVAR';

  @override
  String get tipRisky => 'Empuje agresivo — mayor riesgo, mayor recompensa';

  @override
  String get tipAttack => 'Estilo ofensivo — busca el mejor tiempo';

  @override
  String get tipNormal => 'Conducción equilibrada — estilo por defecto';

  @override
  String get tipConserve => 'Estilo defensivo / ahorro de neumáticos';

  @override
  String get tipRegulationStartTyres =>
      'REGLAMENTO: Los neumáticos de salida son fijos. Deben ser los mismos del mejor tiempo en clasificación.';

  @override
  String get pitBoardMessageInBox => 'EN BOX';

  @override
  String get pitBoardMessageReady => 'LISTO';

  @override
  String pitBoardNewTeamRecord(String name, String time) {
    return '¡$name: RÉCORD DEL EQUIPO — $time!';
  }

  @override
  String pitBoardNewPB(String name, String time) {
    return '$name: Mejor Personal — $time';
  }

  @override
  String pitBoardReturningPits(String name) {
    return '$name regresando a boxes...';
  }

  @override
  String pitBoardInGarage(String name) {
    return '$name en el garaje.';
  }

  @override
  String pitBoardLeftPits(String name) {
    return '$name SALIENDO DE BOXES';
  }

  @override
  String pitBoardStartingPractice(String name) {
    return '$name COMENZANDO SERIE DE PRÁCTICA';
  }

  @override
  String pitBoardOnLap(String name, int current, int total) {
    return '$name: VUELTA $current/$total';
  }

  @override
  String get bestPb => 'MEJOR RP';

  @override
  String get fastest => 'EL MÁS RÁPIDO';

  @override
  String get garagePracticeClosedRace =>
      'PRÁCTICA CERRADA: La configuración de carrera ha sido enviada.';

  @override
  String get garagePracticeClosedQualy =>
      'PRÁCTICA CERRADA: La sesión de clasificación ha comenzado.';

  @override
  String garageQualyIntro(int total) {
    return 'Configura tu monoplaza para clasificación y realiza intentos para marcar el mejor tiempo. Intentos máx: $total';
  }

  @override
  String get garageRaceStrategyStintTips =>
      'Optimiza la carga de combustible, los neumáticos y la agresividad para cada stint.';

  @override
  String get setupTyreCompound => 'Compuesto de Neumático';

  @override
  String get labelFuel => 'COMBUSTIBLE';

  @override
  String get labelDriveStyle => 'ESTILO';

  @override
  String get labelTyres => 'NEUMÁTICOS';

  @override
  String get labelLaps => 'VUELTAS';

  @override
  String get labelLapTime => 'TIEMPO VUELTA';

  @override
  String get labelGap => 'DIFERENCIA';

  @override
  String get weatherLabel => 'CLIMA';

  @override
  String get trackTempLabel => 'PISTA';

  @override
  String get airTempLabel => 'AIRE';

  @override
  String get humidityLabel => 'HUMEDAD';

  @override
  String garageMaxLapsReached(Object max, Object remaining) {
    return 'El piloto alcanzó el máximo de vueltas de práctica ($max). Reduciendo la serie a $remaining vueltas.';
  }

  @override
  String garageCrashAlert(Object name) {
    return '¡CHOQUE! ¡$name HA TENIDO UN ACCIDENTE!';
  }

  @override
  String garageSeriesCompletedConfidence(Object value) {
    return 'Serie completada. Confianza en la configuración: $value%';
  }

  @override
  String get garageQualySetupSavedDraft =>
      'Configuración de clasificación guardada (Borrador)';

  @override
  String get garageRaceSetupSavedDraft =>
      'Borrador de config. de carrera guardado.';

  @override
  String get garageDriver => 'PILOTO';

  @override
  String get garageConstructor => 'CONSTRUCTOR';

  @override
  String get garageLapsIntel => 'VUELTAS';

  @override
  String get garageTyresIntel => 'NEUMÁTICOS';

  @override
  String get garageWeatherIntel => 'CLIMA';

  @override
  String get garageEngineIntel => 'MOTOR';

  @override
  String get garageFuelIntel => 'COMBUSTIBLE';

  @override
  String get garageAeroIntel => 'AERO';

  @override
  String get garageWeatherSunny => 'SOLEADO';

  @override
  String get garageWeatherExtremeHigh => 'EXTREMO';

  @override
  String get garageWeatherExtremeLow => 'EXTREMO BAJO';

  @override
  String get garageImportant => 'IMPORTANTE';

  @override
  String get garageCrucial => 'CRUCIAL';

  @override
  String get garageCritical => 'CRÍTICO';

  @override
  String get garageVeryHigh => 'MUY ALTO';

  @override
  String get garageMaximum => 'MÁXIMO';

  @override
  String get garageFocus => 'ENFOQUE';

  @override
  String get garageQualifyingResults => 'RESULTADOS DE CLASIFICACIÓN';

  @override
  String get garageLocked => 'BLOQUEADO';

  @override
  String get garageLowPriority => 'PRIORIDAD BAJA';

  @override
  String garageLapsCount(int current, int total) {
    return 'Intentos: $current/$total';
  }

  @override
  String garageLapsCountShort(int count) {
    return 'Vueltas: $count';
  }

  @override
  String get garageDnfSessionOver => 'DNF — SESIÓN TERMINADA';

  @override
  String get garageBestPersonal => 'MEJOR PERSONAL';

  @override
  String garageBestLapTimeShort(String time) {
    return 'PB: $time';
  }

  @override
  String garageLapSetup(String time) {
    return 'CONFIG. VUELTA — $time';
  }

  @override
  String get garageClose => 'CERRAR';

  @override
  String get garagePitStopStrategyTooltip =>
      'Planifica tu estrategia de paradas y compuestos de neumáticos.';

  @override
  String get garageParcFermeLockedTooltip =>
      'Parc Fermé: Este ajuste no se puede cambiar.';

  @override
  String get garageConfidenceShort => 'CONF.';

  @override
  String get garagePitBoard => 'PIT BOARD';

  @override
  String get garageReady => 'LISTO';

  @override
  String get garageDriverFeedback => 'FEEDBACK DEL PILOTO';

  @override
  String get garageNoLapsRecordedYet => 'Sin vueltas registradas aún';

  @override
  String get garageRaceStartTyreRegulation =>
      'Regla: Debe salir con el neumático de su mejor tiempo en clasif.';

  @override
  String garageLapsIntelShort(Object count) {
    return '$count VUELTAS';
  }

  @override
  String get garageNoFeedbackGatheredYet => 'Sin feedback recolectado aún';

  @override
  String garageFitnessPercentage(int percent) {
    return 'ESTADO: $percent%';
  }
}
