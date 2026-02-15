import 'package:flutter/material.dart';

class DriversScreen extends StatelessWidget {
  final String teamId;

  const DriversScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Drivers View - Work in Progress\nContract management and stats coming soon.",
      ),
    );
  }
}
