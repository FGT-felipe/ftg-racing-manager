import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'FTG Racing Manager'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @paddockTitle.
  ///
  /// In en, this message translates to:
  /// **'PADDOCK'**
  String get paddockTitle;

  /// No description provided for @garageTitle.
  ///
  /// In en, this message translates to:
  /// **'GARAGE'**
  String get garageTitle;

  /// No description provided for @hqTitle.
  ///
  /// In en, this message translates to:
  /// **'HEADQUARTERS'**
  String get hqTitle;

  /// No description provided for @standingsTitle.
  ///
  /// In en, this message translates to:
  /// **'STANDINGS'**
  String get standingsTitle;

  /// No description provided for @newsTitle.
  ///
  /// In en, this message translates to:
  /// **'PRESS NEWS'**
  String get newsTitle;

  /// No description provided for @officeTitle.
  ///
  /// In en, this message translates to:
  /// **'OFFICE'**
  String get officeTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @nextRace.
  ///
  /// In en, this message translates to:
  /// **'NEXT RACE'**
  String get nextRace;

  /// No description provided for @raceDaySundayTime.
  ///
  /// In en, this message translates to:
  /// **'SUNDAY, 14:00 LOCAL'**
  String get raceDaySundayTime;

  /// No description provided for @raceDayRaceTime.
  ///
  /// In en, this message translates to:
  /// **'RACE: {time}'**
  String raceDayRaceTime(Object time);

  /// No description provided for @raceDaySunday.
  ///
  /// In en, this message translates to:
  /// **'SUNDAY'**
  String get raceDaySunday;

  /// No description provided for @raceDayLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get raceDayLive;

  /// No description provided for @raceDayLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading race data...'**
  String get raceDayLoadingData;

  /// No description provided for @raceDayTitle.
  ///
  /// In en, this message translates to:
  /// **'RACE DAY'**
  String get raceDayTitle;

  /// No description provided for @raceDayLap.
  ///
  /// In en, this message translates to:
  /// **'LAP'**
  String get raceDayLap;

  /// No description provided for @raceDayFastestLap.
  ///
  /// In en, this message translates to:
  /// **'FASTEST LAP'**
  String get raceDayFastestLap;

  /// No description provided for @raceDayRacePositions.
  ///
  /// In en, this message translates to:
  /// **'RACE POSITIONS'**
  String get raceDayRacePositions;

  /// No description provided for @raceDayInBoxes.
  ///
  /// In en, this message translates to:
  /// **'IN BOXES'**
  String get raceDayInBoxes;

  /// No description provided for @raceDayRaceLabel.
  ///
  /// In en, this message translates to:
  /// **'RACE'**
  String get raceDayRaceLabel;

  /// No description provided for @raceDayPitBoard.
  ///
  /// In en, this message translates to:
  /// **'PIT BOARD'**
  String get raceDayPitBoard;

  /// No description provided for @raceDayCommentary.
  ///
  /// In en, this message translates to:
  /// **'COMMENTARY'**
  String get raceDayCommentary;

  /// No description provided for @raceCompletedResults.
  ///
  /// In en, this message translates to:
  /// **'RACE COMPLETED — RESULTS'**
  String get raceCompletedResults;

  /// No description provided for @raceFinished.
  ///
  /// In en, this message translates to:
  /// **'FINISHED'**
  String get raceFinished;

  /// No description provided for @racePreRace.
  ///
  /// In en, this message translates to:
  /// **'PRE-RACE'**
  String get racePreRace;

  /// No description provided for @raceLightsOutSoon.
  ///
  /// In en, this message translates to:
  /// **'LIGHTS OUT SOON'**
  String get raceLightsOutSoon;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No events recorded yet. Stand by for lights out.'**
  String get noEventsYet;

  /// No description provided for @raceWaitingStart.
  ///
  /// In en, this message translates to:
  /// **'Waiting for race start...'**
  String get raceWaitingStart;

  /// No description provided for @retired.
  ///
  /// In en, this message translates to:
  /// **'RETIRED'**
  String get retired;

  /// No description provided for @leader.
  ///
  /// In en, this message translates to:
  /// **'LEADER'**
  String get leader;

  /// No description provided for @standingsInterval.
  ///
  /// In en, this message translates to:
  /// **'INTERVAL'**
  String get standingsInterval;

  /// No description provided for @standingsPos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get standingsPos;

  /// No description provided for @standingsDriver.
  ///
  /// In en, this message translates to:
  /// **'DRIVER'**
  String get standingsDriver;

  /// No description provided for @navDrivers.
  ///
  /// In en, this message translates to:
  /// **'DRIVERS'**
  String get navDrivers;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'EVENTS'**
  String get navEvents;

  /// No description provided for @garageEvents.
  ///
  /// In en, this message translates to:
  /// **'GARAGE EVENTS'**
  String get garageEvents;

  /// No description provided for @waitingForLightsOut.
  ///
  /// In en, this message translates to:
  /// **'Waiting for lights out...'**
  String get waitingForLightsOut;

  /// No description provided for @commentatorsStandingBy.
  ///
  /// In en, this message translates to:
  /// **'Commentators standing by for the start...'**
  String get commentatorsStandingBy;

  /// No description provided for @practiceTab.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE'**
  String get practiceTab;

  /// No description provided for @qualifyingTab.
  ///
  /// In en, this message translates to:
  /// **'QUALIFYING'**
  String get qualifyingTab;

  /// No description provided for @raceTab.
  ///
  /// In en, this message translates to:
  /// **'RACE'**
  String get raceTab;

  /// No description provided for @garageRaceSetupSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Race setup submitted ✓'**
  String get garageRaceSetupSubmitted;

  /// No description provided for @garageError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String garageError(String message);

  /// No description provided for @garageDriverCrashedSessionOver.
  ///
  /// In en, this message translates to:
  /// **'This driver has crashed and cannot run again this session.'**
  String get garageDriverCrashedSessionOver;

  /// No description provided for @garageDriverCrashedSessionOverDetails.
  ///
  /// In en, this message translates to:
  /// **'Repair and medical costs have been applied. This driver cannot run again this qualifying session.'**
  String get garageDriverCrashedSessionOverDetails;

  /// No description provided for @garageOutLap.
  ///
  /// In en, this message translates to:
  /// **'OUT LAP...'**
  String get garageOutLap;

  /// No description provided for @garagePushing.
  ///
  /// In en, this message translates to:
  /// **'PUSHING...'**
  String get garagePushing;

  /// No description provided for @garageCrashAccident.
  ///
  /// In en, this message translates to:
  /// **'CRASH! {name} HAS HAD AN ACCIDENT!'**
  String garageCrashAccident(String name);

  /// No description provided for @garageCrashedQualifying.
  ///
  /// In en, this message translates to:
  /// **'CRASHED! QUALIFYING OVER'**
  String get garageCrashedQualifying;

  /// No description provided for @garageInLap.
  ///
  /// In en, this message translates to:
  /// **'IN LAP...'**
  String get garageInLap;

  /// No description provided for @garageImprovedTime.
  ///
  /// In en, this message translates to:
  /// **'✓ {time} — New PB! (Attempt {current}/{total})'**
  String garageImprovedTime(String time, int current, int total);

  /// No description provided for @garageNoImprovement.
  ///
  /// In en, this message translates to:
  /// **'⏱ {time} — No improvement (Attempt {current}/{total})'**
  String garageNoImprovement(String time, int current, int total);

  /// No description provided for @garageTabPractice.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE'**
  String get garageTabPractice;

  /// No description provided for @garageTabQualifying.
  ///
  /// In en, this message translates to:
  /// **'QUALIFYING'**
  String get garageTabQualifying;

  /// No description provided for @garageTabRace.
  ///
  /// In en, this message translates to:
  /// **'RACE'**
  String get garageTabRace;

  /// No description provided for @garageSelectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select a driver to configure setup'**
  String get garageSelectDriver;

  /// No description provided for @garageCircuitIntel.
  ///
  /// In en, this message translates to:
  /// **'CIRCUIT INTEL'**
  String get garageCircuitIntel;

  /// No description provided for @garageSetupPractice.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE SETUP'**
  String get garageSetupPractice;

  /// No description provided for @garageSetupQualifying.
  ///
  /// In en, this message translates to:
  /// **'QUALIFYING SETUP'**
  String get garageSetupQualifying;

  /// No description provided for @garageSetupRace.
  ///
  /// In en, this message translates to:
  /// **'RACE SETUP'**
  String get garageSetupRace;

  /// No description provided for @garageDriverStyle.
  ///
  /// In en, this message translates to:
  /// **'DRIVER STYLE'**
  String get garageDriverStyle;

  /// No description provided for @garageStartSeries.
  ///
  /// In en, this message translates to:
  /// **'START SERIES'**
  String get garageStartSeries;

  /// No description provided for @garageRunQualyAttempt.
  ///
  /// In en, this message translates to:
  /// **'RUN QUALIFYING ATTEMPT ({current}/{total})'**
  String garageRunQualyAttempt(int current, int total);

  /// No description provided for @garageParcFermeLabel.
  ///
  /// In en, this message translates to:
  /// **'PARC FERMÉ'**
  String get garageParcFermeLabel;

  /// No description provided for @garageParcFerme.
  ///
  /// In en, this message translates to:
  /// **'PARC FERMÉ: Only front wing and tyres can be changed. (Attempt {current}/{total})'**
  String garageParcFerme(int current, int total);

  /// No description provided for @garageQualyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts: {current}/{total}'**
  String garageQualyAttempts(int current, int total);

  /// No description provided for @garageAllAttemptsUsed.
  ///
  /// In en, this message translates to:
  /// **'ALL ATTEMPTS USED'**
  String get garageAllAttemptsUsed;

  /// No description provided for @garageMaxQualifyingAttemptsReached.
  ///
  /// In en, this message translates to:
  /// **'Max qualifying attempts reached for this session.'**
  String get garageMaxQualifyingAttemptsReached;

  /// No description provided for @garageBestTime.
  ///
  /// In en, this message translates to:
  /// **'BEST: {time}'**
  String garageBestTime(String time);

  /// No description provided for @garageLastLap.
  ///
  /// In en, this message translates to:
  /// **'LAST LAP'**
  String get garageLastLap;

  /// No description provided for @garagePos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get garagePos;

  /// No description provided for @garageGap.
  ///
  /// In en, this message translates to:
  /// **'GAP'**
  String get garageGap;

  /// No description provided for @garageTyre.
  ///
  /// In en, this message translates to:
  /// **'TYRE'**
  String get garageTyre;

  /// No description provided for @garageTime.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get garageTime;

  /// No description provided for @garageLaps.
  ///
  /// In en, this message translates to:
  /// **'LAPS'**
  String get garageLaps;

  /// No description provided for @garageLoadingParticipants.
  ///
  /// In en, this message translates to:
  /// **'Loading participants...'**
  String get garageLoadingParticipants;

  /// No description provided for @garageQualySessionOpen.
  ///
  /// In en, this message translates to:
  /// **'QUALIFYING SESSION OPEN'**
  String get garageQualySessionOpen;

  /// No description provided for @garageQualySessionClosed.
  ///
  /// In en, this message translates to:
  /// **'QUALIFYING SESSION CLOSED'**
  String get garageQualySessionClosed;

  /// No description provided for @garageRaceStrategyDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure your complete race strategy and driving styles. This setup will be used during the race itself.'**
  String get garageRaceStrategyDesc;

  /// No description provided for @garageRaceRegulationTyre.
  ///
  /// In en, this message translates to:
  /// **'Rule: Hard compound tyres MUST be used at least once during the race.'**
  String get garageRaceRegulationTyre;

  /// No description provided for @garageSubmitRaceSetup.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT RACE SETUP'**
  String get garageSubmitRaceSetup;

  /// No description provided for @garageCarConfiguration.
  ///
  /// In en, this message translates to:
  /// **'CAR CONFIGURATION'**
  String get garageCarConfiguration;

  /// No description provided for @garageRaceStrategy.
  ///
  /// In en, this message translates to:
  /// **'RACE STRATEGY'**
  String get garageRaceStrategy;

  /// No description provided for @garageRaceStart.
  ///
  /// In en, this message translates to:
  /// **'RACE START'**
  String get garageRaceStart;

  /// No description provided for @garagePitStop.
  ///
  /// In en, this message translates to:
  /// **'STOP {number}'**
  String garagePitStop(int number);

  /// No description provided for @garageAddPitStop.
  ///
  /// In en, this message translates to:
  /// **'ADD PIT STOP'**
  String get garageAddPitStop;

  /// No description provided for @garageFitness.
  ///
  /// In en, this message translates to:
  /// **'FITNESS: {value}%'**
  String garageFitness(int value);

  /// No description provided for @garageDnf.
  ///
  /// In en, this message translates to:
  /// **'DNF'**
  String get garageDnf;

  /// No description provided for @garageRepairMedicalCosts.
  ///
  /// In en, this message translates to:
  /// **'Repair and medical costs have been applied. This driver cannot run again this qualifying session.'**
  String get garageRepairMedicalCosts;

  /// No description provided for @garageConfidence.
  ///
  /// In en, this message translates to:
  /// **'CONFIDENCE'**
  String get garageConfidence;

  /// No description provided for @garageRestoreSetup.
  ///
  /// In en, this message translates to:
  /// **'RESTORE THIS SETUP'**
  String get garageRestoreSetup;

  /// No description provided for @garageSetupRestored.
  ///
  /// In en, this message translates to:
  /// **'Setup restored to current session'**
  String get garageSetupRestored;

  /// No description provided for @garageLapTimes.
  ///
  /// In en, this message translates to:
  /// **'LAP TIMES — {name}'**
  String garageLapTimes(String name);

  /// No description provided for @garageNoLapsYet.
  ///
  /// In en, this message translates to:
  /// **'No laps recorded yet'**
  String get garageNoLapsYet;

  /// No description provided for @garageNoFeedbackYet.
  ///
  /// In en, this message translates to:
  /// **'No feedback gathered yet'**
  String get garageNoFeedbackYet;

  /// No description provided for @garageSetQualy.
  ///
  /// In en, this message translates to:
  /// **'SET QUALY'**
  String get garageSetQualy;

  /// No description provided for @garageSetRace.
  ///
  /// In en, this message translates to:
  /// **'SET RACE'**
  String get garageSetRace;

  /// No description provided for @setupFrontWing.
  ///
  /// In en, this message translates to:
  /// **'Front Wing'**
  String get setupFrontWing;

  /// No description provided for @setupRearWing.
  ///
  /// In en, this message translates to:
  /// **'Rear Wing'**
  String get setupRearWing;

  /// No description provided for @setupSuspension.
  ///
  /// In en, this message translates to:
  /// **'Suspension'**
  String get setupSuspension;

  /// No description provided for @setupGearRatio.
  ///
  /// In en, this message translates to:
  /// **'Gear Ratio'**
  String get setupGearRatio;

  /// No description provided for @styleRisky.
  ///
  /// In en, this message translates to:
  /// **'RISKY'**
  String get styleRisky;

  /// No description provided for @styleAttack.
  ///
  /// In en, this message translates to:
  /// **'ATTACK'**
  String get styleAttack;

  /// No description provided for @styleNormal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get styleNormal;

  /// No description provided for @styleConserve.
  ///
  /// In en, this message translates to:
  /// **'CONSERVE'**
  String get styleConserve;

  /// No description provided for @tipRisky.
  ///
  /// In en, this message translates to:
  /// **'Most aggressive push — highest risk, highest reward'**
  String get tipRisky;

  /// No description provided for @tipAttack.
  ///
  /// In en, this message translates to:
  /// **'Offensive style — push hard for lap time'**
  String get tipAttack;

  /// No description provided for @tipNormal.
  ///
  /// In en, this message translates to:
  /// **'Balanced driving — default style'**
  String get tipNormal;

  /// No description provided for @tipConserve.
  ///
  /// In en, this message translates to:
  /// **'Defensive / tyre saving style'**
  String get tipConserve;

  /// No description provided for @tipRegulationStartTyres.
  ///
  /// In en, this message translates to:
  /// **'REGULATION: Start tyres are fixed. Drivers must start on the same compound used for their best qualifying lap.'**
  String get tipRegulationStartTyres;

  /// No description provided for @pitBoardMessageInBox.
  ///
  /// In en, this message translates to:
  /// **'IN BOX'**
  String get pitBoardMessageInBox;

  /// No description provided for @pitBoardMessageReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get pitBoardMessageReady;

  /// No description provided for @pitBoardNewTeamRecord.
  ///
  /// In en, this message translates to:
  /// **'{name}: NEW TEAM RECORD — {time}!'**
  String pitBoardNewTeamRecord(String name, String time);

  /// No description provided for @pitBoardNewPB.
  ///
  /// In en, this message translates to:
  /// **'{name}: New Personal Best — {time}'**
  String pitBoardNewPB(String name, String time);

  /// No description provided for @pitBoardReturningPits.
  ///
  /// In en, this message translates to:
  /// **'{name} is returning to the pits...'**
  String pitBoardReturningPits(String name);

  /// No description provided for @pitBoardInGarage.
  ///
  /// In en, this message translates to:
  /// **'{name} is back in the garage.'**
  String pitBoardInGarage(String name);

  /// No description provided for @pitBoardLeftPits.
  ///
  /// In en, this message translates to:
  /// **'{name} IS LEAVING THE PITS'**
  String pitBoardLeftPits(String name);

  /// No description provided for @pitBoardStartingPractice.
  ///
  /// In en, this message translates to:
  /// **'{name} IS STARTING PRACTICE SERIES'**
  String pitBoardStartingPractice(String name);

  /// No description provided for @pitBoardOnLap.
  ///
  /// In en, this message translates to:
  /// **'{name}: LAP {current}/{total}'**
  String pitBoardOnLap(String name, int current, int total);

  /// No description provided for @bestPb.
  ///
  /// In en, this message translates to:
  /// **'BEST PB'**
  String get bestPb;

  /// No description provided for @fastest.
  ///
  /// In en, this message translates to:
  /// **'FASTEST'**
  String get fastest;

  /// No description provided for @garagePracticeClosedRace.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE CLOSED: Race setup has been submitted.'**
  String get garagePracticeClosedRace;

  /// No description provided for @garagePracticeClosedQualy.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE CLOSED: Qualifying session has started.'**
  String get garagePracticeClosedQualy;

  /// No description provided for @garageQualyIntro.
  ///
  /// In en, this message translates to:
  /// **'Configure your qualifying setup and run attempts to set the best lap time. Max attempts: {total}'**
  String garageQualyIntro(int total);

  /// No description provided for @garageRaceStrategyStintTips.
  ///
  /// In en, this message translates to:
  /// **'Optimize fuel load, tyre choices, and driving aggression for each stint.'**
  String get garageRaceStrategyStintTips;

  /// No description provided for @setupTyreCompound.
  ///
  /// In en, this message translates to:
  /// **'Tyre Compound'**
  String get setupTyreCompound;

  /// No description provided for @labelFuel.
  ///
  /// In en, this message translates to:
  /// **'FUEL'**
  String get labelFuel;

  /// No description provided for @labelDriveStyle.
  ///
  /// In en, this message translates to:
  /// **'DRIVE STYLE'**
  String get labelDriveStyle;

  /// No description provided for @labelTyres.
  ///
  /// In en, this message translates to:
  /// **'TYRES'**
  String get labelTyres;

  /// No description provided for @labelLaps.
  ///
  /// In en, this message translates to:
  /// **'LAPS'**
  String get labelLaps;

  /// No description provided for @labelLapTime.
  ///
  /// In en, this message translates to:
  /// **'LAP TIME'**
  String get labelLapTime;

  /// No description provided for @labelGap.
  ///
  /// In en, this message translates to:
  /// **'GAP'**
  String get labelGap;

  /// No description provided for @weatherLabel.
  ///
  /// In en, this message translates to:
  /// **'WEATHER'**
  String get weatherLabel;

  /// No description provided for @trackTempLabel.
  ///
  /// In en, this message translates to:
  /// **'TRACK'**
  String get trackTempLabel;

  /// No description provided for @airTempLabel.
  ///
  /// In en, this message translates to:
  /// **'AIR'**
  String get airTempLabel;

  /// No description provided for @humidityLabel.
  ///
  /// In en, this message translates to:
  /// **'HUMIDITY'**
  String get humidityLabel;

  /// No description provided for @garageMaxLapsReached.
  ///
  /// In en, this message translates to:
  /// **'Driver reached max practice laps ({max}). Reducing series to {remaining} laps.'**
  String garageMaxLapsReached(Object max, Object remaining);

  /// No description provided for @garageCrashAlert.
  ///
  /// In en, this message translates to:
  /// **'CRASH! {name} HAS HAD AN ACCIDENT!'**
  String garageCrashAlert(Object name);

  /// No description provided for @garageSeriesCompletedConfidence.
  ///
  /// In en, this message translates to:
  /// **'Series completed. Setup confidence: {value}%'**
  String garageSeriesCompletedConfidence(Object value);

  /// No description provided for @garageQualySetupSavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Qualifying setup saved (Draft)'**
  String get garageQualySetupSavedDraft;

  /// No description provided for @garageRaceSetupSavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Race setup draft saved.'**
  String get garageRaceSetupSavedDraft;

  /// No description provided for @garageDriver.
  ///
  /// In en, this message translates to:
  /// **'DRIVER'**
  String get garageDriver;

  /// No description provided for @garageConstructor.
  ///
  /// In en, this message translates to:
  /// **'CONSTRUCTOR'**
  String get garageConstructor;

  /// No description provided for @garageLapsIntel.
  ///
  /// In en, this message translates to:
  /// **'LAPS'**
  String get garageLapsIntel;

  /// No description provided for @garageTyresIntel.
  ///
  /// In en, this message translates to:
  /// **'TYRES'**
  String get garageTyresIntel;

  /// No description provided for @garageWeatherIntel.
  ///
  /// In en, this message translates to:
  /// **'WEATHER'**
  String get garageWeatherIntel;

  /// No description provided for @garageEngineIntel.
  ///
  /// In en, this message translates to:
  /// **'ENGINE'**
  String get garageEngineIntel;

  /// No description provided for @garageFuelIntel.
  ///
  /// In en, this message translates to:
  /// **'FUEL'**
  String get garageFuelIntel;

  /// No description provided for @garageAeroIntel.
  ///
  /// In en, this message translates to:
  /// **'AERO'**
  String get garageAeroIntel;

  /// No description provided for @garageWeatherSunny.
  ///
  /// In en, this message translates to:
  /// **'SUNNY'**
  String get garageWeatherSunny;

  /// No description provided for @garageWeatherExtremeHigh.
  ///
  /// In en, this message translates to:
  /// **'EXTREME'**
  String get garageWeatherExtremeHigh;

  /// No description provided for @garageWeatherExtremeLow.
  ///
  /// In en, this message translates to:
  /// **'EXTREME LOW'**
  String get garageWeatherExtremeLow;

  /// No description provided for @garageImportant.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT'**
  String get garageImportant;

  /// No description provided for @garageCrucial.
  ///
  /// In en, this message translates to:
  /// **'CRUCIAL'**
  String get garageCrucial;

  /// No description provided for @garageCritical.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL'**
  String get garageCritical;

  /// No description provided for @garageVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'VERY HIGH'**
  String get garageVeryHigh;

  /// No description provided for @garageMaximum.
  ///
  /// In en, this message translates to:
  /// **'MAXIMUM'**
  String get garageMaximum;

  /// No description provided for @garageFocus.
  ///
  /// In en, this message translates to:
  /// **'FOCUS'**
  String get garageFocus;

  /// No description provided for @garageQualifyingResults.
  ///
  /// In en, this message translates to:
  /// **'QUALIFYING RESULTS'**
  String get garageQualifyingResults;

  /// No description provided for @garageLocked.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get garageLocked;

  /// No description provided for @garageLowPriority.
  ///
  /// In en, this message translates to:
  /// **'LOW PRIORITY'**
  String get garageLowPriority;

  /// No description provided for @garageLapsCount.
  ///
  /// In en, this message translates to:
  /// **'Attempts: {current}/{total}'**
  String garageLapsCount(int current, int total);

  /// No description provided for @garageLapsCountShort.
  ///
  /// In en, this message translates to:
  /// **'Laps: {count}'**
  String garageLapsCountShort(int count);

  /// No description provided for @garageDnfSessionOver.
  ///
  /// In en, this message translates to:
  /// **'DNF — SESSION OVER'**
  String get garageDnfSessionOver;

  /// No description provided for @garageBestPersonal.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL BEST'**
  String get garageBestPersonal;

  /// No description provided for @garageBestLapTimeShort.
  ///
  /// In en, this message translates to:
  /// **'PB: {time}'**
  String garageBestLapTimeShort(String time);

  /// No description provided for @garageLapSetup.
  ///
  /// In en, this message translates to:
  /// **'LAP SETUP — {time}'**
  String garageLapSetup(String time);

  /// No description provided for @garageClose.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get garageClose;

  /// No description provided for @garagePitStopStrategyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Plan your pit strategy and tyre compounds.'**
  String get garagePitStopStrategyTooltip;

  /// No description provided for @garageParcFermeLockedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Parc Fermé: This setting cannot be changed.'**
  String get garageParcFermeLockedTooltip;

  /// No description provided for @garageConfidenceShort.
  ///
  /// In en, this message translates to:
  /// **'CONF.'**
  String get garageConfidenceShort;

  /// No description provided for @garagePitBoard.
  ///
  /// In en, this message translates to:
  /// **'PIT BOARD'**
  String get garagePitBoard;

  /// No description provided for @garageReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get garageReady;

  /// No description provided for @garageDriverFeedback.
  ///
  /// In en, this message translates to:
  /// **'DRIVER FEEDBACK'**
  String get garageDriverFeedback;

  /// No description provided for @garageNoLapsRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'No laps recorded yet'**
  String get garageNoLapsRecordedYet;

  /// No description provided for @garageRaceStartTyreRegulation.
  ///
  /// In en, this message translates to:
  /// **'Regulation: Must start on best qualifying tyres.'**
  String get garageRaceStartTyreRegulation;

  /// No description provided for @garageLapsIntelShort.
  ///
  /// In en, this message translates to:
  /// **'{count} LAPS'**
  String garageLapsIntelShort(Object count);

  /// No description provided for @garageNoFeedbackGatheredYet.
  ///
  /// In en, this message translates to:
  /// **'No feedback gathered yet'**
  String get garageNoFeedbackGatheredYet;

  /// No description provided for @garageFitnessPercentage.
  ///
  /// In en, this message translates to:
  /// **'FITNESS: {percent}%'**
  String garageFitnessPercentage(int percent);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
