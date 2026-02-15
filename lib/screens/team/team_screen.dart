import 'package:flutter/material.dart';

class TeamScreen extends StatelessWidget {
  final String teamId;

  const TeamScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Team View - Work in Progress\nTeam information and name change logic coming soon.",
      ),
    );
  }
}
