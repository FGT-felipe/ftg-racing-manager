// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FTG Racing Manager';

  @override
  String get loading => 'Loading...';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get name => 'Name';

  @override
  String get description => 'Description';

  @override
  String get paddockTitle => 'PADDOCK';

  @override
  String get garageTitle => 'GARAGE';

  @override
  String get hqTitle => 'HEADQUARTERS';

  @override
  String get standingsTitle => 'STANDINGS';

  @override
  String get newsTitle => 'PRESS NEWS';

  @override
  String get officeTitle => 'OFFICE';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get nextRace => 'NEXT RACE';

  @override
  String get raceDaySundayTime => 'SUNDAY, 14:00 LOCAL';

  @override
  String raceDayRaceTime(Object time) {
    return 'RACE: $time';
  }

  @override
  String get raceDaySunday => 'SUNDAY';

  @override
  String get raceDayLive => 'LIVE';

  @override
  String get raceDayLoadingData => 'Loading race data...';

  @override
  String get raceDayTitle => 'RACE DAY';

  @override
  String get raceDayLap => 'LAP';

  @override
  String get raceDayFastestLap => 'FASTEST LAP';

  @override
  String get raceDayRacePositions => 'RACE POSITIONS';

  @override
  String get raceDayInBoxes => 'IN BOXES';

  @override
  String get raceDayRaceLabel => 'RACE';

  @override
  String get raceDayPitBoard => 'PIT BOARD';

  @override
  String get raceDayCommentary => 'COMMENTARY';

  @override
  String get raceCompletedResults => 'RACE COMPLETED — RESULTS';

  @override
  String get raceFinished => 'FINISHED';

  @override
  String get racePreRace => 'PRE-RACE';

  @override
  String get raceLightsOutSoon => 'LIGHTS OUT SOON';

  @override
  String get noEventsYet => 'No events recorded yet. Stand by for lights out.';

  @override
  String get raceWaitingStart => 'Waiting for race start...';

  @override
  String get retired => 'RETIRED';

  @override
  String get leader => 'LEADER';

  @override
  String get standingsInterval => 'INTERVAL';

  @override
  String get standingsPos => 'POS';

  @override
  String get standingsDriver => 'DRIVER';

  @override
  String get navDrivers => 'DRIVERS';

  @override
  String get navEvents => 'EVENTS';

  @override
  String get garageEvents => 'GARAGE EVENTS';

  @override
  String get waitingForLightsOut => 'Waiting for lights out...';

  @override
  String get commentatorsStandingBy =>
      'Commentators standing by for the start...';

  @override
  String get practiceTab => 'PRACTICE';

  @override
  String get qualifyingTab => 'QUALIFYING';

  @override
  String get raceTab => 'RACE';

  @override
  String get garageRaceSetupSubmitted => 'Race setup submitted ✓';

  @override
  String garageError(String message) {
    return 'Error: $message';
  }

  @override
  String get garageDriverCrashedSessionOver =>
      'This driver has crashed and cannot run again this session.';

  @override
  String get garageDriverCrashedSessionOverDetails =>
      'Repair and medical costs have been applied. This driver cannot run again this qualifying session.';

  @override
  String get garageOutLap => 'OUT LAP...';

  @override
  String get garagePushing => 'PUSHING...';

  @override
  String garageCrashAccident(String name) {
    return 'CRASH! $name HAS HAD AN ACCIDENT!';
  }

  @override
  String get garageCrashedQualifying => 'CRASHED! QUALIFYING OVER';

  @override
  String get garageInLap => 'IN LAP...';

  @override
  String garageImprovedTime(String time, int current, int total) {
    return '✓ $time — New PB! (Attempt $current/$total)';
  }

  @override
  String garageNoImprovement(String time, int current, int total) {
    return '⏱ $time — No improvement (Attempt $current/$total)';
  }

  @override
  String get garageTabPractice => 'PRACTICE';

  @override
  String get garageTabQualifying => 'QUALIFYING';

  @override
  String get garageTabRace => 'RACE';

  @override
  String get garageSelectDriver => 'Select a driver to configure setup';

  @override
  String get garageCircuitIntel => 'CIRCUIT INTEL';

  @override
  String get garageSetupPractice => 'PRACTICE SETUP';

  @override
  String get garageSetupQualifying => 'QUALIFYING SETUP';

  @override
  String get garageSetupRace => 'RACE SETUP';

  @override
  String get garageDriverStyle => 'DRIVER STYLE';

  @override
  String get garageStartSeries => 'START SERIES';

  @override
  String garageRunQualyAttempt(int current, int total) {
    return 'RUN QUALIFYING ATTEMPT ($current/$total)';
  }

  @override
  String get garageParcFermeLabel => 'PARC FERMÉ';

  @override
  String garageParcFerme(int current, int total) {
    return 'PARC FERMÉ: Only front wing and tyres can be changed. (Attempt $current/$total)';
  }

  @override
  String garageQualyAttempts(int current, int total) {
    return 'Attempts: $current/$total';
  }

  @override
  String get garageAllAttemptsUsed => 'ALL ATTEMPTS USED';

  @override
  String get garageMaxQualifyingAttemptsReached =>
      'Max qualifying attempts reached for this session.';

  @override
  String garageBestTime(String time) {
    return 'BEST: $time';
  }

  @override
  String get garageLastLap => 'LAST LAP';

  @override
  String get garagePos => 'POS';

  @override
  String get garageGap => 'GAP';

  @override
  String get garageTyre => 'TYRE';

  @override
  String get garageTime => 'TIME';

  @override
  String get garageLaps => 'LAPS';

  @override
  String get garageLoadingParticipants => 'Loading participants...';

  @override
  String get garageQualySessionOpen => 'QUALIFYING SESSION OPEN';

  @override
  String get garageQualySessionClosed => 'QUALIFYING SESSION CLOSED';

  @override
  String get garageRaceStrategyDesc =>
      'Configure your complete race strategy and driving styles. This setup will be used during the race itself.';

  @override
  String get garageRaceRegulationTyre =>
      'Rule: Hard compound tyres MUST be used at least once during the race.';

  @override
  String get garageSubmitRaceSetup => 'SUBMIT RACE SETUP';

  @override
  String get garageCarConfiguration => 'CAR CONFIGURATION';

  @override
  String get garageRaceStrategy => 'RACE STRATEGY';

  @override
  String get garageRaceStart => 'RACE START';

  @override
  String garagePitStop(int number) {
    return 'STOP $number';
  }

  @override
  String get garageAddPitStop => 'ADD PIT STOP';

  @override
  String garageFitness(int value) {
    return 'FITNESS: $value%';
  }

  @override
  String get garageDnf => 'DNF';

  @override
  String get garageRepairMedicalCosts =>
      'Repair and medical costs have been applied. This driver cannot run again this qualifying session.';

  @override
  String get garageConfidence => 'CONFIDENCE';

  @override
  String get garageRestoreSetup => 'RESTORE THIS SETUP';

  @override
  String get garageSetupRestored => 'Setup restored to current session';

  @override
  String garageLapTimes(String name) {
    return 'LAP TIMES — $name';
  }

  @override
  String get garageNoLapsYet => 'No laps recorded yet';

  @override
  String get garageNoFeedbackYet => 'No feedback gathered yet';

  @override
  String get garageSetQualy => 'SET QUALY';

  @override
  String get garageSetRace => 'SET RACE';

  @override
  String get setupFrontWing => 'Front Wing';

  @override
  String get setupRearWing => 'Rear Wing';

  @override
  String get setupSuspension => 'Suspension';

  @override
  String get setupGearRatio => 'Gear Ratio';

  @override
  String get styleRisky => 'RISKY';

  @override
  String get styleAttack => 'ATTACK';

  @override
  String get styleNormal => 'NORMAL';

  @override
  String get styleConserve => 'CONSERVE';

  @override
  String get tipRisky => 'Most aggressive push — highest risk, highest reward';

  @override
  String get tipAttack => 'Offensive style — push hard for lap time';

  @override
  String get tipNormal => 'Balanced driving — default style';

  @override
  String get tipConserve => 'Defensive / tyre saving style';

  @override
  String get tipRegulationStartTyres =>
      'REGULATION: Start tyres are fixed. Drivers must start on the same compound used for their best qualifying lap.';

  @override
  String get pitBoardMessageInBox => 'IN BOX';

  @override
  String get pitBoardMessageReady => 'READY';

  @override
  String pitBoardNewTeamRecord(String name, String time) {
    return '$name: NEW TEAM RECORD — $time!';
  }

  @override
  String pitBoardNewPB(String name, String time) {
    return '$name: New Personal Best — $time';
  }

  @override
  String pitBoardReturningPits(String name) {
    return '$name is returning to the pits...';
  }

  @override
  String pitBoardInGarage(String name) {
    return '$name is back in the garage.';
  }

  @override
  String pitBoardLeftPits(String name) {
    return '$name IS LEAVING THE PITS';
  }

  @override
  String pitBoardStartingPractice(String name) {
    return '$name IS STARTING PRACTICE SERIES';
  }

  @override
  String pitBoardOnLap(String name, int current, int total) {
    return '$name: LAP $current/$total';
  }

  @override
  String get bestPb => 'BEST PB';

  @override
  String get fastest => 'FASTEST';

  @override
  String get garagePracticeClosedRace =>
      'PRACTICE CLOSED: Race setup has been submitted.';

  @override
  String get garagePracticeClosedQualy =>
      'PRACTICE CLOSED: Qualifying session has started.';

  @override
  String garageQualyIntro(int total) {
    return 'Configure your qualifying setup and run attempts to set the best lap time. Max attempts: $total';
  }

  @override
  String get garageRaceStrategyStintTips =>
      'Optimize fuel load, tyre choices, and driving aggression for each stint.';

  @override
  String get setupTyreCompound => 'Tyre Compound';

  @override
  String get labelFuel => 'FUEL';

  @override
  String get labelDriveStyle => 'DRIVE STYLE';

  @override
  String get labelTyres => 'TYRES';

  @override
  String get labelLaps => 'LAPS';

  @override
  String get labelLapTime => 'LAP TIME';

  @override
  String get labelGap => 'GAP';

  @override
  String get weatherLabel => 'WEATHER';

  @override
  String get trackTempLabel => 'TRACK';

  @override
  String get airTempLabel => 'AIR';

  @override
  String get humidityLabel => 'HUMIDITY';

  @override
  String garageMaxLapsReached(Object max, Object remaining) {
    return 'Driver reached max practice laps ($max). Reducing series to $remaining laps.';
  }

  @override
  String garageCrashAlert(Object name) {
    return 'CRASH! $name HAS HAD AN ACCIDENT!';
  }

  @override
  String garageSeriesCompletedConfidence(Object value) {
    return 'Series completed. Setup confidence: $value%';
  }

  @override
  String get garageQualySetupSavedDraft => 'Qualifying setup saved (Draft)';

  @override
  String get garageRaceSetupSavedDraft => 'Race setup draft saved.';

  @override
  String get garageDriver => 'DRIVER';

  @override
  String get garageConstructor => 'CONSTRUCTOR';

  @override
  String get garageLapsIntel => 'LAPS';

  @override
  String get garageTyresIntel => 'TYRES';

  @override
  String get garageWeatherIntel => 'WEATHER';

  @override
  String get garageEngineIntel => 'ENGINE';

  @override
  String get garageFuelIntel => 'FUEL';

  @override
  String get garageAeroIntel => 'AERO';

  @override
  String get garageWeatherSunny => 'SUNNY';

  @override
  String get garageWeatherExtremeHigh => 'EXTREME';

  @override
  String get garageWeatherExtremeLow => 'EXTREME LOW';

  @override
  String get garageImportant => 'IMPORTANT';

  @override
  String get garageCrucial => 'CRUCIAL';

  @override
  String get garageCritical => 'CRITICAL';

  @override
  String get garageVeryHigh => 'VERY HIGH';

  @override
  String get garageMaximum => 'MAXIMUM';

  @override
  String get garageFocus => 'FOCUS';

  @override
  String get garageQualifyingResults => 'QUALIFYING RESULTS';

  @override
  String get garageLocked => 'LOCKED';

  @override
  String get garageLowPriority => 'LOW PRIORITY';

  @override
  String garageLapsCount(int current, int total) {
    return 'Attempts: $current/$total';
  }

  @override
  String garageLapsCountShort(int count) {
    return 'Laps: $count';
  }

  @override
  String get garageDnfSessionOver => 'DNF — SESSION OVER';

  @override
  String get garageBestPersonal => 'PERSONAL BEST';

  @override
  String garageBestLapTimeShort(String time) {
    return 'PB: $time';
  }

  @override
  String garageLapSetup(String time) {
    return 'LAP SETUP — $time';
  }

  @override
  String get garageClose => 'CLOSE';

  @override
  String get garagePitStopStrategyTooltip =>
      'Plan your pit strategy and tyre compounds.';

  @override
  String get garageParcFermeLockedTooltip =>
      'Parc Fermé: This setting cannot be changed.';

  @override
  String get garageConfidenceShort => 'CONF.';

  @override
  String get garagePitBoard => 'PIT BOARD';

  @override
  String get garageReady => 'READY';

  @override
  String get garageDriverFeedback => 'DRIVER FEEDBACK';

  @override
  String get garageNoLapsRecordedYet => 'No laps recorded yet';

  @override
  String get garageRaceStartTyreRegulation =>
      'Regulation: Must start on best qualifying tyres.';

  @override
  String garageLapsIntelShort(Object count) {
    return '$count LAPS';
  }

  @override
  String get garageNoFeedbackGatheredYet => 'No feedback gathered yet';

  @override
  String garageFitnessPercentage(int percent) {
    return 'FITNESS: $percent%';
  }
}
