import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding/landing_screen.dart';
import 'screens/onboarding/create_manager_screen.dart';
import 'screens/onboarding/team_selection_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FireTowerApp());
}

class FireTowerApp extends StatelessWidget {
  const FireTowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.teal,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RootHandler(),
    );
  }
}

class RootHandler extends StatelessWidget {
  const RootHandler({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Check Authentication
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          // No user -> Landing Page
          return const LandingScreen();
        }

        // 2. Check Manager Profile
        return FutureBuilder<bool>(
          future: AuthService().hasManagerProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                ),
              );
            }

            final hasProfile = profileSnapshot.data ?? false;

            if (!hasProfile) {
              // No profile -> Create Manager Form
              return const CreateManagerScreen();
            }

            // 3. Check Team Assignment
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .where('managerId', isEqualTo: user.uid)
                  .limit(1)
                  .snapshots(),
              builder: (context, teamSnapshot) {
                if (teamSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Colors.tealAccent,
                      ),
                    ),
                  );
                }

                if (teamSnapshot.hasData &&
                    teamSnapshot.data!.docs.isNotEmpty) {
                  // Has Team -> Go to Dashboard
                  final teamId = teamSnapshot.data!.docs.first.id;
                  return MainScaffold(teamId: teamId);
                }

                // Has Profile but No Team -> Team Selection
                return const TeamSelectionScreen();
              },
            );
          },
        );
      },
    );
  }
}
