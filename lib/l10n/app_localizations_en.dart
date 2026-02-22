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

  @override
  String get facTeamOffice => 'Team Office';

  @override
  String get facGarage => 'Garage';

  @override
  String get facYouthAcademy => 'Youth Academy';

  @override
  String get facPressRoom => 'Press Room';

  @override
  String get facScoutingOffice => 'Scouting Office';

  @override
  String get facRacingSimulator => 'Racing Simulator';

  @override
  String get facGym => 'Gym';

  @override
  String get facRDOffice => 'R&D Office';

  @override
  String get descTeamOffice => 'Administrative hub and contract management.';

  @override
  String get descGarage => 'Vehicle maintenance and technical tuning.';

  @override
  String get descYouthAcademy => 'Training future talents for the team.';

  @override
  String get descPressRoom => 'Media relations and public image management.';

  @override
  String get descScoutingOffice =>
      'Global talent search for drivers and engineers.';

  @override
  String get descRacingSimulator =>
      'Precision training in a virtual environment.';

  @override
  String get descGym => 'Physical preparation and driver endurance.';

  @override
  String get descRDOffice => 'Constant innovation and technical development.';

  @override
  String get notPurchased => 'Not Purchased';

  @override
  String bonusBudget(String arg0) {
    return 'Bonus Budget $arg0';
  }

  @override
  String bonusRepair(String arg0) {
    return 'Bonus Repair $arg0';
  }

  @override
  String bonusScouting(String arg0) {
    return 'Bonus Scouting $arg0';
  }

  @override
  String get bonusTBD => 'Bonus T B D';

  @override
  String get accountSettingsTitle => 'Account Settings';

  @override
  String get userProfileTitle => 'User Profile';

  @override
  String get nameLabel => 'Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get registeredLabel => 'Registered';

  @override
  String get userDataNotFound => 'User Data Not Found';

  @override
  String get managerProfileTitle => 'Manager Profile';

  @override
  String get managerNameLabel => 'Manager Name';

  @override
  String get roleLabel => 'Role';

  @override
  String get countryLabel => 'Country';

  @override
  String get noManagerProfile => 'No Manager Profile';

  @override
  String get logOutBtn => 'Log Out';

  @override
  String googleAuthError(String arg0) {
    return 'Google Auth Error $arg0';
  }

  @override
  String authError(String arg0) {
    return 'Auth Error $arg0';
  }

  @override
  String get emailAlreadyRegistered => 'Email Already Registered';

  @override
  String unexpectedError(String arg0) {
    return 'Unexpected Error $arg0';
  }

  @override
  String get formulaTrackGlory => 'Formula Track Glory';

  @override
  String get ftgSlogan => 'Ftg Slogan';

  @override
  String get alreadyHaveAccount => 'Already Have Account';

  @override
  String get newManagerJoin => 'New Manager Join';

  @override
  String get versionFooter => 'V3.0.0 - Fire Tower Games Studio';

  @override
  String get continueWithGoogle => 'Continue With Google';

  @override
  String get orUseEmail => 'Or Use Email';

  @override
  String get firstNameLabel => 'First Name';

  @override
  String get lastNameLabel => 'Last Name';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get createAccountBtn => 'Create Account';

  @override
  String get signInBtn => 'Sign In';

  @override
  String get calendarNoEvents => 'Calendar No Events';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get lapsIntel => 'Laps Intel';

  @override
  String get calendarStatusScheduled => 'Calendar Status Scheduled';

  @override
  String get driversManagementTitle => 'Drivers Management';

  @override
  String get errorLoadingDrivers => 'Error Loading Drivers';

  @override
  String get noDriversFound => 'No Drivers Found';

  @override
  String renewingContractSimulated(String arg0) {
    return 'Renewing Contract Simulated $arg0';
  }

  @override
  String firingDriverSimulated(String arg0) {
    return 'Firing Driver Simulated $arg0';
  }

  @override
  String ageLabel(int arg0) {
    return 'Age $arg0';
  }

  @override
  String get contractDetailsTitle => 'Contract Details';

  @override
  String get contractStatusLabel => 'Contract Status';

  @override
  String get salaryPerRaceLabel => 'Salary per Race';

  @override
  String get terminationLabel => 'Termination';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String seasonsRemaining(String arg0) {
    return 'Seasons Remaining: $arg0';
  }

  @override
  String get moraleLabel => 'Morale';

  @override
  String get marketabilityLabel => 'Marketability';

  @override
  String get fireBtn => 'Fire';

  @override
  String get renewContractBtn => 'Renew';

  @override
  String get driverStatsSectionTitle => 'Driver Stats Section';

  @override
  String get careerStatsTitle => 'Career Stats';

  @override
  String get titlesStat => 'Titles';

  @override
  String get winsStat => 'Wins';

  @override
  String get podiumsStat => 'Podiums';

  @override
  String get racesStat => 'Races';

  @override
  String get championshipFormTitle => 'Championship Form';

  @override
  String get standingsBtn => 'Standings';

  @override
  String get posLabel => 'Pos';

  @override
  String get eventHeader => 'Event Header';

  @override
  String get qHeader => 'Q Header';

  @override
  String get rHeader => 'R';

  @override
  String get pHeader => 'P';

  @override
  String get careerHistoryTitle => 'Career History';

  @override
  String get yearHeader => 'Year Header';

  @override
  String get teamHeader => 'Team Header';

  @override
  String get seriesHeader => 'Series Header';

  @override
  String get wHeader => 'W';

  @override
  String get historyIndividual => 'History Individual';

  @override
  String get noDataAvailableYet => 'No Data Available Yet';

  @override
  String get historyLowerDivision => 'History Lower Division';

  @override
  String get historyChampionBadge => 'CHAMPION';

  @override
  String get statBraking => 'Braking';

  @override
  String get statCornering => 'Cornering';

  @override
  String get statSmoothness => 'Smoothness';

  @override
  String get statOvertaking => 'Overtaking';

  @override
  String get statConsistency => 'Consistency';

  @override
  String get statAdaptability => 'Adaptability';

  @override
  String get statFitness => 'Fitness';

  @override
  String get statFeedback => 'Feedback';

  @override
  String get statFocus => 'Focus';

  @override
  String get statMorale => 'Morale';

  @override
  String get statMarketability => 'Marketability';

  @override
  String get roleMain => 'Role Main';

  @override
  String get roleSecond => 'Role Second';

  @override
  String get roleEqual => 'Role Equal';

  @override
  String get roleReserve => 'Role Reserve';

  @override
  String get engineeringDescription => 'Engineering Description';

  @override
  String get budgetLabel => 'Budget';

  @override
  String get currencySymbol => '\$';

  @override
  String get millionsSuffix => 'M';

  @override
  String get upgradeLimitReached => 'Upgrade Limit Reached';

  @override
  String get carLabelA => 'Car Label A';

  @override
  String get noDriverAssigned => 'No Driver Assigned';

  @override
  String get carLabelB => 'Car Label B';

  @override
  String carPerformanceTitle(String arg0) {
    return 'Car Performance Title $arg0';
  }

  @override
  String get aero => 'Aero';

  @override
  String get engine => 'Engine';

  @override
  String get chassisPart => 'Chassis Part';

  @override
  String get reliability => 'Reliability';

  @override
  String costLabel(String arg0, String arg1) {
    return 'Cost Label $arg0 $arg1';
  }

  @override
  String get upgradeBtn => 'Upgrade';

  @override
  String managerError(String arg0) {
    return 'Manager Error $arg0';
  }

  @override
  String get managerProfileNotFound => 'Manager Profile Not Found';

  @override
  String teamError(String arg0) {
    return 'Team Error $arg0';
  }

  @override
  String get teamDataNotFound => 'Team Data Not Found';

  @override
  String seasonError(String arg0) {
    return 'Season Error $arg0';
  }

  @override
  String get quickView => 'Quick View';

  @override
  String get pressNewsTitle => 'PRESS NEWS';

  @override
  String get errorLoadingNews => 'Error Loading News';

  @override
  String get officeNewsTitle => 'OFFICE NEWS';

  @override
  String get notificationsUnavailable => 'Notifications Unavailable';

  @override
  String get noNewNotifications => 'No New Notifications';

  @override
  String get noNewsFromPaddockYet => 'No News From Paddock Yet';

  @override
  String welcomeBackManager(String arg0) {
    return 'Welcome back, Manager $arg0';
  }

  @override
  String get sessionInProgress => 'Session In Progress';

  @override
  String get timeUntilNextSession => 'Time Until Next Session';

  @override
  String get teamBudget => 'Team Budget';

  @override
  String get deficit => 'Deficit';

  @override
  String get surplus => 'Surplus';

  @override
  String get estimatedAbbr => 'Estimated Abbr';

  @override
  String get nextGrandPrix => 'Next Grand Prix';

  @override
  String circuitLengthAndLaps(String arg0, String arg1) {
    return 'Distance: $arg0 km | Laps: $arg1';
  }

  @override
  String get paddockOpen => 'Paddock Open';

  @override
  String get weekendSetupBtn => 'Weekend Setup';

  @override
  String get qualifyingStatus => 'Qualifying';

  @override
  String get viewQualifyingBtn => 'View Qualifying';

  @override
  String get raceStrategyStatus => 'Race Strategy';

  @override
  String get setRaceStrategyBtn => 'Set Race Strategy';

  @override
  String get raceWeekendStatus => 'Race';

  @override
  String get goToRaceBtn => 'Go To Race';

  @override
  String get raceFinishedStatus => 'Race Finished Status';

  @override
  String get viewResultsBtn => 'View Results';

  @override
  String get circuitIntelTitle => 'Circuit Intel';

  @override
  String get aeroIntel => 'Aero Intel';

  @override
  String get highIntel => 'High Intel';

  @override
  String get powerIntel => 'Power Intel';

  @override
  String get speedIntel => 'Speed Intel';

  @override
  String get tyreIntel => 'Tyre Intel';

  @override
  String get onLive => 'On Live';

  @override
  String get offLive => 'Off Live';

  @override
  String get preRaceChecklist => 'Pre-Race Checklist';

  @override
  String get practiceProgram => 'Practice Program';

  @override
  String completedLapsOf(String arg0, String arg1) {
    return 'Laps: $arg0 / $arg1';
  }

  @override
  String get qualifyingSetup => 'Qualifying Setup';

  @override
  String get readyStatus => 'Ready Status';

  @override
  String get pendingStatus => 'Pending Status';

  @override
  String get hqDescription => 'Hq Description';

  @override
  String get facilitiesSectionTitle => 'Facilities Section';

  @override
  String levelLabel(String arg0) {
    return 'Level Label $arg0';
  }

  @override
  String get nextLevelLabel => 'Next Level';

  @override
  String get maintCostLabel => 'Maint Cost';

  @override
  String get bonusLabel => 'Bonus';

  @override
  String get buyBtn => 'Buy';

  @override
  String get comingSoonBanner => 'Coming Soon Banner';

  @override
  String facilityImproved(String arg0) {
    return 'Facility Improved $arg0';
  }

  @override
  String get signContractError => 'Sign Contract';

  @override
  String get confirmResetWorldTitle => 'Confirm Reset World';

  @override
  String get confirmResetWorldDesc => 'Confirm Reset World';

  @override
  String get cancelBtn => 'Cancel';

  @override
  String get resetSuccess => 'Reset Successful!';

  @override
  String get resetBtn => 'Reset';

  @override
  String get jobMarketTitle => 'Job Market';

  @override
  String get availableLabel => 'Available';

  @override
  String get signContract => 'Sign Contract';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navHQ => 'HQ';

  @override
  String get navTeamOffice => 'Office';

  @override
  String get navGarage => 'Garage';

  @override
  String get navYouthAcademy => 'Academy';

  @override
  String get navRacing => 'Racing';

  @override
  String get navWeekendSetup => 'Setup';

  @override
  String get navRaceDay => 'Race Day';

  @override
  String get navManagement => 'Management';

  @override
  String get navPersonal => 'Personal';

  @override
  String get navFinances => 'Finances';

  @override
  String get navSponsors => 'Sponsors';

  @override
  String get navSeason => 'Season';

  @override
  String get navStandings => 'Standings';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get accountInfo => 'Account';

  @override
  String get notAvailable => 'Not Available';

  @override
  String get lastSession => 'Last Session';

  @override
  String get adminBtn => 'Admin';

  @override
  String get accountBtn => 'Account';

  @override
  String get logOutConfirmTitle => 'Log Out Confirm';

  @override
  String get logOutConfirmDesc => 'Log Out Confirm';

  @override
  String get navMarket => 'Market';

  @override
  String get personalManagement => 'Personal Management';

  @override
  String get driversTitle => 'Drivers';

  @override
  String get fitnessTrainerTitle => 'Fitness Trainer';

  @override
  String get chiefEngineerTitle => 'Chief Engineer';

  @override
  String get hrManagerTitle => 'Hr Manager';

  @override
  String get marketingManagerTitle => 'Marketing Manager';

  @override
  String get currentBalanceTitle => 'Current Balance';

  @override
  String get recentMovementsTitle => 'Recent Movements';

  @override
  String get noFinancialActivity => 'No Financial Activity';

  @override
  String get selectCarPartToManage => 'Select Car Part To Manage';

  @override
  String activeContractTitle(String arg0) {
    return 'Active Contract Title $arg0';
  }

  @override
  String get weeklyPayLabel => 'Weekly Pay';

  @override
  String get racesLeftLabel => 'Races Left';

  @override
  String availableOffersTitle(String arg0) {
    return 'Available Offers Title $arg0';
  }

  @override
  String get rearWingPart => 'Rear Wing Part';

  @override
  String get sidepodLPart => 'Sidepod L Part';

  @override
  String get sidepodRPart => 'Sidepod R Part';

  @override
  String get haloPart => 'Halo Part';

  @override
  String get frontWingPart => 'Front Wing Part';

  @override
  String get nosePart => 'Nose Part';

  @override
  String get manageBtn => 'Manage';

  @override
  String get selectSponsorBtn => 'Select Sponsor';

  @override
  String get negotiationRulesTitle => 'Negotiation Rules';

  @override
  String get negotiationRulesDesc => 'Negotiation Rules';

  @override
  String get signingBonusLabel => 'Signing Bonus';

  @override
  String get weeklyPaymentLabel => 'Weekly Payment';

  @override
  String get durationLabel => 'Duration';

  @override
  String durationRaces(String arg0) {
    return 'Duration Races $arg0';
  }

  @override
  String get objectiveLabel => 'Objective';

  @override
  String get suspendedStatus => 'Suspended Status';

  @override
  String chooseTacticLabel(String arg0) {
    return 'Choose Tactic Label $arg0';
  }

  @override
  String get persuasiveTactic => 'Persuasive Tactic';

  @override
  String get negotiatorTactic => 'Negotiator Tactic';

  @override
  String get collaborativeTactic => 'Collaborative Tactic';

  @override
  String get availableSponsorsTitle => 'Available Sponsors';

  @override
  String get roleExDriverTitle => 'Role Ex Driver';

  @override
  String get roleExDriverDesc => 'Role Ex Driver';

  @override
  String get roleBusinessTitle => 'Role Business';

  @override
  String get roleBusinessDesc => 'Role Business';

  @override
  String get roleBureaucratTitle => 'Role Bureaucrat';

  @override
  String get roleBureaucratDesc => 'Role Bureaucrat';

  @override
  String get roleEngineerTitle => 'Role Engineer';

  @override
  String get roleEngineerDesc => 'Role Engineer';

  @override
  String get createManagerProfile => 'Create Manager Profile';

  @override
  String get personalInfoTitle => 'Personal Information';

  @override
  String get selectCountryError => 'Please select a country';

  @override
  String get genderLabel => 'Gender';

  @override
  String get maleGender => 'Male Gender';

  @override
  String get femaleGender => 'Female Gender';

  @override
  String get nonBinaryGender => 'Non Binary Gender';

  @override
  String get selectGenderError => 'Please select a gender';

  @override
  String get dayLabel => 'Day';

  @override
  String get monthLabel => 'Month';

  @override
  String get yearLabel => 'Year';

  @override
  String get selectBackgroundTitle => 'Select Background';

  @override
  String get createManagerDesc => 'Create Manager';

  @override
  String get establishCareerBtn => 'Establish Career';

  @override
  String get requiredError => 'This field is required';

  @override
  String get advantagesTitle => 'Advantages';

  @override
  String get disadvantagesTitle => 'Disadvantages';

  @override
  String get adminAccess => 'Admin Access';

  @override
  String get enterPin => 'Enter Pin';

  @override
  String get verifyBtn => 'Verify';

  @override
  String get nukeWorldTitle => 'Nuke World';

  @override
  String get nukeWorldDesc => 'Nuke World';

  @override
  String get nukeWorldSuccess => 'Database Reset Successful!';

  @override
  String errorPrefix(String arg0) {
    return 'Error Prefix $arg0';
  }

  @override
  String get executeNuke => 'Execute Nuke';

  @override
  String get ftgRacing => 'Ftg Racing';

  @override
  String get manager2026 => 'Manager2026';

  @override
  String get signInWithGoogle => 'Sign In With Google';

  @override
  String get signInWithEmail => 'Sign In With Email';

  @override
  String get devQuickStart => 'Dev Quick Start';

  @override
  String signingWithTeam(String arg0) {
    return 'Signing With Team $arg0';
  }

  @override
  String applicationFailed(String arg0) {
    return 'Application Failed $arg0';
  }

  @override
  String get selectTeamTitle => 'Select Team';

  @override
  String get selectTeamDesc => 'Select Team';

  @override
  String get worldChampionship => 'World Championship';

  @override
  String get secondSeries => 'Second Series';

  @override
  String get noTeamsAvailable => 'No Teams Available';

  @override
  String get recommendedTag => 'Recommended Tag';

  @override
  String get unlockLeagueDesc => 'Unlock League';

  @override
  String get mainDriverLabel => 'Main Driver';

  @override
  String get secondaryDriverLabel => 'Secondary Driver';

  @override
  String get selectTeamBtn => 'Select Team';

  @override
  String get selectedTag => 'Selected Tag';

  @override
  String get standingsConstructorTitle => 'Constructors';

  @override
  String get raceResults => 'Race Results';

  @override
  String get standingsTeam => 'Team';

  @override
  String get standingsPoints => 'Points';

  @override
  String get insufficientBudgetForNameChange =>
      'Insufficient Budget For Name Change';

  @override
  String teamRenamedFree(String arg0) {
    return 'Team Renamed Free $arg0';
  }

  @override
  String teamRenamedPaid(String arg0) {
    return 'Team Renamed Paid $arg0';
  }

  @override
  String get teamIdentityTitle => 'Team Identity';

  @override
  String get teamNameLabel => 'Team Name';

  @override
  String get confirmBtn => 'Confirm';

  @override
  String get regulationsTitle => 'Regulations';

  @override
  String get firstChangeUsed => 'First Change Used';

  @override
  String get firstChangeFree => 'First Change Free';

  @override
  String get nextChangesCost => 'Next Changes Cost';

  @override
  String renamedTimesLabel(String arg0) {
    return 'Renamed Times Label $arg0';
  }

  @override
  String get teamCareerStatsTitle => 'Team Career Stats';

  @override
  String get combinedDriversLabel => 'Combined Drivers';

  @override
  String get driverBreakdownTitle => 'Driver Breakdown';

  @override
  String get driverHeader => 'Driver Header';

  @override
  String get teamLiveryTitle => 'Team Livery';

  @override
  String get selectYourColors => 'Select Your Colors';

  @override
  String get liveryDescription => 'Livery Description';

  @override
  String get managerProfileSectionTitle => 'Manager Profile Section';

  @override
  String get circuitMexico => 'Circuit Mexico';

  @override
  String get circuitInterlagos => 'Circuit Interlagos';

  @override
  String get circuitMiami => 'Circuit Miami';

  @override
  String get circuitSanPabloStreet => 'Circuit San Pablo Street';

  @override
  String get circuitIndianapolis => 'Circuit Indianapolis';

  @override
  String get circuitMontreal => 'Circuit Montreal';

  @override
  String get circuitVegas => 'Circuit Vegas';

  @override
  String get circuitTexas => 'Circuit Texas';

  @override
  String get circuitBuenosAires => 'Circuit Buenos Aires';

  @override
  String get statusLivingLegend => 'Status Living Legend';

  @override
  String get statusEraDominator => 'Status Era Dominator';

  @override
  String get statusTheHeir => 'Status The Heir';

  @override
  String get statusTheHeiress => 'Status The Heiress';

  @override
  String get statusEliteVeteran => 'Status Elite Veteran';

  @override
  String get statusLastDance => 'Status Last Dance';

  @override
  String get statusSolidSpecialist => 'Status Solid Specialist';

  @override
  String get statusYoungWonder => 'Status Young Wonder';

  @override
  String get statusRisingStar => 'Status Rising Star';

  @override
  String get statusStuckPromise => 'Status Stuck Promise';

  @override
  String get statusJourneyman => 'Status Journeyman';

  @override
  String get statusJourneywoman => 'Status Journeywoman';

  @override
  String get statusUnsungDriver => 'Status Unsung Driver';

  @override
  String get statusMidfieldSpark => 'Status Midfield Spark';

  @override
  String get statusPastGlory => 'Status Past Glory';

  @override
  String get statusGridFiller => 'Status Grid Filler';

  @override
  String get statusUnknown => 'Status Unknown';

  @override
  String get descLivingLegend => 'Desc Living Legend';

  @override
  String get descEraDominator => 'Desc Era Dominator';

  @override
  String get descTheHeir => 'Desc The Heir';

  @override
  String get descEliteVeteran => 'Desc Elite Veteran';

  @override
  String get descLastDance => 'Desc Last Dance';

  @override
  String get descSolidSpecialist => 'Desc Solid Specialist';

  @override
  String get descYoungWonder => 'Desc Young Wonder';

  @override
  String get descRisingStar => 'Desc Rising Star';

  @override
  String get descStuckPromise => 'Desc Stuck Promise';

  @override
  String get descJourneyman => 'Desc Journeyman';

  @override
  String get descUnsungDriver => 'Desc Unsung Driver';

  @override
  String get descMidfieldSpark => 'Desc Midfield Spark';

  @override
  String get descPastGlory => 'Desc Past Glory';

  @override
  String get descGridFiller => 'Desc Grid Filler';

  @override
  String get descUnknown => 'Desc Unknown';

  @override
  String errorLoadingProfile(String arg0) {
    return 'Error Loading Profile $arg0';
  }

  @override
  String get powerStatsLabel => 'Power Stats';

  @override
  String get aeroStatsLabel => 'Aero Stats';

  @override
  String get handlingStatsLabel => 'Handling Stats';

  @override
  String get reliabilityStatsLabel => 'Reliability Stats';

  @override
  String get failedToLoadLiveries => 'Failed To Load Liveries';

  @override
  String liveryIndexLabel(String arg0, String arg1) {
    return 'Livery Index Label $arg0 $arg1';
  }

  @override
  String get loadingPhrase1 => 'Warming up engines...';

  @override
  String get loadingPhrase2 => 'Analyzing telemetry data...';

  @override
  String get loadingPhrase3 => 'Adjusting aero balance...';

  @override
  String get loadingPhrase4 => 'Preparing tyre sets...';

  @override
  String get loadingPhrase5 => 'Checking fuel levels...';

  @override
  String get loadingPhrase6 => 'Syncing with pit wall...';

  @override
  String get loadingPhrase7 => 'Optimizing engine map...';

  @override
  String get loadingPhrase8 => 'Awaiting green flag...';

  @override
  String minsAgo(int arg0) {
    return 'Mins Ago $arg0';
  }

  @override
  String hoursAgo(int arg0) {
    return 'Hours Ago $arg0';
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
    return 'Press News Manager Join $arg0 $arg1 $arg2 $arg3 $arg4 $arg5 $arg6';
  }

  @override
  String get motorsportDaily => 'Motorsport Daily';

  @override
  String get readFullArticle => 'Read Full Article';

  @override
  String get closeBtn => 'Close';

  @override
  String get navOffice => 'Office';

  @override
  String get objFinishTop3 => 'Finish Top 3';

  @override
  String get objBothInPoints => 'Both cars in points';

  @override
  String get objRaceWin => 'Race Win';

  @override
  String get objFinishTop10 => 'Finish Top 10';

  @override
  String get objFastestLap => 'Fastest Lap';

  @override
  String get objFinishRace => 'Finish the race';

  @override
  String get objImproveGrid => 'Improve Grid Position';

  @override
  String get objOvertake3Cars => 'Overtake 3 cars';
}
