import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

class PersonalScreen extends StatelessWidget {
  final String teamId;
  final VoidCallback onDriversTap;
  final VoidCallback onFitnessTrainerTap;

  const PersonalScreen({
    super.key,
    required this.teamId,
    required this.onDriversTap,
    required this.onFitnessTrainerTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).personalManagement.toUpperCase(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: screenWidth > 1200 ? 3 : 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.4,
        children: [
          _PersonalCard(
            title: AppLocalizations.of(context).driversTitle,
            icon: Icons.people_alt_rounded,
            onTap: onDriversTap,
            isEnabled: true,
          ),
          _PersonalCard(
            title: AppLocalizations.of(context).fitnessTrainerTitle,
            icon: Icons.fitness_center_rounded,
            onTap: onFitnessTrainerTap,
            isEnabled: true,
          ),
          _PersonalCard(
            title: AppLocalizations.of(context).chiefEngineerTitle,
            icon: Icons.engineering_rounded,
            onTap: () {},
            isEnabled: false,
          ),
          _PersonalCard(
            title: AppLocalizations.of(context).hrManagerTitle,
            icon: Icons.badge_rounded,
            onTap: () {},
            isEnabled: false,
          ),
          _PersonalCard(
            title: AppLocalizations.of(context).marketingManagerTitle,
            icon: Icons.campaign_rounded,
            onTap: () {},
            isEnabled: false,
          ),
        ],
      ),
    );
  }
}

class _PersonalCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  const _PersonalCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.isEnabled,
  });

  @override
  State<_PersonalCard> createState() => _PersonalCardState();
}

class _PersonalCardState extends State<_PersonalCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scanlineController;

  // Mockup colors
  static const Color _neonGreen = Color(0xFF00E676);
  static const Color _accentPurple = Color(0xFFC1C4F4);
  static const Color _disabledGrey = Color(0xFF555555);

  @override
  void initState() {
    super.initState();
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
  }

  @override
  void dispose() {
    _scanlineController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool hovering) {
    if (!widget.isEnabled) return;
    setState(() => _isHovered = hovering);
    if (hovering) {
      _scanlineController.repeat();
    } else {
      _scanlineController.stop();
      _scanlineController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isEnabled ? _neonGreen : _disabledGrey;
    final iconColor = widget.isEnabled
        ? (_isHovered ? _neonGreen : _accentPurple)
        : Colors.grey.withValues(alpha: 0.4);

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      cursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? _neonGreen.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? _neonGreen.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: _isHovered ? 40 : 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Grid
              Positioned.fill(
                child: CustomPaint(
                  painter: _CardGridPainter(
                    color: _accentPurple.withValues(alpha: 0.04),
                  ),
                ),
              ),
              // Scanline sweep (only on hover)
              if (widget.isEnabled)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _scanlineController,
                    builder: (context, child) {
                      return AnimatedOpacity(
                        opacity: _isHovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: CustomPaint(
                          painter: _ScanlinePainter(
                            progress: _scanlineController.value,
                            color: _neonGreen,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Left Accent Bar
              Positioned(
                left: 0,
                top: 20,
                bottom: 20,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                    boxShadow: widget.isEnabled
                        ? [
                            BoxShadow(
                              color: _neonGreen.withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
              // Tappable content
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.isEnabled ? widget.onTap : null,
                    child: Opacity(
                      opacity: widget.isEnabled ? 1.0 : 0.5,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Glassmorphism Icon Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isHovered
                                    ? _neonGreen.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: _isHovered
                                      ? _neonGreen.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                                boxShadow: _isHovered
                                    ? [
                                        BoxShadow(
                                          color: _neonGreen.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: AnimatedScale(
                                scale: _isHovered ? 1.1 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  widget.icon,
                                  size: 40,
                                  color: iconColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.title.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // COMING SOON ribbon
              if (!widget.isEnabled)
                Positioned(
                  top: 15,
                  right: -30,
                  child: Transform.rotate(
                    angle: 0.785,
                    child: Container(
                      width: 120,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).comingSoonBanner.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardGridPainter extends CustomPainter {
  final Color color;

  _CardGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const double step = 30.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanlinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * (progress * 2 - 0.5);
    final gradientHeight = size.height * 0.5;

    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              color.withValues(alpha: 0.06),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromLTWH(
              0,
              centerY - gradientHeight / 2,
              size.width,
              gradientHeight,
            ),
          );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        centerY - gradientHeight / 2,
        size.width,
        gradientHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
