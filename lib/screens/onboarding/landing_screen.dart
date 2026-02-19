import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_seeder.dart';
import '../auth/login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Secret Admin Logic
  int _secretTaps = 0;
  Timer? _tapTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }

  void _handleLogoTap() {
    _secretTaps++;

    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 2), () {
      _secretTaps = 0;
    });

    if (_secretTaps >= 5) {
      _secretTaps = 0;
      _showAdminDialog();
    }
  }

  void _showAdminDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Text(
          "ADMIN ACCESS",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: pinController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Enter PIN",
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              if (pinController.text == "1234") {
                Navigator.pop(context);
                _showNukeConfirmation();
              }
            },
            child: const Text(
              "VERIFY",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showNukeConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("NUKE WORLD?", style: TextStyle(color: Colors.red)),
        content: const Text(
          "This will DELETE ALL data (Leagues, Teams, Drivers, Seasons) and RESEED a fresh world.\n\nAre you sure?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await DatabaseSeeder.nukeAndReseed();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("WORLD NUKE SUCCESSFUL"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("EXECUTE NUKE"),
          ),
        ],
      ),
    );
  }

  void _handleLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Effect (Subtle Gradient)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  const Color(0xFF0F1115), // Slightly darker shade
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              // Added scroll for smaller screens
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ), // Max width for content
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo
                      GestureDetector(
                        onTap: _handleLogoTap,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sports_motorsports,
                              size: 100,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        "FTG RACING",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontSize: 32, letterSpacing: 2.0),
                      ),
                      Text(
                        "MANAGER 2026",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6.0,
                        ),
                      ),

                      const SizedBox(height: 64),

                      // Auth Buttons
                      if (_isLoading)
                        CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAuthButton(
                              context,
                              "SIGN IN WITH GOOGLE",
                              Icons.g_mobiledata,
                              Colors.white, // Google is always white bg
                              Colors.black,
                              _handleLogin,
                            ),
                            const SizedBox(height: 16),
                            _buildAuthButton(
                              context,
                              "SIGN IN WITH EMAIL",
                              Icons.email,
                              Theme.of(context).cardColor,
                              Colors.white,
                              _handleLogin,
                            ),
                            const SizedBox(height: 32),

                            // DEV SHORTCUT
                            TextButton.icon(
                              onPressed: _handleDevLogin,
                              icon: const Icon(
                                Icons.developer_mode,
                                color: Colors.orangeAccent,
                              ),
                              label: const Text(
                                "DEV: QUICK START",
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDevLogin() async {
    setState(() => _isLoading = true);

    try {
      // 1. Anon Auth
      final userCred = await FirebaseAuth.instance.signInAnonymously();
      final user = userCred.user;

      if (user != null) {
        // 2. Check if profile exists, if not create basic dev profile
        final doc = await FirebaseFirestore.instance
            .collection('managers')
            .doc(user.uid)
            .get();
        if (!doc.exists) {
          // Create Manager
          await FirebaseFirestore.instance
              .collection('managers')
              .doc(user.uid)
              .set({
                'name': 'Dev',
                'surname': 'User',
                'nationality': 'USA',
                'role': 'engineerDetails',
                'experience': 1,
                'reputation': 50,
              });

          // Create Team
          await FirebaseFirestore.instance.collection('teams').add({
            'managerId': user.uid,
            'name': 'Dev Racing',
            'budget': 50000000,
            'chassisLevel': 50,
            'engineLevel': 50,
            'aeroLevel': 50,
            // Add other necessary defaults as needed by your models
            'drivers': {},
            'engineers': {},
            'sponsors': {},
            'weekStatus': {},
            'history': [],
          });
        }
      }
    } catch (e) {
      debugPrint("Dev Login Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAuthButton(
    BuildContext context,
    String text,
    IconData icon,
    Color bg,
    Color fg,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: fg),
        label: Text(
          text,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: bg == Theme.of(context).cardColor
                ? BorderSide(color: Colors.white10)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
