import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/domain/domain_models.dart';
import 'universe_seeder.dart';

/// Servicio para gestionar el GameUniverse global.
///
/// Singleton que mantiene y persiste el estado del universo del juego
/// en Firestore. Proporciona operaciones para leer, escribir y actualizar
/// el universo completo o ligas específicas.
class UniverseService {
  static final UniverseService _instance = UniverseService._internal();
  factory UniverseService() => _instance;
  UniverseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Documento único del universo en Firestore
  static const String _universeDocId = 'game_universe_v1';

  /// Stream del universo global
  ///
  /// Retorna un stream que emite el GameUniverse cada vez que
  /// hay cambios en Firestore. Útil para UI reactiva.
  Stream<GameUniverse?> getUniverseStream() {
    return _db.collection('universe').doc(_universeDocId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return GameUniverse.fromMap(data);
    });
  }

  /// Obtiene el universo actual (one-shot)
  ///
  /// Retorna el estado actual del GameUniverse desde Firestore.
  /// Retorna null si el universo aún no ha sido inicializado.
  Future<GameUniverse?> getUniverse() async {
    final doc = await _db.collection('universe').doc(_universeDocId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return GameUniverse.fromMap(data);
  }

  /// Guarda el universo completo en Firestore
  ///
  /// Sobrescribe el documento del universo con el estado proporcionado.
  /// Esta operación es atómica.
  Future<void> saveUniverse(GameUniverse universe) async {
    await _db.collection('universe').doc(_universeDocId).set(universe.toMap());
  }

  /// Inicializa el universo si no existe
  ///
  /// Verifica si el universo ya está creado en Firestore.
  /// Si no existe, lo crea usando UniverseSeeder con la configuración
  /// inicial de países y ligas.
  ///
  /// Es seguro llamar múltiples veces - solo crea si no existe.
  Future<void> initializeIfNeeded() async {
    final existing = await getUniverse();
    if (existing != null) return; // Ya existe, no hacer nada

    // Crear universo inicial usando el seeder
    final universe = UniverseSeeder.createInitialUniverse();
    await saveUniverse(universe);
  }

  /// Obtiene una liga específica por código de país
  ///
  /// Ejemplo: getLeagueByCountry('BR') retorna la Liga Brasil
  /// Retorna null si el universo no existe o el país no tiene liga.
  Future<CountryLeague?> getLeagueByCountry(String countryCode) async {
    final universe = await getUniverse();
    return universe?.getLeagueByCountry(countryCode);
  }

  /// Actualiza una liga específica en el universo
  ///
  /// Reemplaza la liga del país correspondiente con la nueva versión.
  /// Mantiene todas las demás ligas sin cambios.
  ///
  /// Throws Exception si el universo no está inicializado.
  Future<void> updateLeague(CountryLeague league) async {
    final universe = await getUniverse();
    if (universe == null) {
      throw Exception(
        'Universe not initialized. Call initializeIfNeeded() first.',
      );
    }

    // Crear nuevo universo con la liga actualizada
    final updatedLeagues = Map<String, CountryLeague>.from(
      universe.activeLeagues,
    );
    updatedLeagues[league.country.code] = league;

    final updatedUniverse = GameUniverse(
      activeLeagues: updatedLeagues,
      createdAt: universe.createdAt,
      gameVersion: universe.gameVersion,
    );

    await saveUniverse(updatedUniverse);
  }

  /// Elimina todo el universo (útil para testing/debugging)
  Future<void> deleteUniverse() async {
    await _db.collection('universe').doc(_universeDocId).delete();
  }
}
