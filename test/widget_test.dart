// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ftg_racing_manager/main.dart';

void main() {
  testWidgets('App basic pump test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Since it uses Firebase, it might require extra setup for full testing,
    // but we can at least verify it builds without immediate failure.
    await tester.pumpWidget(const FTGRacingApp());

    // Verify the app starts (e.g., searches for a key widget or just completes pumping)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
