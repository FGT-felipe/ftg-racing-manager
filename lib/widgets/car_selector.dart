import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

/// A widget that displays a single car from a sprite sheet and allows
/// the user to navigate between liveries using arrow buttons.
///
/// The sprite sheet is expected to be a grid of [columns] × [rows] cells.
/// Each cell contains one car livery. The [index] property (0-based)
/// determines which car is shown: row = index ~/ columns, col = index % columns.
class CarSelector extends StatefulWidget {
  /// Path to the sprite sheet asset.
  final String assetPath;

  /// Number of columns in the sprite sheet grid.
  final int columns;

  /// Number of rows in the sprite sheet grid.
  final int rows;

  /// Initially selected livery index (0-based).
  final int initialIndex;

  /// Called when the user selects a new livery index.
  final ValueChanged<int>? onChanged;

  const CarSelector({
    super.key,
    this.assetPath = 'liverys/livery_map2.png',
    this.columns = 6,
    this.rows = 3,
    this.initialIndex = 0,
    this.onChanged,
  });

  @override
  State<CarSelector> createState() => _CarSelectorState();
}

class _CarSelectorState extends State<CarSelector> {
  ui.Image? _spriteSheet;
  late int _currentIndex;
  bool _isLoading = true;

  int get _totalSprites => widget.columns * widget.rows;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _totalSprites - 1);
    _loadSpriteSheet();
  }

  Future<void> _loadSpriteSheet() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _spriteSheet = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sprite sheet: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goNext() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _totalSprites;
    });
    widget.onChanged?.call(_currentIndex);
  }

  void _goPrevious() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _totalSprites) % _totalSprites;
    });
    widget.onChanged?.call(_currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_spriteSheet == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).failedToLoadLiveries,
          style: GoogleFonts.raleway(color: Colors.white38),
        ),
      );
    }

    final cellWidth = _spriteSheet!.width / widget.columns;
    final cellHeight = _spriteSheet!.height / widget.rows;

    return Column(
      children: [
        // Car display with navigation arrows
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left arrow
            _buildArrowButton(
              icon: Icons.chevron_left_rounded,
              onTap: _goPrevious,
              accentColor: accentColor,
            ),

            // Car sprite
            Expanded(
              child: AspectRatio(
                aspectRatio: cellWidth / cellHeight,
                child: CustomPaint(
                  painter: _SpritePainter(
                    spriteSheet: _spriteSheet!,
                    index: _currentIndex,
                    columns: widget.columns,
                    cellWidth: cellWidth,
                    cellHeight: cellHeight,
                  ),
                ),
              ),
            ),

            // Right arrow
            _buildArrowButton(
              icon: Icons.chevron_right_rounded,
              onTap: _goNext,
              accentColor: accentColor,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Index indicator
        Text(
          AppLocalizations.of(context).liveryIndexLabel(
            (_currentIndex + 1).toString(),
            _totalSprites.toString(),
          ),
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white38,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: accentColor, size: 24),
        ),
      ),
    );
  }
}

/// CustomPainter that renders a single sprite from the sprite sheet.
class _SpritePainter extends CustomPainter {
  final ui.Image spriteSheet;
  final int index;
  final int columns;
  final double cellWidth;
  final double cellHeight;

  _SpritePainter({
    required this.spriteSheet,
    required this.index,
    required this.columns,
    required this.cellWidth,
    required this.cellHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int col = index % columns;
    final int row = index ~/ columns;

    // Source rectangle in the sprite sheet
    final srcRect = Rect.fromLTWH(
      col * cellWidth,
      row * cellHeight,
      cellWidth,
      cellHeight,
    );

    // Destination rectangle filling the widget
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(
      spriteSheet,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_SpritePainter oldDelegate) {
    return oldDelegate.index != index || oldDelegate.spriteSheet != spriteSheet;
  }
}
