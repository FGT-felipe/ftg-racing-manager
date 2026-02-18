import 'dart:math';
import '../models/core_models.dart';
import '../models/domain/domain_models.dart';

/// Fábrica para generar equipos de un país específico.
///
/// Similar a YouthAcademyFactory pero para equipos bot.
/// Genera nombres temáticos y configuraciones basadas en el país.
class TeamFactory {
  /// País del cual esta fábrica genera equipos (inmutable)
  final Country country;

  /// Generador de números aleatorios
  final Random _random;

  /// Contador para IDs únicos por país
  static final Map<String, int> _countryCounters = {};

  TeamFactory(this.country) : _random = Random() {
    _countryCounters.putIfAbsent(country.code, () => 0);
  }

  /// Genera un equipo bot del país
  ///
  /// El equipo tendrá:
  /// - Nombre temático del país
  /// - isBot = true, managerId = null
  /// - Budget: $5M - $15M
  /// - Stats iniciales: 1-20 (para permitir progresión)
  Team generateBotTeam() {
    return Team(
      id: _generateId(),
      name: _generateTeamName(),
      managerId: null, // Bot team sin manager
      isBot: true,
      budget: _generateBudget(),
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
  String _generateId() {
    final countryCode = country.code.toLowerCase();
    final counter = _countryCounters[country.code]!;
    _countryCounters[country.code] = counter + 1;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(999);

    return 'team_${countryCode}_${timestamp}_$randomSuffix';
  }

  /// Genera un nombre de equipo temático del país
  String _generateTeamName() {
    final prefixes = _teamPrefixesByCountry[country.code] ?? _defaultPrefixes;
    final suffixes = _teamSuffixesByCountry[country.code] ?? _defaultSuffixes;

    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final suffix = suffixes[_random.nextInt(suffixes.length)];

    return '$prefix $suffix';
  }

  /// Genera presupuesto inicial ($5M fijo)
  int _generateBudget() {
    return 5000000;
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
