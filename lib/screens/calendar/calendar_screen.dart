import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  final String teamId;

  const CalendarScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Calendar View - Work in Progress\nSeason race schedule coming soon.",
      ),
    );
  }
}
