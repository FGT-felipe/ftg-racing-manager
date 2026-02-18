import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  BreadcrumbItem({required this.label, this.onTap});
}

class Breadcrumbs extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumbs({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _buildBreadcrumbs(context),
      ),
    );
  }

  List<Widget> _buildBreadcrumbs(BuildContext context) {
    List<Widget> widgets = [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      widgets.add(_BreadcrumbLink(item: item, isLast: isLast));

      if (!isLast) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "/",
              style: GoogleFonts.raleway(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

class _BreadcrumbLink extends StatefulWidget {
  final BreadcrumbItem item;
  final bool isLast;

  const _BreadcrumbLink({required this.item, required this.isLast});

  @override
  State<_BreadcrumbLink> createState() => _BreadcrumbLinkState();
}

class _BreadcrumbLinkState extends State<_BreadcrumbLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isLast
        ? Colors.white
        : (_isHovered ? Colors.white : Colors.white.withValues(alpha: 0.5));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.item.onTap != null && !widget.isLast
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.isLast ? null : widget.item.onTap,
        child: Text(
          widget.item.label.toUpperCase(),
          style: GoogleFonts.raleway(
            fontSize: 11,
            fontWeight: widget.isLast ? FontWeight.bold : FontWeight.w500,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
