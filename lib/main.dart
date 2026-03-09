import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/create_manager_screen.dart';
import 'screens/onboarding/team_selection_screen.dart';
import 'screens/main_layout.dart';
import 'screens/admin_screen.dart';

import 'config/game_config.dart';
import 'services/database_seeder.dart';
// import 'services/academy_migration.dart';

void main() async {
  debugPrint("APP_START: Iniciando Flutter...");
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  tz_data.initializeTimeZones();

  debugPrint("APP_START: Inicializando Firebase...");
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint("APP_START: Firebase OK");
  } catch (e) {
    debugPrint("APP_START_ERROR: Fallo en Firebase: $e");
  }

  // Run one-time migration for academy sync
  // MIGRATION COMPLETED: Commented out to prevent permission errors on hot reload
  // and unnecessary database calls on startup.
  /*
  try {
    await syncAcademyLevels();
  } catch (e) {
    debugPrint("Failed to sync academies: $e");
  }
  */

  // Check for automatic database reset via configuration
  if (GameConfig.shouldReset) {
    debugPrint("CONFIG: auto-reset is enabled. NUKING database...");
    await DatabaseSeeder.nukeAndReseed();
    debugPrint(
      "CONFIG: Reset complete. Please set GameConfig.shouldReset to false.",
    );
  }

  runApp(const ErrorBoundary(child: FTGRacingApp()));
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      debugPrint(
        "FLUTTER_ERROR_CAPTURED: ${details.exception}\n${details.stack}",
      );
      setState(() {
        _error = details.exception;
        _stack = details.stack;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'CRITICAL UI FATAL ERROR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error.toString(),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _stack.toString(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _stack = null;
                      });
                    },
                    child: const Text('RELOAD APP'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}

class FTGRacingApp extends StatelessWidget {
  const FTGRacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return MaterialApp(
        title: 'FTG Racing Manager',
        debugShowCheckedModeBanner: false,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/admin': (context) => const AdminScreen(),
        },
      );
    } catch (e) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Fatal Start Error: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // LEVEL 1: Listen to Auth State
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        }

        if (!authSnapshot.hasData || authSnapshot.data == null) {
          debugPrint("AuthWrapper: User is null, showing LoginScreen");
          return const LoginScreen();
        }

        final User user = authSnapshot.data!;
        debugPrint("AuthWrapper: User logged in: ${user.uid}");
        return ManagerProfileCheck(uid: user.uid);
      },
    );
  }
}

class ManagerProfileCheck extends StatelessWidget {
  final String uid;
  const ManagerProfileCheck({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    debugPrint("CHECK: Buscando perfil de Manager para $uid...");
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('managers')
          .doc(uid)
          .snapshots(),
      builder: (context, managerSnapshot) {
        if (managerSnapshot.hasError) {
          debugPrint("ERROR: Fallo buscando Manager: ${managerSnapshot.error}");
          return Scaffold(
            body: Center(
              child: Text(
                "Error Manager: ${managerSnapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (managerSnapshot.connectionState == ConnectionState.waiting) {
          debugPrint("CHECK: Esperando datos de Manager...");
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        bool profileExists =
            managerSnapshot.hasData && managerSnapshot.data!.exists;
        debugPrint("CHECK: Perfil Manager existe? $profileExists");

        if (profileExists) {
          final data = managerSnapshot.data!.data() as Map<String, dynamic>;
          final nationality = data['nationality'] as String? ?? 'Brazil';
          return TeamCheck(uid: uid, nationality: nationality);
        } else {
          debugPrint("CHECK: Redirigiendo a Creación de Manager");
          return const CreateManagerScreen();
        }
      },
    );
  }
}

class TeamCheck extends StatelessWidget {
  final String uid;
  final String nationality;
  const TeamCheck({super.key, required this.uid, required this.nationality});

  @override
  Widget build(BuildContext context) {
    debugPrint("CHECK: Buscando Equipo para $uid...");
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where('managerId', isEqualTo: uid)
          .limit(1)
          .snapshots(),
      builder: (context, teamSnapshot) {
        if (teamSnapshot.hasError) {
          debugPrint("ERROR: Fallo buscando Equipo: ${teamSnapshot.error}");
          return Scaffold(
            body: Center(
              child: Text(
                "Error Equipo: ${teamSnapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (teamSnapshot.connectionState == ConnectionState.waiting) {
          debugPrint("CHECK: Esperando datos de Equipo...");
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        bool hasTeam =
            teamSnapshot.hasData && teamSnapshot.data!.docs.isNotEmpty;
        debugPrint("CHECK: Equipo encontrado? $hasTeam");

        if (hasTeam) {
          final teamId = teamSnapshot.data!.docs.first.id;
          debugPrint("CHECK: Entrando a Layout Principal con equipo $teamId");
          return MainLayout(teamId: teamId);
        }

        debugPrint("CHECK: Redirigiendo a Selección de Equipo");
        return TeamSelectionScreen(nationality: nationality);
      },
    );
  }
}
