import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegistering = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  // AUTH LOGIC: GOOGLE
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).googleAuthError(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // AUTH LOGIC: EMAIL
  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isRegistering) {
        final UserCredential result = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailCtrl.text.trim(),
              password: _passCtrl.text.trim(),
            );

        if (result.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(result.user!.uid)
              .set({
                'uid': result.user!.uid,
                'email': _emailCtrl.text.trim(),
                'firstName': _nameCtrl.text.trim(),
                'lastName': _lastNameCtrl.text.trim(),
                'registrationDate': DateTime.now().toIso8601String(),
              });
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = AppLocalizations.of(context).authError(e.message ?? '');
      if (e.code == 'email-already-in-use') {
        message = AppLocalizations.of(context).emailAlreadyRegistered;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).unexpectedError(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background Image with dark gradient overlay ──
          Positioned.fill(
            child: Image.asset(
              'blueprints/login_image.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // Dark gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A0A).withValues(alpha: 0.75),
                    const Color(0xFF0A0A0A).withValues(alpha: 0.92),
                    const Color(0xFF0A0A0A),
                  ],
                  stops: const [0.0, 0.45, 0.75],
                ),
              ),
            ),
          ),
          // Subtle vignette
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0A0A0A).withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // ── Main Content ──
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Brand Logo ──
                    const _BrandLogo(),
                    const SizedBox(height: 8),

                    // ── "Formula Track Glory" ──
                    Text(
                      AppLocalizations.of(context).formulaTrackGlory,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w300,
                        fontSize: 14,
                        letterSpacing: 4.0,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Slogan ──
                    Text(
                      AppLocalizations.of(context).ftgSlogan,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF00C853),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ── Google Button ──
                    _buildGoogleButton(),
                    const SizedBox(height: 28),

                    // ── Divider ──
                    _buildDivider(),
                    const SizedBox(height: 28),

                    // ── Email Form ──
                    _buildEmailForm(),
                    const SizedBox(height: 20),

                    // ── Toggle ──
                    TextButton(
                      onPressed: () {
                        setState(() => _isRegistering = !_isRegistering);
                      },
                      child: Text(
                        _isRegistering
                            ? AppLocalizations.of(context).alreadyHaveAccount
                            : AppLocalizations.of(context).newManagerJoin,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Footer ──
                    Text(
                      AppLocalizations.of(context).versionFooter,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.25),
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Google Button ──
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: Text(
          AppLocalizations.of(context).continueWithGoogle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.04),
        ),
      ),
    );
  }

  // ── Divider ──
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context).orUseEmail,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.35),
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Email Form ──
  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_isRegistering) ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _nameCtrl,
                    label: AppLocalizations.of(context).firstNameLabel,
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameCtrl,
                    label: AppLocalizations.of(context).lastNameLabel,
                    icon: Icons.person_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          _buildTextField(
            controller: _emailCtrl,
            label: AppLocalizations.of(context).emailAddressLabel,
            keyboardType: TextInputType.emailAddress,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _passCtrl,
            label: AppLocalizations.of(context).passwordLabel,
            obscureText: true,
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 28),

          // ── Submit Button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(
                  0xFF00C853,
                ).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      _isRegistering
                          ? AppLocalizations.of(context).createAccountBtn
                          : AppLocalizations.of(context).signInBtn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Text Field ──
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.3))
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter $label";
        }
        return null;
      },
    );
  }
}

// ── BRAND LOGO ──
class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00C853);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Subtle glow behind FTG
              Positioned(
                child: Container(
                  width: 160,
                  height: 80,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.06),
                        blurRadius: 80,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),

              // "FTG" Core Text
              Transform(
                transform: Matrix4.skewX(-0.3),
                child: Text(
                  "FTG",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 84,
                    letterSpacing: -10,
                    color: Colors.white,
                  ),
                ),
              ),

              // Speed Cut (Mask Layer)
              Positioned(
                bottom: 22,
                child: Transform(
                  transform: Matrix4.skewX(-0.3),
                  child: Container(
                    width: 240,
                    height: 10,
                    color: Colors.transparent,
                  ),
                ),
              ),

              // Speed Line and Apex
              Positioned(
                bottom: 26,
                child: Transform(
                  transform: Matrix4.skewX(-0.3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 180, height: 1.5, color: accentColor),
                      const SizedBox(width: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
