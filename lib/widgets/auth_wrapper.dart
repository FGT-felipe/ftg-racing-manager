import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/main_layout.dart';
import '../screens/onboarding/landing_screen.dart';
import '../screens/onboarding/create_manager_screen.dart';
import '../screens/onboarding/team_selection_screen.dart';
import '../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, authSnapshot) {
        // Case 2: Loading Auth State
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        // Case 1: No User -> Landing Screen
        if (user == null) {
          return const LandingScreen();
        }

        // Case 3: User Logged In -> Check Manager Profile
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('managers')
              .doc(user.uid)
              .get(),
          builder: (context, profileSnapshot) {
            // Loading Manager Profile
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).errorLoadingProfile(profileSnapshot.error.toString()),
                  ),
                ),
              );
            }

            final profileDoc = profileSnapshot.data;
            final hasProfile = profileDoc?.exists ?? false;

            if (!hasProfile) {
              // No Profile -> Create Manager
              return const CreateManagerScreen();
            }

            final managerData = profileDoc!.data() as Map<String, dynamic>;
            final nationality =
                managerData['nationality'] as String? ?? 'Brazil';

            // Has Profile -> Check Team Assignment
            // We use a StreamBuilder here so if the team is assigned/created in the next step,
            // it updates automatically without a refresh.
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .where('managerId', isEqualTo: user.uid)
                  .limit(1)
                  .snapshots(),
              builder: (context, teamSnapshot) {
                if (teamSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (teamSnapshot.hasData &&
                    teamSnapshot.data!.docs.isNotEmpty) {
                  // Has Team -> MAIN LAYOUT (The Single Scaffold)
                  final teamId = teamSnapshot.data!.docs.first.id;
                  return MainLayout(teamId: teamId);
                }

                // Has Profile but No Team -> Team Selection
                return TeamSelectionScreen(nationality: nationality);
              },
            );
          },
        );
      },
    );
  }
}
