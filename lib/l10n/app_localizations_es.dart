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
  String get save => 'GUARDAR';

  @override
  String get cancel => 'CANCELAR';

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

  @override
  String get facTeamOffice => 'Oficina del Equipo';

  @override
  String get facGarage => 'Garaje';

  @override
  String get facYouthAcademy => 'Academia Junior';

  @override
  String get facPressRoom => 'Sala de Prensa';

  @override
  String get facScoutingOffice => 'Scouting';

  @override
  String get facRacingSimulator => 'Simulador';

  @override
  String get facGym => 'Gimnasio';

  @override
  String get facRDOffice => 'I+D';

  @override
  String get descTeamOffice => 'Gestión administrativa y contratos.';

  @override
  String get descGarage => 'Mantenimiento y puesta a punto del monoplaza.';

  @override
  String get descYouthAcademy => 'Formación de nuevos talentos para el futuro.';

  @override
  String get descPressRoom => 'Gestión de medios y relaciones públicas.';

  @override
  String get descScoutingOffice => 'Búsqueda de talento global en la parrilla.';

  @override
  String get descRacingSimulator =>
      'Entrenamiento de precisión en entorno virtual.';

  @override
  String get descGym => 'Preparación física y resistencia de los pilotos.';

  @override
  String get descRDOffice => 'Innovación y desarrollo tecnológico constante.';

  @override
  String get notPurchased => 'No Comprado';

  @override
  String bonusBudget(String arg0) {
    return 'Bono de Presupuesto: $arg0';
  }

  @override
  String bonusRepair(String arg0) {
    return 'Bono de Reparación: $arg0';
  }

  @override
  String bonusScouting(String arg0) {
    return 'Bono de Scouting: $arg0';
  }

  @override
  String get bonusTBD => 'Bono por definir';

  @override
  String get accountSettingsTitle => 'Ajustes de Cuenta';

  @override
  String get userProfileTitle => 'PERFIL DE USUARIO';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get emailLabel => 'Correo';

  @override
  String get registeredLabel => 'Registrado';

  @override
  String get userDataNotFound => 'Datos de usuario no encontrados';

  @override
  String get managerProfileTitle => 'PERFIL DE MANAGER';

  @override
  String get managerNameLabel => 'Nombre del Manager';

  @override
  String get roleLabel => 'Rol';

  @override
  String get countryLabel => 'País';

  @override
  String get noManagerProfile => 'Sin Perfil de Manager';

  @override
  String get logOutBtn => 'Cerrar Sesión';

  @override
  String googleAuthError(String arg0) {
    return 'Error al conectar con Google: $arg0';
  }

  @override
  String authError(String arg0) {
    return 'Error de acceso: $arg0';
  }

  @override
  String get emailAlreadyRegistered => 'Este correo ya está registrado';

  @override
  String unexpectedError(String arg0) {
    return 'Error inesperado: $arg0';
  }

  @override
  String get formulaTrackGlory => 'Formula Track Glory';

  @override
  String get ftgSlogan => 'Domina la pista';

  @override
  String get alreadyHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get newManagerJoin => 'Súmate como Manager';

  @override
  String get versionFooter => 'V3.0.0 - Fire Tower Games Studio';

  @override
  String get continueWithGoogle => 'Seguir con Google';

  @override
  String get orUseEmail => 'O usar email';

  @override
  String get firstNameLabel => 'Nombre';

  @override
  String get lastNameLabel => 'Apellidos';

  @override
  String get emailAddressLabel => 'Correo Electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get createAccountBtn => 'Crear Cuenta';

  @override
  String get signInBtn => 'Entrar';

  @override
  String get calendarNoEvents => 'No hay eventos en el calendario actual.';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get lapsIntel => 'Vueltas';

  @override
  String get calendarStatusScheduled => 'Programado';

  @override
  String get driversManagementTitle => 'Gestión de Pilotos';

  @override
  String get errorLoadingDrivers => 'Error al cargar pilotos';

  @override
  String get noDriversFound => 'No se encontraron pilotos';

  @override
  String renewingContractSimulated(String arg0) {
    return 'Renovando contrato de $arg0...';
  }

  @override
  String firingDriverSimulated(String arg0) {
    return 'Despidiendo a $arg0...';
  }

  @override
  String ageLabel(int arg0) {
    return 'Edad: $arg0';
  }

  @override
  String get contractDetailsTitle => 'Detalles del Contrato';

  @override
  String get contractStatusLabel => 'Estado del Contrato';

  @override
  String get salaryPerRaceLabel => 'Salario por Carrera';

  @override
  String get terminationLabel => 'Cláusula de Rescisión';

  @override
  String get remainingLabel => 'Restante';

  @override
  String seasonsRemaining(String arg0) {
    return 'Temporadas restantes: $arg0';
  }

  @override
  String get moraleLabel => 'Moral';

  @override
  String get marketabilityLabel => 'Valor Comercial';

  @override
  String get fireBtn => 'DESPEDIR';

  @override
  String get renewContractBtn => 'RENOVAR';

  @override
  String get driverStatsSectionTitle => 'Estadísticas del Piloto';

  @override
  String get careerStatsTitle => 'Estadísticas de Carrera';

  @override
  String get titlesStat => 'Títulos';

  @override
  String get winsStat => 'Victorias';

  @override
  String get podiumsStat => 'Podios';

  @override
  String get racesStat => 'Carreras';

  @override
  String get championshipFormTitle => 'Estado del Campeonato';

  @override
  String get standingsBtn => 'VER TABLA';

  @override
  String get posLabel => 'Pos';

  @override
  String get eventHeader => 'Evento';

  @override
  String get qHeader => 'Clas.';

  @override
  String get rHeader => 'Car.';

  @override
  String get pHeader => 'Pos.';

  @override
  String get careerHistoryTitle => 'Historial de Carrera';

  @override
  String get yearHeader => 'Año';

  @override
  String get teamHeader => 'Equipo';

  @override
  String get seriesHeader => 'Serie';

  @override
  String get wHeader => 'Vic.';

  @override
  String get historyIndividual => 'Individual';

  @override
  String get noDataAvailableYet => 'Sin datos disponibles aún';

  @override
  String get historyLowerDivision => 'División Inferior';

  @override
  String get historyChampionBadge => 'CAMPEÓN';

  @override
  String get statBraking => 'Frenada';

  @override
  String get statCornering => 'Curvas';

  @override
  String get statSmoothness => 'Suavidad';

  @override
  String get statOvertaking => 'Adelantamiento';

  @override
  String get statConsistency => 'Consistencia';

  @override
  String get statAdaptability => 'Adaptabilidad';

  @override
  String get statFitness => 'Física';

  @override
  String get statFeedback => 'Feedback';

  @override
  String get statFocus => 'Enfoque';

  @override
  String get statMorale => 'Moral';

  @override
  String get statMarketability => 'Comercial';

  @override
  String get roleMain => 'Primer Piloto';

  @override
  String get roleSecond => 'Segundo Piloto';

  @override
  String get roleEqual => 'Estatus Igualitario';

  @override
  String get roleReserve => 'Piloto de Reserva';

  @override
  String get engineeringDescription =>
      'Desarrollo técnico y mejoras del monoplaza.';

  @override
  String get budgetLabel => 'PRESUPUESTO';

  @override
  String get currencySymbol => '\$';

  @override
  String get millionsSuffix => 'M';

  @override
  String get upgradeLimitReached => 'Límite de mejoras alcanzado esta semana.';

  @override
  String get carLabelA => 'Coche A';

  @override
  String get noDriverAssigned => 'Sin piloto asignado';

  @override
  String get carLabelB => 'Coche B';

  @override
  String carPerformanceTitle(String arg0) {
    return 'Rendimiento del Coche: $arg0';
  }

  @override
  String get aero => 'Aerodinámica';

  @override
  String get engine => 'Motor';

  @override
  String get chassisPart => 'Chasis';

  @override
  String get reliability => 'Fiabilidad';

  @override
  String costLabel(String arg0, String arg1) {
    return 'Costo: $arg0 $arg1';
  }

  @override
  String get upgradeBtn => 'MEJORAR';

  @override
  String managerError(String arg0) {
    return 'Error de gestión: $arg0';
  }

  @override
  String get managerProfileNotFound => 'Perfil de manager no encontrado';

  @override
  String teamError(String arg0) {
    return 'Error de equipo: $arg0';
  }

  @override
  String get teamDataNotFound => 'Datos de equipo no encontrados';

  @override
  String seasonError(String arg0) {
    return 'Error de temporada: $arg0';
  }

  @override
  String get quickView => 'Vista Rápida';

  @override
  String get pressNewsTitle => 'NOTICIAS DE PRENSA';

  @override
  String get errorLoadingNews => 'Error al cargar noticias';

  @override
  String get officeNewsTitle => 'NOTICIAS DE OFICINA';

  @override
  String get notificationsUnavailable => 'Notificaciones no disponibles';

  @override
  String get noNewNotifications => 'No hay notificaciones nuevas';

  @override
  String get noNewsFromPaddockYet => 'Aún no hay noticias del paddock';

  @override
  String welcomeBackManager(String arg0) {
    return 'Bienvenido de nuevo, Manager $arg0';
  }

  @override
  String get sessionInProgress => 'Sesión en curso';

  @override
  String get timeUntilNextSession => 'Próxima sesión en';

  @override
  String get teamBudget => 'Presupuesto del Equipo';

  @override
  String get deficit => 'Déficit';

  @override
  String get surplus => 'Superávit';

  @override
  String get estimatedAbbr => 'Est.';

  @override
  String get nextGrandPrix => 'Próximo Gran Premio';

  @override
  String circuitLengthAndLaps(String arg0, String arg1) {
    return 'Distancia: $arg0 km | Vueltas: $arg1';
  }

  @override
  String get paddockOpen => 'Paddock Abierto';

  @override
  String get weekendSetupBtn => 'Ajustes de Fin de Semana';

  @override
  String get qualifyingStatus => 'Clasificación en Curso';

  @override
  String get viewQualifyingBtn => 'Ver Clasificación';

  @override
  String get raceStrategyStatus => 'Estrategia de Carrera';

  @override
  String get setRaceStrategyBtn => 'Fijar Estrategia';

  @override
  String get raceWeekendStatus => 'Carrera en Curso';

  @override
  String get goToRaceBtn => 'Ir a Carrera';

  @override
  String get raceFinishedStatus => 'Carrera Finalizada';

  @override
  String get viewResultsBtn => 'Ver Resultados';

  @override
  String get circuitIntelTitle => 'Información del Circuito';

  @override
  String get aeroIntel => 'Aero';

  @override
  String get highIntel => 'Alto';

  @override
  String get powerIntel => 'Potencia';

  @override
  String get speedIntel => 'Velocidad';

  @override
  String get tyreIntel => 'Neumáticos';

  @override
  String get onLive => 'En Vivo';

  @override
  String get offLive => 'Fuera de Línea';

  @override
  String get preRaceChecklist => 'Lista de Preparación';

  @override
  String get practiceProgram => 'Programa de Prácticas';

  @override
  String completedLapsOf(String arg0, String arg1) {
    return 'Vueltas: $arg0 de $arg1';
  }

  @override
  String get qualifyingSetup => 'Configuración de Clasificación';

  @override
  String get readyStatus => 'Listo';

  @override
  String get pendingStatus => 'Pendiente';

  @override
  String get hqDescription =>
      'Gestiona las instalaciones y el desarrollo de tu equipo.';

  @override
  String get facilitiesSectionTitle => 'Instalaciones';

  @override
  String levelLabel(String arg0) {
    return 'Nivel: $arg0';
  }

  @override
  String get nextLevelLabel => 'Siguiente Nivel';

  @override
  String get maintCostLabel => 'Costo Manto.';

  @override
  String get bonusLabel => 'Bonificación';

  @override
  String get buyBtn => 'COMPRAR';

  @override
  String get comingSoonBanner => 'PRÓXIMAMENTE';

  @override
  String facilityImproved(String arg0) {
    return '¡Instalación mejorada a nivel $arg0!';
  }

  @override
  String get signContractError => 'Error al firmar contrato';

  @override
  String get confirmResetWorldTitle => '¿Reiniciar el Mundo?';

  @override
  String get confirmResetWorldDesc =>
      'Esta acción borrará todo el progreso actual. Es irreversible.';

  @override
  String get cancelBtn => 'CANCELAR';

  @override
  String get resetSuccess => '¡Mundo reiniciado con éxito!';

  @override
  String get resetBtn => 'REINICIAR';

  @override
  String get jobMarketTitle => 'Mercado Laboral';

  @override
  String get availableLabel => 'Disponible';

  @override
  String get signContract => 'Firmar Contrato';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navHQ => 'Sede';

  @override
  String get navTeamOffice => 'Oficina';

  @override
  String get navGarage => 'Garaje';

  @override
  String get navYouthAcademy => 'Filial Junior';

  @override
  String get navRacing => 'Competición';

  @override
  String get navWeekendSetup => 'Ajustes de GP';

  @override
  String get navRaceDay => 'DÍA DE CARRERA';

  @override
  String get navManagement => 'Gestión';

  @override
  String get navPersonal => 'Plataforma';

  @override
  String get navFinances => 'Finanzas';

  @override
  String get navSponsors => 'Patrocinadores';

  @override
  String get navSeason => 'Temporada';

  @override
  String get navStandings => 'Clasificación';

  @override
  String get navCalendar => 'Calendario';

  @override
  String get accountInfo => 'INFO. DE CUENTA';

  @override
  String get notAvailable => 'NO DISPONIBLE';

  @override
  String get lastSession => 'Última Sesión';

  @override
  String get adminBtn => 'ADMIN';

  @override
  String get accountBtn => 'CUENTA';

  @override
  String get logOutConfirmTitle => 'Confirmar Cierre de Sesión';

  @override
  String get logOutConfirmDesc =>
      '¿Estás seguro de que deseas cerrar la sesión?';

  @override
  String get navMarket => 'Mercado';

  @override
  String get personalManagement => 'Gestión de Personal';

  @override
  String get driversTitle => 'Pilotos';

  @override
  String get fitnessTrainerTitle => 'Entrenador Físico';

  @override
  String get chiefEngineerTitle => 'Ingeniero Jefe';

  @override
  String get hrManagerTitle => 'Director de RRHH';

  @override
  String get marketingManagerTitle => 'Director de Marketing';

  @override
  String get currentBalanceTitle => 'Saldo Actual';

  @override
  String get recentMovementsTitle => 'Movimientos Recientes';

  @override
  String get noFinancialActivity => 'Sin actividad financiera reciente.';

  @override
  String get selectCarPartToManage => 'Selecciona la pieza a gestionar';

  @override
  String activeContractTitle(String arg0) {
    return 'CONTRATO ACTIVO: $arg0';
  }

  @override
  String get weeklyPayLabel => 'Pago Semanal';

  @override
  String get racesLeftLabel => 'Carreras Restantes';

  @override
  String availableOffersTitle(String arg0) {
    return 'OFERTAS: $arg0';
  }

  @override
  String get rearWingPart => 'Alerón Trasero';

  @override
  String get sidepodLPart => 'Pontón Izquierdo';

  @override
  String get sidepodRPart => 'Pontón Derecho';

  @override
  String get haloPart => 'Halo';

  @override
  String get frontWingPart => 'Alerón Delantero';

  @override
  String get nosePart => 'Morro';

  @override
  String get manageBtn => 'GESTIONAR';

  @override
  String get selectSponsorBtn => 'Seleccionar Patrocinador';

  @override
  String get negotiationRulesTitle => 'Reglas de Negociación';

  @override
  String get negotiationRulesDesc =>
      'Establece los términos antes de la firma.';

  @override
  String get signingBonusLabel => 'Bono de Firma';

  @override
  String get weeklyPaymentLabel => 'Pago Semanal';

  @override
  String get durationLabel => 'Duración';

  @override
  String durationRaces(String arg0) {
    return '$arg0 Carreras';
  }

  @override
  String get objectiveLabel => 'Objetivo';

  @override
  String get suspendedStatus => 'Suspendido';

  @override
  String chooseTacticLabel(String arg0) {
    return 'Elige Táctica: $arg0';
  }

  @override
  String get persuasiveTactic => 'Persuasiva';

  @override
  String get negotiatorTactic => 'Negociadora';

  @override
  String get collaborativeTactic => 'Colaborativa';

  @override
  String get availableSponsorsTitle => 'Patrocinadores Disponibles';

  @override
  String get roleExDriverTitle => 'Ex-Piloto';

  @override
  String get roleExDriverDesc => 'Aporta experiencia técnica en pista.';

  @override
  String get roleBusinessTitle => 'Empresario';

  @override
  String get roleBusinessDesc => 'Optimiza ingresos y mercadeo.';

  @override
  String get roleBureaucratTitle => 'Burócrata';

  @override
  String get roleBureaucratDesc => 'Experto en regulaciones y política.';

  @override
  String get roleEngineerTitle => 'Ingeniero';

  @override
  String get roleEngineerDesc => 'Maximiza el desarrollo técnico.';

  @override
  String get createManagerProfile => 'Crear Perfil de Manager';

  @override
  String get personalInfoTitle => 'Información Personal';

  @override
  String get selectCountryError => 'Debes seleccionar un país';

  @override
  String get genderLabel => 'Género';

  @override
  String get maleGender => 'Masculino';

  @override
  String get femaleGender => 'Femenino';

  @override
  String get nonBinaryGender => 'No Binario';

  @override
  String get selectGenderError => 'Debes seleccionar un género';

  @override
  String get dayLabel => 'Día';

  @override
  String get monthLabel => 'Mes';

  @override
  String get yearLabel => 'Año';

  @override
  String get selectBackgroundTitle => 'TRASFONDO DEL MANAGER';

  @override
  String get createManagerDesc =>
      'Personaliza tu perfil y trasfondo profesional.';

  @override
  String get establishCareerBtn => 'ESTABLECER CARRERA';

  @override
  String get requiredError => 'Este campo es obligatorio';

  @override
  String get advantagesTitle => 'VENTAJAS';

  @override
  String get disadvantagesTitle => 'DESVENTAJAS';

  @override
  String get adminAccess => 'ADMINISTRACIÓN';

  @override
  String get enterPin => 'INTRODUCIR PIN';

  @override
  String get verifyBtn => 'VERIFICAR';

  @override
  String get nukeWorldTitle => 'Reinicio Global';

  @override
  String get nukeWorldDesc =>
      'Elimina todos los datos de la liga y los managers. Esta acción es definitiva.';

  @override
  String get nukeWorldSuccess => '¡Base de datos reiniciada!';

  @override
  String errorPrefix(String arg0) {
    return 'Error: $arg0';
  }

  @override
  String get executeNuke => 'Ejecutar Reinicio';

  @override
  String get ftgRacing => 'FTG Racing';

  @override
  String get manager2026 => 'MANAGER 2026';

  @override
  String get signInWithGoogle => 'Entrar con Google';

  @override
  String get signInWithEmail => 'Entrar con Email';

  @override
  String get devQuickStart => 'Inicio Rápido (Dev)';

  @override
  String signingWithTeam(String arg0) {
    return 'Tramitando contrato con $arg0...';
  }

  @override
  String applicationFailed(String arg0) {
    return 'Error en la solicitud: $arg0';
  }

  @override
  String get selectTeamTitle => 'ELECCIÓN DE EQUIPO';

  @override
  String get selectTeamDesc => 'Selecciona la escudería que deseas dirigir.';

  @override
  String get worldChampionship => 'CAMPEONATO MUNDIAL';

  @override
  String get secondSeries => 'SERIE SECUNDARIA';

  @override
  String get noTeamsAvailable => 'No hay equipos disponibles en esta liga.';

  @override
  String get recommendedTag => 'RECOMENDADO';

  @override
  String get unlockLeagueDesc =>
      'Gana reputación para desbloquear ligas superiores.';

  @override
  String get mainDriverLabel => 'Primer Piloto';

  @override
  String get secondaryDriverLabel => 'Segundo Piloto';

  @override
  String get selectTeamBtn => 'SELECCIONAR EQUIPO';

  @override
  String get selectedTag => 'SELECCIONADO';

  @override
  String get standingsConstructorTitle => ' Constructores';

  @override
  String get raceResults => 'Resultados';

  @override
  String get standingsTeam => 'Escudería';

  @override
  String get standingsPoints => 'Puntos';

  @override
  String get insufficientBudgetForNameChange =>
      'Presupuesto insuficiente para cambio de nombre';

  @override
  String teamRenamedFree(String arg0) {
    return 'Renombrado gratis: $arg0';
  }

  @override
  String teamRenamedPaid(String arg0) {
    return 'Renombrado: $arg0';
  }

  @override
  String get teamIdentityTitle => 'IDENTIDAD VISUAL';

  @override
  String get teamNameLabel => 'Nombre de la Escudería';

  @override
  String get confirmBtn => 'CONFIRMAR';

  @override
  String get regulationsTitle => 'NORMATIVA';

  @override
  String get firstChangeUsed => 'Cambio inicial agotado';

  @override
  String get firstChangeFree => 'Primer cambio sin costo';

  @override
  String get nextChangesCost => 'Siguientes cambios tendrán costo';

  @override
  String renamedTimesLabel(String arg0) {
    return 'Renombrado $arg0 veces';
  }

  @override
  String get teamCareerStatsTitle => 'ESTADÍSTICAS HISTÓRICAS';

  @override
  String get combinedDriversLabel => 'RENDIMIENTO COMBINADO';

  @override
  String get driverBreakdownTitle => 'DETALLE POR PILOTO';

  @override
  String get driverHeader => 'PILOTO';

  @override
  String get teamLiveryTitle => 'COLORES DEL EQUIPO';

  @override
  String get selectYourColors => 'Elige tus colores';

  @override
  String get liveryDescription =>
      'Configura la apariencia de tus monoplazas en pista.';

  @override
  String get managerProfileSectionTitle => 'PERFIL DEL DIRECTOR';

  @override
  String get circuitMexico => 'México';

  @override
  String get circuitInterlagos => 'Interlagos';

  @override
  String get circuitMiami => 'Miami';

  @override
  String get circuitSanPabloStreet => 'San Pablo';

  @override
  String get circuitIndianapolis => 'Indianápolis';

  @override
  String get circuitMontreal => 'Montreal';

  @override
  String get circuitVegas => 'Las Vegas';

  @override
  String get circuitTexas => 'Texas';

  @override
  String get circuitBuenosAires => 'Buenos Aires';

  @override
  String get statusLivingLegend => 'LEYENDA VIVA';

  @override
  String get statusEraDominator => 'DOMINADOR DE LA ERA';

  @override
  String get statusTheHeir => 'EL HEREDERO';

  @override
  String get statusTheHeiress => 'LA HEREDERA';

  @override
  String get statusEliteVeteran => 'VETERANO DE ÉLITE';

  @override
  String get statusLastDance => 'EL ÚLTIMO BAILE';

  @override
  String get statusSolidSpecialist => 'Especialista Sólido';

  @override
  String get statusYoungWonder => 'Joven Maravilla';

  @override
  String get statusRisingStar => 'ESTRELLA EMERGENTE';

  @override
  String get statusStuckPromise => 'PROMESA ESTANCADA';

  @override
  String get statusJourneyman => 'TROTAMUNDOS';

  @override
  String get statusJourneywoman => 'Trotamundos';

  @override
  String get statusUnsungDriver => 'HÉROE ANÓNIMO';

  @override
  String get statusMidfieldSpark => 'CHISPA DE MEDIA TABLA';

  @override
  String get statusPastGlory => 'SOL DE OCASO';

  @override
  String get statusGridFiller => 'RELLENO DE PARRILLA';

  @override
  String get statusUnknown => 'Desconocido';

  @override
  String get descLivingLegend => 'Uno de los mejores de la historia.';

  @override
  String get descEraDominator => 'Domina su época con puño de hierro.';

  @override
  String get descTheHeir => 'Heredero de una dinastía ganadora.';

  @override
  String get descEliteVeteran => 'Años de experiencia al máximo nivel.';

  @override
  String get descLastDance => 'Su última oportunidad para la gloria.';

  @override
  String get descSolidSpecialist => 'Fiable en cualquier circunstancia.';

  @override
  String get descYoungWonder => 'El futuro del automovilismo.';

  @override
  String get descRisingStar => 'Un talento que sube como la espuma.';

  @override
  String get descStuckPromise => 'Mucho talento, pocos resultados.';

  @override
  String get descJourneyman => 'Ha pasado por casi todos los garajes.';

  @override
  String get descUnsungDriver => 'Merece más atención de la prensa.';

  @override
  String get descMidfieldSpark => 'Capaz de milagros en coches medios.';

  @override
  String get descPastGlory => 'Su mejor momento ya pasó.';

  @override
  String get descGridFiller => 'Simplemente está aquí para correr.';

  @override
  String get descUnknown => 'Sin datos biográficos destacados.';

  @override
  String errorLoadingProfile(String arg0) {
    return 'Error al cargar perfil: $arg0';
  }

  @override
  String get powerStatsLabel => 'Potencia';

  @override
  String get aeroStatsLabel => 'Aerodinámica';

  @override
  String get handlingStatsLabel => 'Manejo';

  @override
  String get reliabilityStatsLabel => 'Fiabilidad';

  @override
  String get failedToLoadLiveries => 'Error al cargar diseños';

  @override
  String liveryIndexLabel(String arg0, String arg1) {
    return 'Diseño $arg0 de $arg1';
  }

  @override
  String get loadingPhrase1 => 'Calentando neumáticos...';

  @override
  String get loadingPhrase2 => 'Sincronizando telemetría...';

  @override
  String get loadingPhrase3 => 'Ajustando alerones...';

  @override
  String get loadingPhrase4 => 'Preparando estrategia...';

  @override
  String get loadingPhrase5 => 'Revisando niveles...';

  @override
  String get loadingPhrase6 => 'Conectando con el muro...';

  @override
  String get loadingPhrase7 => 'Optimizando motor...';

  @override
  String get loadingPhrase8 => 'Listos para el semáforo...';

  @override
  String minsAgo(int arg0) {
    return 'Hace $arg0 min';
  }

  @override
  String hoursAgo(int arg0) {
    return 'Hace $arg0 h';
  }

  @override
  String pressNewsManagerJoin(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
    String arg4,
    String arg5,
    String arg6,
  ) {
    return '¡BOMBA! $arg0 se une a $arg1. El manager de $arg2, $arg3, llega desde $arg4 para buscar $arg5 en $arg6.';
  }

  @override
  String get motorsportDaily => 'DIARIO DEL MOTOR';

  @override
  String get readFullArticle => 'Leer artículo completo';

  @override
  String get closeBtn => 'CERRAR';

  @override
  String get navOffice => 'Sede Central';

  @override
  String get objFinishTop3 => 'Terminar en el Top 3';

  @override
  String get objBothInPoints => 'Ambos coches en los puntos';

  @override
  String get objRaceWin => 'Ganar la carrera';

  @override
  String get objFinishTop10 => 'Terminar en el Top 10';

  @override
  String get objFastestLap => 'Vuelta rápida';

  @override
  String get objFinishRace => 'Terminar la carrera';

  @override
  String get objImproveGrid => 'Mejorar posición de parrilla';

  @override
  String get objOvertake3Cars => 'Adelantar 3 coches';
}
