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
      name: _generateTeamName(country),
      managerId: null, // Bot team sin manager
      isBot: true,
      budget: 5000000,
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

  /// Genera un nombre de equipo temático del país
  String _generateTeamName(Country country) {
    final prefixes = _teamPrefixesByCountry[country.code] ?? _defaultPrefixes;
    final suffixes = _teamSuffixesByCountry[country.code] ?? _defaultSuffixes;

    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final suffix = suffixes[_random.nextInt(suffixes.length)];

    return '$prefix $suffix';
  }

  /// Pick a random country for team thematic
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

  /// Prefijos de nombres de equipos por país
  static const Map<String, List<String>> _teamPrefixesByCountry = {
    'BR': [
      'Escuderia',
      'Racing Team',
      'Motorsport',
      'Fórmula',
      'Sao Paulo',
      'Rio',
      'Interlagos',
      'Copacabana',
    ],
    'AR': [
      'Furia',
      'Pampas',
      'Buenos Aires',
      'Termas',
      'Velocidad',
      'Racing',
      'Gaucho',
      'Tango',
    ],
    'CO': [
      'Cafetera',
      'Esmeralda',
      'Bogotá',
      'Medellín',
      'Antioquia',
      'Racing',
      'Motorsport',
      'Andina',
    ],
    'MX': [
      'Azteca',
      'Nacional',
      'Ciudad de México',
      'Guadalajara',
      'Hermanos Rodríguez',
      'Velocidad',
      'Racing',
      'Mariachi',
    ],
    'UY': [
      'Celeste',
      'Oriental',
      'Montevideo',
      'El Pinar',
      'Racing',
      'Motorsport',
      'Charrúa',
      'Rio de la Plata',
    ],
    'CL': [
      'Cóndor',
      'Andino',
      'Santiago',
      'Valparaíso',
      'Racing',
      'Velocidad',
      'Motorsport',
      'Cordillera',
    ],
  };

  /// Sufijos de nombres de equipos por país
  static const Map<String, List<String>> _teamSuffixesByCountry = {
    'BR': ['Racing', 'Motorsport', 'Grand Prix', 'Team', 'F1', 'Velocity'],
    'AR': ['Racing', 'Motorsport', 'Team', 'Velocidad', 'GP', 'Performance'],
    'CO': [
      'Racing',
      'Motorsport',
      'Team',
      'Grand Prix',
      'Speed',
      'Performance',
    ],
    'MX': ['Racing', 'Motorsport', 'Team', 'Velocidad', 'GP', 'Performance'],
    'UY': [
      'Racing',
      'Motorsport',
      'Team',
      'Grand Prix',
      'Speed',
      'Performance',
    ],
    'CL': ['Racing', 'Motorsport', 'Team', 'Velocidad', 'GP', 'Performance'],
  };

  static const List<String> _defaultPrefixes = [
    'Racing',
    'Motorsport',
    'Grand Prix',
    'Velocity',
  ];
  static const List<String> _defaultSuffixes = [
    'Team',
    'Racing',
    'Motorsport',
    'Performance',
  ];
}
