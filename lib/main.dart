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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  tz_data.initializeTimeZones();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check for automatic database reset via configuration
  if (GameConfig.shouldReset) {
    debugPrint("CONFIG: auto-reset is enabled. NUKING database...");
    await DatabaseSeeder.nukeAndReseed();
    debugPrint(
      "CONFIG: Reset complete. Please set GameConfig.shouldReset to false.",
    );
  }

  runApp(const FTGRacingApp());
}

class FTGRacingApp extends StatelessWidget {
  const FTGRacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FTG Racing Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/admin': (context) => const AdminScreen(),
      },
    );
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
    // LEVEL 2: Listen to Manager Document REALTIME
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('managers')
          .doc(uid)
          .snapshots(),
      builder: (context, managerSnapshot) {
        if (managerSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        }

        bool profileExists =
            managerSnapshot.hasData && managerSnapshot.data!.exists;

        if (profileExists) {
          // Profile exists, now check for Team
          final data = managerSnapshot.data!.data() as Map<String, dynamic>;
          final nationality = data['nationality'] as String? ?? 'Brazil';
          return TeamCheck(uid: uid, nationality: nationality);
        } else {
          // No profile -> Create Manager
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
    // LEVEL 3: Listen to Team Assignment REALTIME
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where('managerId', isEqualTo: uid)
          .limit(1)
          .snapshots(),
      builder: (context, teamSnapshot) {
        if (teamSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        }

        if (teamSnapshot.hasData && teamSnapshot.data!.docs.isNotEmpty) {
          // Team exists -> Main Layout
          final teamId = teamSnapshot.data!.docs.first.id;
          return MainLayout(teamId: teamId);
        }

        // No Team -> Team Selection
        return TeamSelectionScreen(nationality: nationality);
      },
    );
  }
}
