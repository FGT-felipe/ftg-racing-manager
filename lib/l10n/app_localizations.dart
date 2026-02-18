import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'FireTower Racing'**
  String get appTitle;

  /// No description provided for @jobMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Contracts'**
  String get jobMarketTitle;

  /// No description provided for @signContract.
  ///
  /// In en, this message translates to:
  /// **'Sign Contract'**
  String get signContract;

  /// No description provided for @budgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetLabel;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @takenLabel.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get takenLabel;

  /// No description provided for @driversLabel.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get driversLabel;

  /// No description provided for @initializeWorld.
  ///
  /// In en, this message translates to:
  /// **'Initialize Universe'**
  String get initializeWorld;

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

  /// No description provided for @signContractError.
  ///
  /// In en, this message translates to:
  /// **'Error signing contract'**
  String get signContractError;

  /// No description provided for @teamDetails.
  ///
  /// In en, this message translates to:
  /// **'Team Details'**
  String get teamDetails;

  /// No description provided for @hqTitle.
  ///
  /// In en, this message translates to:
  /// **'Headquarters'**
  String get hqTitle;

  /// No description provided for @activeDrivers.
  ///
  /// In en, this message translates to:
  /// **'Active Drivers'**
  String get activeDrivers;

  /// No description provided for @driverStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get driverStats;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @cornering.
  ///
  /// In en, this message translates to:
  /// **'Cornering'**
  String get cornering;

  /// No description provided for @nextRace.
  ///
  /// In en, this message translates to:
  /// **'Next Race'**
  String get nextRace;

  /// No description provided for @gpPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'GP Sao Paulo (Coming Soon)'**
  String get gpPlaceholder;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'{age} yo'**
  String ageLabel(int age);

  /// No description provided for @potentialLabel.
  ///
  /// In en, this message translates to:
  /// **'Pot: {value}'**
  String potentialLabel(int value);

  /// No description provided for @starMaterial.
  ///
  /// In en, this message translates to:
  /// **'Star Material'**
  String get starMaterial;

  /// No description provided for @veteran.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get veteran;

  /// No description provided for @rookie.
  ///
  /// In en, this message translates to:
  /// **'Rookie'**
  String get rookie;

  /// No description provided for @engineeringTitle.
  ///
  /// In en, this message translates to:
  /// **'R&D Lab'**
  String get engineeringTitle;

  /// No description provided for @aero.
  ///
  /// In en, this message translates to:
  /// **'Aerodynamics'**
  String get aero;

  /// No description provided for @engine.
  ///
  /// In en, this message translates to:
  /// **'Powertrain'**
  String get engine;

  /// No description provided for @reliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get reliability;

  /// No description provided for @upgradeBtn.
  ///
  /// In en, this message translates to:
  /// **'Develop (+1)'**
  String get upgradeBtn;

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost: {symbol}{cost}'**
  String costLabel(String symbol, String cost);

  /// No description provided for @insufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Funds'**
  String get insufficientFunds;

  /// No description provided for @simulateBtn.
  ///
  /// In en, this message translates to:
  /// **'Simulate Race'**
  String get simulateBtn;

  /// No description provided for @raceResults.
  ///
  /// In en, this message translates to:
  /// **'Race Results'**
  String get raceResults;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @podium.
  ///
  /// In en, this message translates to:
  /// **'Podium'**
  String get podium;

  /// No description provided for @financialReport.
  ///
  /// In en, this message translates to:
  /// **'Financial Report'**
  String get financialReport;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @noDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'No driver assigned'**
  String get noDriverAssigned;

  /// No description provided for @engineeringWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the R&D Lab'**
  String get engineeringWelcome;

  /// No description provided for @engineeringDescription.
  ///
  /// In en, this message translates to:
  /// **'Improve your cars\' performance by developing specific parts. Remember that you can only perform ONE upgrade per team each week. Use your resources wisely to stay ahead of the competition!'**
  String get engineeringDescription;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
