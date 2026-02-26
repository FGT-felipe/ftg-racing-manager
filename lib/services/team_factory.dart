import 'dart:math';
import '../models/core_models.dart';
import '../models/domain/domain_models.dart';

/// Fábrica para generar equipos bot.
///
/// Genera nombres temáticos y configuraciones basadas en el país.
class TeamFactory {
  /// Generador de números aleatorios
  final Random _random;

  /// Contador para IDs únicos
  static int _globalCounter = 0;

  TeamFactory({Random? random}) : _random = random ?? Random();

  /// Genera un equipo bot
  ///
  /// [forcedCountry]: Si se provee, el equipo será de este país.
  Team generateBotTeam({Country? forcedCountry}) {
    final country = forcedCountry ?? _pickRandomCountry();

    return Team(
      id: _generateId(country),
      name: _generateTeamName(),
      managerId: null, // Bot team sin manager
      isBot: true,
      budget: 2500000,
      points: 0,
      races: 0,
      wins: 0,
      podiums: 0,
      poles: 0,
      carStats: _generateCarStats(),
      weekStatus: _generateWeekStatus(),
      sponsors: const {}, // Sin sponsors iniciales
    );
  }

  /// Genera un ID único para el equipo
  String _generateId(Country country) {
    return 'team_${country.code.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}_${_globalCounter++}';
  }

  /// Genera un nombre de equipo combinando cualidades, colores y sustantivos
  String _generateTeamName() {
    final pattern = _random.nextInt(3);

    final quality = _qualities[_random.nextInt(_qualities.length)];
    final color = _colors[_random.nextInt(_colors.length)];
    final noun = _nouns[_random.nextInt(_nouns.length)];

    switch (pattern) {
      case 0:
        return '$quality $color';
      case 1:
        return '$color $noun';
      case 2:
      default:
        return '$quality $noun';
    }
  }

  /// Pick a random country for team thematic (Keeping this if needed, but not used for names anymore)
  Country _pickRandomCountry() {
    final countryList = [
      Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷'),
      Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷'),
      Country(code: 'CO', name: 'Colombia', flagEmoji: '🇨🇴'),
      Country(code: 'MX', name: 'México', flagEmoji: '🇲🇽'),
      Country(code: 'UY', name: 'Uruguay', flagEmoji: '🇺🇾'),
      Country(code: 'CL', name: 'Chile', flagEmoji: '🇨🇱'),
    ];
    return countryList[_random.nextInt(countryList.length)];
  }

  /// Genera stats iniciales del auto (1-20 en cada categoría)
  Map<String, Map<String, int>> _generateCarStats() {
    final stats = {'aero': 1, 'powertrain': 1, 'chassis': 1, 'reliability': 1};
    return {'0': stats, '1': Map<String, int>.from(stats)};
  }

  /// Genera el estado semanal inicial del equipo
  Map<String, dynamic> _generateWeekStatus() {
    return {
      'practiceCompleted': false,
      'strategySet': false,
      'sponsorReviewed': false,
    };
  }

  static const List<String> _qualities = [
    'Rapid',
    'Swift',
    'Dynamic',
    'Furious',
    'Apex',
    'Neon',
    'Turbo',
    'Quantum',
    'Cosmic',
    'Savage',
    'Iron',
    'Royal',
    'Shadow',
    'Lightning',
    'Extreme',
    'Ultimate',
    'Prime',
    'Elite',
    'Alpha',
    'Omega',
    'Phantom',
  ];

  static const List<String> _colors = [
    'Red',
    'Blue',
    'Green',
    'Black',
    'White',
    'Silver',
    'Golden',
    'Crimson',
    'Cobalt',
    'Sapphire',
    'Ruby',
    'Emerald',
    'Onyx',
    'Platinum',
    'Cyan',
    'Magenta',
    'Violet',
    'Scarlet',
    'Amber',
    'Jade',
  ];

  static const List<String> _nouns = [
    'Panthers',
    'Predators',
    'Wolves',
    'Eagles',
    'Falcons',
    'Tigers',
    'Lions',
    'Dragons',
    'Vipers',
    'Cobras',
    'Titans',
    'Arrows',
    'Meteors',
    'Strikers',
    'Storm',
    'Force',
    'Velocity',
    'Racing',
    'Motorsports',
    'Syndicate',
    'Knights',
    'Spartans',
    'Jets',
    'Rockets',
    'Machines',
  ];
}
