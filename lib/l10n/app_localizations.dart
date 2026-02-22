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

  /// No description provided for @facTeamOffice.
  ///
  /// In en, this message translates to:
  /// **'Team Office'**
  String get facTeamOffice;

  /// No description provided for @facGarage.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get facGarage;

  /// No description provided for @facYouthAcademy.
  ///
  /// In en, this message translates to:
  /// **'Youth Academy'**
  String get facYouthAcademy;

  /// No description provided for @facPressRoom.
  ///
  /// In en, this message translates to:
  /// **'Press Room'**
  String get facPressRoom;

  /// No description provided for @facScoutingOffice.
  ///
  /// In en, this message translates to:
  /// **'Scouting Office'**
  String get facScoutingOffice;

  /// No description provided for @facRacingSimulator.
  ///
  /// In en, this message translates to:
  /// **'Racing Simulator'**
  String get facRacingSimulator;

  /// No description provided for @facGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get facGym;

  /// No description provided for @facRDOffice.
  ///
  /// In en, this message translates to:
  /// **'R&D Office'**
  String get facRDOffice;

  /// No description provided for @descTeamOffice.
  ///
  /// In en, this message translates to:
  /// **'Administrative hub and contract management.'**
  String get descTeamOffice;

  /// No description provided for @descGarage.
  ///
  /// In en, this message translates to:
  /// **'Vehicle maintenance and technical tuning.'**
  String get descGarage;

  /// No description provided for @descYouthAcademy.
  ///
  /// In en, this message translates to:
  /// **'Training future talents for the team.'**
  String get descYouthAcademy;

  /// No description provided for @descPressRoom.
  ///
  /// In en, this message translates to:
  /// **'Media relations and public image management.'**
  String get descPressRoom;

  /// No description provided for @descScoutingOffice.
  ///
  /// In en, this message translates to:
  /// **'Global talent search for drivers and engineers.'**
  String get descScoutingOffice;

  /// No description provided for @descRacingSimulator.
  ///
  /// In en, this message translates to:
  /// **'Precision training in a virtual environment.'**
  String get descRacingSimulator;

  /// No description provided for @descGym.
  ///
  /// In en, this message translates to:
  /// **'Physical preparation and driver endurance.'**
  String get descGym;

  /// No description provided for @descRDOffice.
  ///
  /// In en, this message translates to:
  /// **'Constant innovation and technical development.'**
  String get descRDOffice;

  /// No description provided for @notPurchased.
  ///
  /// In en, this message translates to:
  /// **'Not Purchased'**
  String get notPurchased;

  /// No description provided for @bonusBudget.
  ///
  /// In en, this message translates to:
  /// **'Bonus Budget {arg0}'**
  String bonusBudget(String arg0);

  /// No description provided for @bonusRepair.
  ///
  /// In en, this message translates to:
  /// **'Bonus Repair {arg0}'**
  String bonusRepair(String arg0);

  /// No description provided for @bonusScouting.
  ///
  /// In en, this message translates to:
  /// **'Bonus Scouting {arg0}'**
  String bonusScouting(String arg0);

  /// No description provided for @bonusTBD.
  ///
  /// In en, this message translates to:
  /// **'Bonus T B D'**
  String get bonusTBD;

  /// No description provided for @accountSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettingsTitle;

  /// No description provided for @userProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfileTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @registeredLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registeredLabel;

  /// No description provided for @userDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'User Data Not Found'**
  String get userDataNotFound;

  /// No description provided for @managerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Manager Profile'**
  String get managerProfileTitle;

  /// No description provided for @managerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Manager Name'**
  String get managerNameLabel;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @noManagerProfile.
  ///
  /// In en, this message translates to:
  /// **'No Manager Profile'**
  String get noManagerProfile;

  /// No description provided for @logOutBtn.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOutBtn;

  /// No description provided for @googleAuthError.
  ///
  /// In en, this message translates to:
  /// **'Google Auth Error {arg0}'**
  String googleAuthError(String arg0);

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Auth Error {arg0}'**
  String authError(String arg0);

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email Already Registered'**
  String get emailAlreadyRegistered;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected Error {arg0}'**
  String unexpectedError(String arg0);

  /// No description provided for @formulaTrackGlory.
  ///
  /// In en, this message translates to:
  /// **'Formula Track Glory'**
  String get formulaTrackGlory;

  /// No description provided for @ftgSlogan.
  ///
  /// In en, this message translates to:
  /// **'Ftg Slogan'**
  String get ftgSlogan;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already Have Account'**
  String get alreadyHaveAccount;

  /// No description provided for @newManagerJoin.
  ///
  /// In en, this message translates to:
  /// **'New Manager Join'**
  String get newManagerJoin;

  /// No description provided for @versionFooter.
  ///
  /// In en, this message translates to:
  /// **'V3.0.0 - Fire Tower Games Studio'**
  String get versionFooter;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue With Google'**
  String get continueWithGoogle;

  /// No description provided for @orUseEmail.
  ///
  /// In en, this message translates to:
  /// **'Or Use Email'**
  String get orUseEmail;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @createAccountBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountBtn;

  /// No description provided for @signInBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInBtn;

  /// No description provided for @calendarNoEvents.
  ///
  /// In en, this message translates to:
  /// **'Calendar No Events'**
  String get calendarNoEvents;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @lapsIntel.
  ///
  /// In en, this message translates to:
  /// **'Laps Intel'**
  String get lapsIntel;

  /// No description provided for @calendarStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Calendar Status Scheduled'**
  String get calendarStatusScheduled;

  /// No description provided for @driversManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Drivers Management'**
  String get driversManagementTitle;

  /// No description provided for @errorLoadingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Drivers'**
  String get errorLoadingDrivers;

  /// No description provided for @noDriversFound.
  ///
  /// In en, this message translates to:
  /// **'No Drivers Found'**
  String get noDriversFound;

  /// No description provided for @renewingContractSimulated.
  ///
  /// In en, this message translates to:
  /// **'Renewing Contract Simulated {arg0}'**
  String renewingContractSimulated(String arg0);

  /// No description provided for @firingDriverSimulated.
  ///
  /// In en, this message translates to:
  /// **'Firing Driver Simulated {arg0}'**
  String firingDriverSimulated(String arg0);

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age {arg0}'**
  String ageLabel(int arg0);

  /// No description provided for @contractDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contract Details'**
  String get contractDetailsTitle;

  /// No description provided for @contractStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Contract Status'**
  String get contractStatusLabel;

  /// No description provided for @salaryPerRaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Salary per Race'**
  String get salaryPerRaceLabel;

  /// No description provided for @terminationLabel.
  ///
  /// In en, this message translates to:
  /// **'Termination'**
  String get terminationLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @seasonsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Seasons Remaining: {arg0}'**
  String seasonsRemaining(String arg0);

  /// No description provided for @moraleLabel.
  ///
  /// In en, this message translates to:
  /// **'Morale'**
  String get moraleLabel;

  /// No description provided for @marketabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Marketability'**
  String get marketabilityLabel;

  /// No description provided for @fireBtn.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fireBtn;

  /// No description provided for @renewContractBtn.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renewContractBtn;

  /// No description provided for @driverStatsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Stats Section'**
  String get driverStatsSectionTitle;

  /// No description provided for @careerStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Career Stats'**
  String get careerStatsTitle;

  /// No description provided for @titlesStat.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get titlesStat;

  /// No description provided for @winsStat.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get winsStat;

  /// No description provided for @podiumsStat.
  ///
  /// In en, this message translates to:
  /// **'Podiums'**
  String get podiumsStat;

  /// No description provided for @racesStat.
  ///
  /// In en, this message translates to:
  /// **'Races'**
  String get racesStat;

  /// No description provided for @championshipFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Championship Form'**
  String get championshipFormTitle;

  /// No description provided for @standingsBtn.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get standingsBtn;

  /// No description provided for @posLabel.
  ///
  /// In en, this message translates to:
  /// **'Pos'**
  String get posLabel;

  /// No description provided for @eventHeader.
  ///
  /// In en, this message translates to:
  /// **'Event Header'**
  String get eventHeader;

  /// No description provided for @qHeader.
  ///
  /// In en, this message translates to:
  /// **'Q Header'**
  String get qHeader;

  /// No description provided for @rHeader.
  ///
  /// In en, this message translates to:
  /// **'R Header'**
  String get rHeader;

  /// No description provided for @pHeader.
  ///
  /// In en, this message translates to:
  /// **'P Header'**
  String get pHeader;

  /// No description provided for @careerHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Career History'**
  String get careerHistoryTitle;

  /// No description provided for @yearHeader.
  ///
  /// In en, this message translates to:
  /// **'Year Header'**
  String get yearHeader;

  /// No description provided for @teamHeader.
  ///
  /// In en, this message translates to:
  /// **'Team Header'**
  String get teamHeader;

  /// No description provided for @seriesHeader.
  ///
  /// In en, this message translates to:
  /// **'Series Header'**
  String get seriesHeader;

  /// No description provided for @wHeader.
  ///
  /// In en, this message translates to:
  /// **'W Header'**
  String get wHeader;

  /// No description provided for @historyIndividual.
  ///
  /// In en, this message translates to:
  /// **'History Individual'**
  String get historyIndividual;

  /// No description provided for @noDataAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No Data Available Yet'**
  String get noDataAvailableYet;

  /// No description provided for @historyLowerDivision.
  ///
  /// In en, this message translates to:
  /// **'History Lower Division'**
  String get historyLowerDivision;

  /// No description provided for @historyChampionBadge.
  ///
  /// In en, this message translates to:
  /// **'CHAMPION'**
  String get historyChampionBadge;

  /// No description provided for @statBraking.
  ///
  /// In en, this message translates to:
  /// **'Braking'**
  String get statBraking;

  /// No description provided for @statCornering.
  ///
  /// In en, this message translates to:
  /// **'Cornering'**
  String get statCornering;

  /// No description provided for @statSmoothness.
  ///
  /// In en, this message translates to:
  /// **'Smoothness'**
  String get statSmoothness;

  /// No description provided for @statOvertaking.
  ///
  /// In en, this message translates to:
  /// **'Overtaking'**
  String get statOvertaking;

  /// No description provided for @statConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get statConsistency;

  /// No description provided for @statAdaptability.
  ///
  /// In en, this message translates to:
  /// **'Adaptability'**
  String get statAdaptability;

  /// No description provided for @statFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get statFitness;

  /// No description provided for @statFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get statFeedback;

  /// No description provided for @statFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get statFocus;

  /// No description provided for @statMorale.
  ///
  /// In en, this message translates to:
  /// **'Morale'**
  String get statMorale;

  /// No description provided for @statMarketability.
  ///
  /// In en, this message translates to:
  /// **'Marketability'**
  String get statMarketability;

  /// No description provided for @roleMain.
  ///
  /// In en, this message translates to:
  /// **'Role Main'**
  String get roleMain;

  /// No description provided for @roleSecond.
  ///
  /// In en, this message translates to:
  /// **'Role Second'**
  String get roleSecond;

  /// No description provided for @roleEqual.
  ///
  /// In en, this message translates to:
  /// **'Role Equal'**
  String get roleEqual;

  /// No description provided for @roleReserve.
  ///
  /// In en, this message translates to:
  /// **'Role Reserve'**
  String get roleReserve;

  /// No description provided for @engineeringDescription.
  ///
  /// In en, this message translates to:
  /// **'Engineering Description'**
  String get engineeringDescription;

  /// No description provided for @budgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetLabel;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get currencySymbol;

  /// No description provided for @millionsSuffix.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get millionsSuffix;

  /// No description provided for @upgradeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Limit Reached'**
  String get upgradeLimitReached;

  /// No description provided for @carLabelA.
  ///
  /// In en, this message translates to:
  /// **'Car Label A'**
  String get carLabelA;

  /// No description provided for @noDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'No Driver Assigned'**
  String get noDriverAssigned;

  /// No description provided for @carLabelB.
  ///
  /// In en, this message translates to:
  /// **'Car Label B'**
  String get carLabelB;

  /// No description provided for @carPerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Car Performance Title {arg0}'**
  String carPerformanceTitle(String arg0);

  /// No description provided for @aero.
  ///
  /// In en, this message translates to:
  /// **'Aero'**
  String get aero;

  /// No description provided for @engine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get engine;

  /// No description provided for @chassisPart.
  ///
  /// In en, this message translates to:
  /// **'Chassis Part'**
  String get chassisPart;

  /// No description provided for @reliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get reliability;

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost Label {arg0} {arg1}'**
  String costLabel(String arg0, String arg1);

  /// No description provided for @upgradeBtn.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeBtn;

  /// No description provided for @managerError.
  ///
  /// In en, this message translates to:
  /// **'Manager Error {arg0}'**
  String managerError(String arg0);

  /// No description provided for @managerProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Manager Profile Not Found'**
  String get managerProfileNotFound;

  /// No description provided for @teamError.
  ///
  /// In en, this message translates to:
  /// **'Team Error {arg0}'**
  String teamError(String arg0);

  /// No description provided for @teamDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Team Data Not Found'**
  String get teamDataNotFound;

  /// No description provided for @seasonError.
  ///
  /// In en, this message translates to:
  /// **'Season Error {arg0}'**
  String seasonError(String arg0);

  /// No description provided for @quickView.
  ///
  /// In en, this message translates to:
  /// **'Quick View'**
  String get quickView;

  /// No description provided for @pressNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'PRESS NEWS'**
  String get pressNewsTitle;

  /// No description provided for @errorLoadingNews.
  ///
  /// In en, this message translates to:
  /// **'Error Loading News'**
  String get errorLoadingNews;

  /// No description provided for @officeNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'OFFICE NEWS'**
  String get officeNewsTitle;

  /// No description provided for @notificationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Notifications Unavailable'**
  String get notificationsUnavailable;

  /// No description provided for @noNewNotifications.
  ///
  /// In en, this message translates to:
  /// **'No New Notifications'**
  String get noNewNotifications;

  /// No description provided for @noNewsFromPaddockYet.
  ///
  /// In en, this message translates to:
  /// **'No News From Paddock Yet'**
  String get noNewsFromPaddockYet;

  /// No description provided for @welcomeBackManager.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, Manager {arg0}'**
  String welcomeBackManager(String arg0);

  /// No description provided for @sessionInProgress.
  ///
  /// In en, this message translates to:
  /// **'Session In Progress'**
  String get sessionInProgress;

  /// No description provided for @timeUntilNextSession.
  ///
  /// In en, this message translates to:
  /// **'Time Until Next Session'**
  String get timeUntilNextSession;

  /// No description provided for @teamBudget.
  ///
  /// In en, this message translates to:
  /// **'Team Budget'**
  String get teamBudget;

  /// No description provided for @deficit.
  ///
  /// In en, this message translates to:
  /// **'Deficit'**
  String get deficit;

  /// No description provided for @surplus.
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get surplus;

  /// No description provided for @estimatedAbbr.
  ///
  /// In en, this message translates to:
  /// **'Estimated Abbr'**
  String get estimatedAbbr;

  /// No description provided for @nextGrandPrix.
  ///
  /// In en, this message translates to:
  /// **'Next Grand Prix'**
  String get nextGrandPrix;

  /// No description provided for @circuitLengthAndLaps.
  ///
  /// In en, this message translates to:
  /// **'Distance: {arg0} km | Laps: {arg1}'**
  String circuitLengthAndLaps(String arg0, String arg1);

  /// No description provided for @paddockOpen.
  ///
  /// In en, this message translates to:
  /// **'Paddock Open'**
  String get paddockOpen;

  /// No description provided for @weekendSetupBtn.
  ///
  /// In en, this message translates to:
  /// **'Weekend Setup'**
  String get weekendSetupBtn;

  /// No description provided for @qualifyingStatus.
  ///
  /// In en, this message translates to:
  /// **'Qualifying'**
  String get qualifyingStatus;

  /// No description provided for @viewQualifyingBtn.
  ///
  /// In en, this message translates to:
  /// **'View Qualifying'**
  String get viewQualifyingBtn;

  /// No description provided for @raceStrategyStatus.
  ///
  /// In en, this message translates to:
  /// **'Race Strategy'**
  String get raceStrategyStatus;

  /// No description provided for @setRaceStrategyBtn.
  ///
  /// In en, this message translates to:
  /// **'Set Race Strategy'**
  String get setRaceStrategyBtn;

  /// No description provided for @raceWeekendStatus.
  ///
  /// In en, this message translates to:
  /// **'Race'**
  String get raceWeekendStatus;

  /// No description provided for @goToRaceBtn.
  ///
  /// In en, this message translates to:
  /// **'Go To Race'**
  String get goToRaceBtn;

  /// No description provided for @raceFinishedStatus.
  ///
  /// In en, this message translates to:
  /// **'Race Finished Status'**
  String get raceFinishedStatus;

  /// No description provided for @viewResultsBtn.
  ///
  /// In en, this message translates to:
  /// **'View Results'**
  String get viewResultsBtn;

  /// No description provided for @circuitIntelTitle.
  ///
  /// In en, this message translates to:
  /// **'Circuit Intel'**
  String get circuitIntelTitle;

  /// No description provided for @aeroIntel.
  ///
  /// In en, this message translates to:
  /// **'Aero Intel'**
  String get aeroIntel;

  /// No description provided for @highIntel.
  ///
  /// In en, this message translates to:
  /// **'High Intel'**
  String get highIntel;

  /// No description provided for @powerIntel.
  ///
  /// In en, this message translates to:
  /// **'Power Intel'**
  String get powerIntel;

  /// No description provided for @speedIntel.
  ///
  /// In en, this message translates to:
  /// **'Speed Intel'**
  String get speedIntel;

  /// No description provided for @tyreIntel.
  ///
  /// In en, this message translates to:
  /// **'Tyre Intel'**
  String get tyreIntel;

  /// No description provided for @onLive.
  ///
  /// In en, this message translates to:
  /// **'On Live'**
  String get onLive;

  /// No description provided for @offLive.
  ///
  /// In en, this message translates to:
  /// **'Off Live'**
  String get offLive;

  /// No description provided for @preRaceChecklist.
  ///
  /// In en, this message translates to:
  /// **'Pre-Race Checklist'**
  String get preRaceChecklist;

  /// No description provided for @practiceProgram.
  ///
  /// In en, this message translates to:
  /// **'Practice Program'**
  String get practiceProgram;

  /// No description provided for @completedLapsOf.
  ///
  /// In en, this message translates to:
  /// **'Laps: {arg0} / {arg1}'**
  String completedLapsOf(String arg0, String arg1);

  /// No description provided for @qualifyingSetup.
  ///
  /// In en, this message translates to:
  /// **'Qualifying Setup'**
  String get qualifyingSetup;

  /// No description provided for @readyStatus.
  ///
  /// In en, this message translates to:
  /// **'Ready Status'**
  String get readyStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending Status'**
  String get pendingStatus;

  /// No description provided for @hqDescription.
  ///
  /// In en, this message translates to:
  /// **'Hq Description'**
  String get hqDescription;

  /// No description provided for @facilitiesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Facilities Section'**
  String get facilitiesSectionTitle;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level Label {arg0}'**
  String levelLabel(String arg0);

  /// No description provided for @nextLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Level'**
  String get nextLevelLabel;

  /// No description provided for @maintCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Maint Cost'**
  String get maintCostLabel;

  /// No description provided for @bonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get bonusLabel;

  /// No description provided for @buyBtn.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyBtn;

  /// No description provided for @comingSoonBanner.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon Banner'**
  String get comingSoonBanner;

  /// No description provided for @facilityImproved.
  ///
  /// In en, this message translates to:
  /// **'Facility Improved {arg0}'**
  String facilityImproved(String arg0);

  /// No description provided for @signContractError.
  ///
  /// In en, this message translates to:
  /// **'Sign Contract'**
  String get signContractError;

  /// No description provided for @confirmResetWorldTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reset World'**
  String get confirmResetWorldTitle;

  /// No description provided for @confirmResetWorldDesc.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reset World'**
  String get confirmResetWorldDesc;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reset Successful!'**
  String get resetSuccess;

  /// No description provided for @resetBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetBtn;

  /// No description provided for @jobMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Market'**
  String get jobMarketTitle;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @signContract.
  ///
  /// In en, this message translates to:
  /// **'Sign Contract'**
  String get signContract;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navHQ.
  ///
  /// In en, this message translates to:
  /// **'HQ'**
  String get navHQ;

  /// No description provided for @navTeamOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get navTeamOffice;

  /// No description provided for @navGarage.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get navGarage;

  /// No description provided for @navYouthAcademy.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get navYouthAcademy;

  /// No description provided for @navRacing.
  ///
  /// In en, this message translates to:
  /// **'Racing'**
  String get navRacing;

  /// No description provided for @navWeekendSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get navWeekendSetup;

  /// No description provided for @navRaceDay.
  ///
  /// In en, this message translates to:
  /// **'Race Day'**
  String get navRaceDay;

  /// No description provided for @navManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get navManagement;

  /// No description provided for @navPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get navPersonal;

  /// No description provided for @navFinances.
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get navFinances;

  /// No description provided for @navSponsors.
  ///
  /// In en, this message translates to:
  /// **'Sponsors'**
  String get navSponsors;

  /// No description provided for @navSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get navSeason;

  /// No description provided for @navStandings.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get navStandings;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountInfo;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @lastSession.
  ///
  /// In en, this message translates to:
  /// **'Last Session'**
  String get lastSession;

  /// No description provided for @adminBtn.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminBtn;

  /// No description provided for @accountBtn.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountBtn;

  /// No description provided for @logOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out Confirm'**
  String get logOutConfirmTitle;

  /// No description provided for @logOutConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Log Out Confirm'**
  String get logOutConfirmDesc;

  /// No description provided for @navMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get navMarket;

  /// No description provided for @personalManagement.
  ///
  /// In en, this message translates to:
  /// **'Personal Management'**
  String get personalManagement;

  /// No description provided for @driversTitle.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get driversTitle;

  /// No description provided for @fitnessTrainerTitle.
  ///
  /// In en, this message translates to:
  /// **'Fitness Trainer'**
  String get fitnessTrainerTitle;

  /// No description provided for @chiefEngineerTitle.
  ///
  /// In en, this message translates to:
  /// **'Chief Engineer'**
  String get chiefEngineerTitle;

  /// No description provided for @hrManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Hr Manager'**
  String get hrManagerTitle;

  /// No description provided for @marketingManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketing Manager'**
  String get marketingManagerTitle;

  /// No description provided for @currentBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalanceTitle;

  /// No description provided for @recentMovementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Movements'**
  String get recentMovementsTitle;

  /// No description provided for @noFinancialActivity.
  ///
  /// In en, this message translates to:
  /// **'No Financial Activity'**
  String get noFinancialActivity;

  /// No description provided for @selectCarPartToManage.
  ///
  /// In en, this message translates to:
  /// **'Select Car Part To Manage'**
  String get selectCarPartToManage;

  /// No description provided for @activeContractTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Contract Title {arg0}'**
  String activeContractTitle(String arg0);

  /// No description provided for @weeklyPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly Pay'**
  String get weeklyPayLabel;

  /// No description provided for @racesLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'Races Left'**
  String get racesLeftLabel;

  /// No description provided for @availableOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Offers Title {arg0}'**
  String availableOffersTitle(String arg0);

  /// No description provided for @rearWingPart.
  ///
  /// In en, this message translates to:
  /// **'Rear Wing Part'**
  String get rearWingPart;

  /// No description provided for @sidepodLPart.
  ///
  /// In en, this message translates to:
  /// **'Sidepod L Part'**
  String get sidepodLPart;

  /// No description provided for @sidepodRPart.
  ///
  /// In en, this message translates to:
  /// **'Sidepod R Part'**
  String get sidepodRPart;

  /// No description provided for @haloPart.
  ///
  /// In en, this message translates to:
  /// **'Halo Part'**
  String get haloPart;

  /// No description provided for @frontWingPart.
  ///
  /// In en, this message translates to:
  /// **'Front Wing Part'**
  String get frontWingPart;

  /// No description provided for @nosePart.
  ///
  /// In en, this message translates to:
  /// **'Nose Part'**
  String get nosePart;

  /// No description provided for @manageBtn.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageBtn;

  /// No description provided for @selectSponsorBtn.
  ///
  /// In en, this message translates to:
  /// **'Select Sponsor'**
  String get selectSponsorBtn;

  /// No description provided for @negotiationRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Negotiation Rules'**
  String get negotiationRulesTitle;

  /// No description provided for @negotiationRulesDesc.
  ///
  /// In en, this message translates to:
  /// **'Negotiation Rules'**
  String get negotiationRulesDesc;

  /// No description provided for @signingBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Signing Bonus'**
  String get signingBonusLabel;

  /// No description provided for @weeklyPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly Payment'**
  String get weeklyPaymentLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @durationRaces.
  ///
  /// In en, this message translates to:
  /// **'Duration Races {arg0}'**
  String durationRaces(String arg0);

  /// No description provided for @objectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Objective'**
  String get objectiveLabel;

  /// No description provided for @suspendedStatus.
  ///
  /// In en, this message translates to:
  /// **'Suspended Status'**
  String get suspendedStatus;

  /// No description provided for @chooseTacticLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose Tactic Label {arg0}'**
  String chooseTacticLabel(String arg0);

  /// No description provided for @persuasiveTactic.
  ///
  /// In en, this message translates to:
  /// **'Persuasive Tactic'**
  String get persuasiveTactic;

  /// No description provided for @negotiatorTactic.
  ///
  /// In en, this message translates to:
  /// **'Negotiator Tactic'**
  String get negotiatorTactic;

  /// No description provided for @collaborativeTactic.
  ///
  /// In en, this message translates to:
  /// **'Collaborative Tactic'**
  String get collaborativeTactic;

  /// No description provided for @availableSponsorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Sponsors'**
  String get availableSponsorsTitle;

  /// No description provided for @roleExDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Role Ex Driver'**
  String get roleExDriverTitle;

  /// No description provided for @roleExDriverDesc.
  ///
  /// In en, this message translates to:
  /// **'Role Ex Driver'**
  String get roleExDriverDesc;

  /// No description provided for @roleBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Role Business'**
  String get roleBusinessTitle;

  /// No description provided for @roleBusinessDesc.
  ///
  /// In en, this message translates to:
  /// **'Role Business'**
  String get roleBusinessDesc;

  /// No description provided for @roleBureaucratTitle.
  ///
  /// In en, this message translates to:
  /// **'Role Bureaucrat'**
  String get roleBureaucratTitle;

  /// No description provided for @roleBureaucratDesc.
  ///
  /// In en, this message translates to:
  /// **'Role Bureaucrat'**
  String get roleBureaucratDesc;

  /// No description provided for @roleEngineerTitle.
  ///
  /// In en, this message translates to:
  /// **'Role Engineer'**
  String get roleEngineerTitle;

  /// No description provided for @roleEngineerDesc.
  ///
  /// In en, this message translates to:
  /// **'Role Engineer'**
  String get roleEngineerDesc;

  /// No description provided for @createManagerProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Manager Profile'**
  String get createManagerProfile;

  /// No description provided for @personalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfoTitle;

  /// No description provided for @selectCountryError.
  ///
  /// In en, this message translates to:
  /// **'Please select a country'**
  String get selectCountryError;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @maleGender.
  ///
  /// In en, this message translates to:
  /// **'Male Gender'**
  String get maleGender;

  /// No description provided for @femaleGender.
  ///
  /// In en, this message translates to:
  /// **'Female Gender'**
  String get femaleGender;

  /// No description provided for @nonBinaryGender.
  ///
  /// In en, this message translates to:
  /// **'Non Binary Gender'**
  String get nonBinaryGender;

  /// No description provided for @selectGenderError.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender'**
  String get selectGenderError;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLabel;

  /// No description provided for @monthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthLabel;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// No description provided for @selectBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Background'**
  String get selectBackgroundTitle;

  /// No description provided for @createManagerDesc.
  ///
  /// In en, this message translates to:
  /// **'Create Manager'**
  String get createManagerDesc;

  /// No description provided for @establishCareerBtn.
  ///
  /// In en, this message translates to:
  /// **'Establish Career'**
  String get establishCareerBtn;

  /// No description provided for @requiredError.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredError;

  /// No description provided for @advantagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Advantages'**
  String get advantagesTitle;

  /// No description provided for @disadvantagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Disadvantages'**
  String get disadvantagesTitle;

  /// No description provided for @adminAccess.
  ///
  /// In en, this message translates to:
  /// **'Admin Access'**
  String get adminAccess;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter Pin'**
  String get enterPin;

  /// No description provided for @verifyBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyBtn;

  /// No description provided for @nukeWorldTitle.
  ///
  /// In en, this message translates to:
  /// **'Nuke World'**
  String get nukeWorldTitle;

  /// No description provided for @nukeWorldDesc.
  ///
  /// In en, this message translates to:
  /// **'Nuke World'**
  String get nukeWorldDesc;

  /// No description provided for @nukeWorldSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database Reset Successful!'**
  String get nukeWorldSuccess;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error Prefix {arg0}'**
  String errorPrefix(String arg0);

  /// No description provided for @executeNuke.
  ///
  /// In en, this message translates to:
  /// **'Execute Nuke'**
  String get executeNuke;

  /// No description provided for @ftgRacing.
  ///
  /// In en, this message translates to:
  /// **'Ftg Racing'**
  String get ftgRacing;

  /// No description provided for @manager2026.
  ///
  /// In en, this message translates to:
  /// **'Manager2026'**
  String get manager2026;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign In With Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign In With Email'**
  String get signInWithEmail;

  /// No description provided for @devQuickStart.
  ///
  /// In en, this message translates to:
  /// **'Dev Quick Start'**
  String get devQuickStart;

  /// No description provided for @signingWithTeam.
  ///
  /// In en, this message translates to:
  /// **'Signing With Team {arg0}'**
  String signingWithTeam(String arg0);

  /// No description provided for @applicationFailed.
  ///
  /// In en, this message translates to:
  /// **'Application Failed {arg0}'**
  String applicationFailed(String arg0);

  /// No description provided for @selectTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Team'**
  String get selectTeamTitle;

  /// No description provided for @selectTeamDesc.
  ///
  /// In en, this message translates to:
  /// **'Select Team'**
  String get selectTeamDesc;

  /// No description provided for @worldChampionship.
  ///
  /// In en, this message translates to:
  /// **'World Championship'**
  String get worldChampionship;

  /// No description provided for @secondSeries.
  ///
  /// In en, this message translates to:
  /// **'Second Series'**
  String get secondSeries;

  /// No description provided for @noTeamsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Teams Available'**
  String get noTeamsAvailable;

  /// No description provided for @recommendedTag.
  ///
  /// In en, this message translates to:
  /// **'Recommended Tag'**
  String get recommendedTag;

  /// No description provided for @unlockLeagueDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock League'**
  String get unlockLeagueDesc;

  /// No description provided for @mainDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Main Driver'**
  String get mainDriverLabel;

  /// No description provided for @secondaryDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary Driver'**
  String get secondaryDriverLabel;

  /// No description provided for @selectTeamBtn.
  ///
  /// In en, this message translates to:
  /// **'Select Team'**
  String get selectTeamBtn;

  /// No description provided for @selectedTag.
  ///
  /// In en, this message translates to:
  /// **'Selected Tag'**
  String get selectedTag;

  /// No description provided for @standingsConstructorTitle.
  ///
  /// In en, this message translates to:
  /// **'Constructors'**
  String get standingsConstructorTitle;

  /// No description provided for @raceResults.
  ///
  /// In en, this message translates to:
  /// **'Race Results'**
  String get raceResults;

  /// No description provided for @standingsTeam.
  ///
  /// In en, this message translates to:
  /// **'Standings Team'**
  String get standingsTeam;

  /// No description provided for @standingsPoints.
  ///
  /// In en, this message translates to:
  /// **'Standings Points'**
  String get standingsPoints;

  /// No description provided for @insufficientBudgetForNameChange.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Budget For Name Change'**
  String get insufficientBudgetForNameChange;

  /// No description provided for @teamRenamedFree.
  ///
  /// In en, this message translates to:
  /// **'Team Renamed Free {arg0}'**
  String teamRenamedFree(String arg0);

  /// No description provided for @teamRenamedPaid.
  ///
  /// In en, this message translates to:
  /// **'Team Renamed Paid {arg0}'**
  String teamRenamedPaid(String arg0);

  /// No description provided for @teamIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Identity'**
  String get teamIdentityTitle;

  /// No description provided for @teamNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamNameLabel;

  /// No description provided for @confirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmBtn;

  /// No description provided for @regulationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Regulations'**
  String get regulationsTitle;

  /// No description provided for @firstChangeUsed.
  ///
  /// In en, this message translates to:
  /// **'First Change Used'**
  String get firstChangeUsed;

  /// No description provided for @firstChangeFree.
  ///
  /// In en, this message translates to:
  /// **'First Change Free'**
  String get firstChangeFree;

  /// No description provided for @nextChangesCost.
  ///
  /// In en, this message translates to:
  /// **'Next Changes Cost'**
  String get nextChangesCost;

  /// No description provided for @renamedTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Renamed Times Label {arg0}'**
  String renamedTimesLabel(String arg0);

  /// No description provided for @teamCareerStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Career Stats'**
  String get teamCareerStatsTitle;

  /// No description provided for @combinedDriversLabel.
  ///
  /// In en, this message translates to:
  /// **'Combined Drivers'**
  String get combinedDriversLabel;

  /// No description provided for @driverBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Breakdown'**
  String get driverBreakdownTitle;

  /// No description provided for @driverHeader.
  ///
  /// In en, this message translates to:
  /// **'Driver Header'**
  String get driverHeader;

  /// No description provided for @teamLiveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Livery'**
  String get teamLiveryTitle;

  /// No description provided for @selectYourColors.
  ///
  /// In en, this message translates to:
  /// **'Select Your Colors'**
  String get selectYourColors;

  /// No description provided for @liveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Livery Description'**
  String get liveryDescription;

  /// No description provided for @managerProfileSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Manager Profile Section'**
  String get managerProfileSectionTitle;

  /// No description provided for @circuitMexico.
  ///
  /// In en, this message translates to:
  /// **'Circuit Mexico'**
  String get circuitMexico;

  /// No description provided for @circuitInterlagos.
  ///
  /// In en, this message translates to:
  /// **'Circuit Interlagos'**
  String get circuitInterlagos;

  /// No description provided for @circuitMiami.
  ///
  /// In en, this message translates to:
  /// **'Circuit Miami'**
  String get circuitMiami;

  /// No description provided for @circuitSanPabloStreet.
  ///
  /// In en, this message translates to:
  /// **'Circuit San Pablo Street'**
  String get circuitSanPabloStreet;

  /// No description provided for @circuitIndianapolis.
  ///
  /// In en, this message translates to:
  /// **'Circuit Indianapolis'**
  String get circuitIndianapolis;

  /// No description provided for @circuitMontreal.
  ///
  /// In en, this message translates to:
  /// **'Circuit Montreal'**
  String get circuitMontreal;

  /// No description provided for @circuitVegas.
  ///
  /// In en, this message translates to:
  /// **'Circuit Vegas'**
  String get circuitVegas;

  /// No description provided for @circuitTexas.
  ///
  /// In en, this message translates to:
  /// **'Circuit Texas'**
  String get circuitTexas;

  /// No description provided for @circuitBuenosAires.
  ///
  /// In en, this message translates to:
  /// **'Circuit Buenos Aires'**
  String get circuitBuenosAires;

  /// No description provided for @statusLivingLegend.
  ///
  /// In en, this message translates to:
  /// **'Status Living Legend'**
  String get statusLivingLegend;

  /// No description provided for @statusEraDominator.
  ///
  /// In en, this message translates to:
  /// **'Status Era Dominator'**
  String get statusEraDominator;

  /// No description provided for @statusTheHeir.
  ///
  /// In en, this message translates to:
  /// **'Status The Heir'**
  String get statusTheHeir;

  /// No description provided for @statusTheHeiress.
  ///
  /// In en, this message translates to:
  /// **'Status The Heiress'**
  String get statusTheHeiress;

  /// No description provided for @statusEliteVeteran.
  ///
  /// In en, this message translates to:
  /// **'Status Elite Veteran'**
  String get statusEliteVeteran;

  /// No description provided for @statusLastDance.
  ///
  /// In en, this message translates to:
  /// **'Status Last Dance'**
  String get statusLastDance;

  /// No description provided for @statusSolidSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Status Solid Specialist'**
  String get statusSolidSpecialist;

  /// No description provided for @statusYoungWonder.
  ///
  /// In en, this message translates to:
  /// **'Status Young Wonder'**
  String get statusYoungWonder;

  /// No description provided for @statusRisingStar.
  ///
  /// In en, this message translates to:
  /// **'Status Rising Star'**
  String get statusRisingStar;

  /// No description provided for @statusStuckPromise.
  ///
  /// In en, this message translates to:
  /// **'Status Stuck Promise'**
  String get statusStuckPromise;

  /// No description provided for @statusJourneyman.
  ///
  /// In en, this message translates to:
  /// **'Status Journeyman'**
  String get statusJourneyman;

  /// No description provided for @statusJourneywoman.
  ///
  /// In en, this message translates to:
  /// **'Status Journeywoman'**
  String get statusJourneywoman;

  /// No description provided for @statusUnsungDriver.
  ///
  /// In en, this message translates to:
  /// **'Status Unsung Driver'**
  String get statusUnsungDriver;

  /// No description provided for @statusMidfieldSpark.
  ///
  /// In en, this message translates to:
  /// **'Status Midfield Spark'**
  String get statusMidfieldSpark;

  /// No description provided for @statusPastGlory.
  ///
  /// In en, this message translates to:
  /// **'Status Past Glory'**
  String get statusPastGlory;

  /// No description provided for @statusGridFiller.
  ///
  /// In en, this message translates to:
  /// **'Status Grid Filler'**
  String get statusGridFiller;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status Unknown'**
  String get statusUnknown;

  /// No description provided for @descLivingLegend.
  ///
  /// In en, this message translates to:
  /// **'Desc Living Legend'**
  String get descLivingLegend;

  /// No description provided for @descEraDominator.
  ///
  /// In en, this message translates to:
  /// **'Desc Era Dominator'**
  String get descEraDominator;

  /// No description provided for @descTheHeir.
  ///
  /// In en, this message translates to:
  /// **'Desc The Heir'**
  String get descTheHeir;

  /// No description provided for @descEliteVeteran.
  ///
  /// In en, this message translates to:
  /// **'Desc Elite Veteran'**
  String get descEliteVeteran;

  /// No description provided for @descLastDance.
  ///
  /// In en, this message translates to:
  /// **'Desc Last Dance'**
  String get descLastDance;

  /// No description provided for @descSolidSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Desc Solid Specialist'**
  String get descSolidSpecialist;

  /// No description provided for @descYoungWonder.
  ///
  /// In en, this message translates to:
  /// **'Desc Young Wonder'**
  String get descYoungWonder;

  /// No description provided for @descRisingStar.
  ///
  /// In en, this message translates to:
  /// **'Desc Rising Star'**
  String get descRisingStar;

  /// No description provided for @descStuckPromise.
  ///
  /// In en, this message translates to:
  /// **'Desc Stuck Promise'**
  String get descStuckPromise;

  /// No description provided for @descJourneyman.
  ///
  /// In en, this message translates to:
  /// **'Desc Journeyman'**
  String get descJourneyman;

  /// No description provided for @descUnsungDriver.
  ///
  /// In en, this message translates to:
  /// **'Desc Unsung Driver'**
  String get descUnsungDriver;

  /// No description provided for @descMidfieldSpark.
  ///
  /// In en, this message translates to:
  /// **'Desc Midfield Spark'**
  String get descMidfieldSpark;

  /// No description provided for @descPastGlory.
  ///
  /// In en, this message translates to:
  /// **'Desc Past Glory'**
  String get descPastGlory;

  /// No description provided for @descGridFiller.
  ///
  /// In en, this message translates to:
  /// **'Desc Grid Filler'**
  String get descGridFiller;

  /// No description provided for @descUnknown.
  ///
  /// In en, this message translates to:
  /// **'Desc Unknown'**
  String get descUnknown;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Profile {arg0}'**
  String errorLoadingProfile(String arg0);

  /// No description provided for @powerStatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Power Stats'**
  String get powerStatsLabel;

  /// No description provided for @aeroStatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Aero Stats'**
  String get aeroStatsLabel;

  /// No description provided for @handlingStatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Handling Stats'**
  String get handlingStatsLabel;

  /// No description provided for @reliabilityStatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reliability Stats'**
  String get reliabilityStatsLabel;

  /// No description provided for @failedToLoadLiveries.
  ///
  /// In en, this message translates to:
  /// **'Failed To Load Liveries'**
  String get failedToLoadLiveries;

  /// No description provided for @liveryIndexLabel.
  ///
  /// In en, this message translates to:
  /// **'Livery Index Label {arg0} {arg1}'**
  String liveryIndexLabel(String arg0, String arg1);

  /// No description provided for @loadingPhrase1.
  ///
  /// In en, this message translates to:
  /// **'Warming up engines...'**
  String get loadingPhrase1;

  /// No description provided for @loadingPhrase2.
  ///
  /// In en, this message translates to:
  /// **'Analyzing telemetry data...'**
  String get loadingPhrase2;

  /// No description provided for @loadingPhrase3.
  ///
  /// In en, this message translates to:
  /// **'Adjusting aero balance...'**
  String get loadingPhrase3;

  /// No description provided for @loadingPhrase4.
  ///
  /// In en, this message translates to:
  /// **'Preparing tyre sets...'**
  String get loadingPhrase4;

  /// No description provided for @loadingPhrase5.
  ///
  /// In en, this message translates to:
  /// **'Checking fuel levels...'**
  String get loadingPhrase5;

  /// No description provided for @loadingPhrase6.
  ///
  /// In en, this message translates to:
  /// **'Syncing with pit wall...'**
  String get loadingPhrase6;

  /// No description provided for @loadingPhrase7.
  ///
  /// In en, this message translates to:
  /// **'Optimizing engine map...'**
  String get loadingPhrase7;

  /// No description provided for @loadingPhrase8.
  ///
  /// In en, this message translates to:
  /// **'Awaiting green flag...'**
  String get loadingPhrase8;

  /// No description provided for @minsAgo.
  ///
  /// In en, this message translates to:
  /// **'Mins Ago {arg0}'**
  String minsAgo(int arg0);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Hours Ago {arg0}'**
  String hoursAgo(int arg0);

  /// No description provided for @pressNewsManagerJoin.
  ///
  /// In en, this message translates to:
  /// **'Press News Manager Join {arg0} {arg1} {arg2} {arg3} {arg4} {arg5} {arg6}'**
  String pressNewsManagerJoin(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
    String arg4,
    String arg5,
    String arg6,
  );

  /// No description provided for @motorsportDaily.
  ///
  /// In en, this message translates to:
  /// **'Motorsport Daily'**
  String get motorsportDaily;

  /// No description provided for @readFullArticle.
  ///
  /// In en, this message translates to:
  /// **'Read Full Article'**
  String get readFullArticle;

  /// No description provided for @closeBtn.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeBtn;

  /// No description provided for @navOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get navOffice;

  /// No description provided for @objFinishTop3.
  ///
  /// In en, this message translates to:
  /// **'Finish Top 3'**
  String get objFinishTop3;

  /// No description provided for @objBothInPoints.
  ///
  /// In en, this message translates to:
  /// **'Both cars in points'**
  String get objBothInPoints;

  /// No description provided for @objRaceWin.
  ///
  /// In en, this message translates to:
  /// **'Race Win'**
  String get objRaceWin;

  /// No description provided for @objFinishTop10.
  ///
  /// In en, this message translates to:
  /// **'Finish Top 10'**
  String get objFinishTop10;

  /// No description provided for @objFastestLap.
  ///
  /// In en, this message translates to:
  /// **'Fastest Lap'**
  String get objFastestLap;

  /// No description provided for @objFinishRace.
  ///
  /// In en, this message translates to:
  /// **'Finish the race'**
  String get objFinishRace;

  /// No description provided for @objImproveGrid.
  ///
  /// In en, this message translates to:
  /// **'Improve Grid Position'**
  String get objImproveGrid;

  /// No description provided for @objOvertake3Cars.
  ///
  /// In en, this message translates to:
  /// **'Overtake 3 cars'**
  String get objOvertake3Cars;
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
