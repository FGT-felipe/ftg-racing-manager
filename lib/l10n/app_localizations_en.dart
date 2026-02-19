// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FireTower Racing';

  @override
  String get jobMarketTitle => 'Open Contracts';

  @override
  String get signContract => 'Sign Contract';

  @override
  String get budgetLabel => 'Budget';

  @override
  String get availableLabel => 'Available';

  @override
  String get takenLabel => 'Taken';

  @override
  String get driversLabel => 'Drivers';

  @override
  String get initializeWorld => 'Initialize Universe';

  @override
  String get currencySymbol => '\$';

  @override
  String get millionsSuffix => 'M';

  @override
  String get signContractError => 'Error signing contract';

  @override
  String get teamDetails => 'Team Details';

  @override
  String get hqTitle => 'Headquarters';

  @override
  String get activeDrivers => 'Active Drivers';

  @override
  String get driverStats => 'Stats';

  @override
  String get speed => 'Speed';

  @override
  String get cornering => 'Cornering';

  @override
  String get nextRace => 'Next Race';

  @override
  String get gpPlaceholder => 'GP Sao Paulo (Coming Soon)';

  @override
  String ageLabel(int age) {
    return '$age yo';
  }

  @override
  String potentialLabel(int value) {
    return 'Pot: $value';
  }

  @override
  String get starMaterial => 'Star Material';

  @override
  String get veteran => 'Veteran';

  @override
  String get rookie => 'Rookie';

  @override
  String get engineeringTitle => 'R&D Lab';

  @override
  String get aero => 'Aerodynamics';

  @override
  String get engine => 'Powertrain';

  @override
  String get reliability => 'Reliability';

  @override
  String get upgradeBtn => 'Develop (+1)';

  @override
  String costLabel(String symbol, String cost) {
    return 'Cost: $symbol$cost';
  }

  @override
  String get insufficientFunds => 'Insufficient Funds';

  @override
  String get simulateBtn => 'Simulate Race';

  @override
  String get raceResults => 'Race Results';

  @override
  String get winner => 'Winner';

  @override
  String get podium => 'Podium';

  @override
  String get financialReport => 'Financial Report';

  @override
  String get earnings => 'Earnings';

  @override
  String get noDriverAssigned => 'No driver assigned';

  @override
  String get engineeringWelcome => 'Welcome to the R&D Lab';

  @override
  String get engineeringDescription =>
      'Improve your cars\' performance by developing specific parts. Remember that you can only perform ONE upgrade each week. Use your resources wisely to stay ahead of the competition!';

  @override
  String get circuitMexico => 'Autodromo Hermanos Rodriguez';

  @override
  String get circuitVegas => 'Las Vegas Strip Circuit';

  @override
  String get circuitInterlagos => 'Autódromo José Carlos Pace';

  @override
  String get circuitMiami => 'Miami International Autodrome';

  @override
  String get circuitSanPabloStreet => 'Sao Paulo Street Circuit';

  @override
  String get circuitIndianapolis => 'Indianapolis Motor Speedway';

  @override
  String get circuitMontreal => 'Circuit Gilles Villeneuve';

  @override
  String get circuitTexas => 'Circuit of the Americas';

  @override
  String get circuitBuenosAires => 'Autódromo Oscar y Juan Gálvez';
}
