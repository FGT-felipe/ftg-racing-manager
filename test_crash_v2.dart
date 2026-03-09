import 'package:flutter/material.dart';

void main() {
  debugPrint("CRASH_V2: App starting...");

  FlutterError.onError = (details) {
    debugPrint("CRASH_V2: Caught error: ${details.exception}");
  };

  debugPrint("CRASH_V2: Triggering exception...");

  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              debugPrint("CRASH_V2: Button pressed, throwing...");
              throw Exception("V2_BUTTON_CRASH");
            },
            child: const Text("CRASH NOW"),
          ),
        ),
      ),
    ),
  );

  debugPrint("CRASH_V2: Post-runApp reached");
}
