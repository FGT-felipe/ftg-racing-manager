import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnyxTable extends StatefulWidget {
  final List<String> columns;
  final List<List<dynamic>>? rows;
  final Widget Function(BuildContext, int)? itemBuilder;
  final int? itemCount;
  final List<int> flexValues;
  final List<int> highlightIndices;
  final VoidCallback? onReachEnd;
  final bool shrinkWrap;

  const OnyxTable({
    super.key,
    required this.columns,
    this.rows,
    this.itemBuilder,
    this.itemCount,
    required this.flexValues,
    this.highlightIndices = const [],
    this.onReachEnd,
    this.shrinkWrap = false,
  }) : assert(
         rows != null || (itemBuilder != null && itemCount != null),
         'Either rows or (itemBuilder and itemCount) must be provided',
       );

  @override
  State<OnyxTable> createState() => _OnyxTableState();
}

class _OnyxTableState extends State<OnyxTable> {
  final ScrollController _scrollController = ScrollController();
  bool _onEndThresholdReached = false;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final atEnd =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;

    if (atEnd && !_onEndThresholdReached) {
      _onEndThresholdReached = true;
      if (widget.onReachEnd != null) {
        // Ensure this happens after the current frame to avoid "setState during build"
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onReachEnd?.call();
        });
      }
    } else if (!atEnd) {
      _onEndThresholdReached = false;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FIXED HEADER
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: List.generate(widget.columns.length, (i) {
              return Expanded(
                flex: widget.flexValues[i],
                child: Text(
                  widget.columns[i].toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.1,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              );
            }),
          ),
        ),
        // SCROLLABLE DATA ROWS
        widget.shrinkWrap
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 0),
                itemCount: widget.itemBuilder != null
                    ? widget.itemCount
                    : widget.rows?.length ?? 0,
                itemBuilder: (context, index) {
                  if (widget.itemBuilder != null) {
                    return _buildRowWrapper(
                      context,
                      index,
                      widget.itemBuilder!(context, index),
                    );
                  }
                  return _buildRowFromData(context, index, widget.rows![index]);
                },
              )
            : Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    itemCount: widget.itemBuilder != null
                        ? widget.itemCount
                        : widget.rows?.length ?? 0,
                    itemBuilder: (context, index) {
                      if (widget.itemBuilder != null) {
                        return _buildRowWrapper(
                          context,
                          index,
                          widget.itemBuilder!(context, index),
                        );
                      }
                      return _buildRowFromData(
                        context,
                        index,
                        widget.rows![index],
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildRowWrapper(BuildContext context, int index, Widget child) {
    final isHighlighted = widget.highlightIndices.contains(index);
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted
              ? const Color(0xFF00C853).withValues(alpha: 0.1)
              : isHovered
              ? const Color(0xFF00C853).withValues(alpha: 0.05)
              : (index % 2 == 0
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.01)),
          border: Border(
            left: isHighlighted
                ? const BorderSide(color: Color(0xFF00C853), width: 4)
                : BorderSide.none,
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: child,
        ),
      ),
    );
  }

  Widget _buildRowFromData(BuildContext context, int index, List<dynamic> row) {
    return _buildRowWrapper(
      context,
      index,
      Row(
        children: List.generate(row.length, (i) {
          final isPoints = i == row.length - 1;
          final isPos = i == 0;
          final isHighlighted = widget.highlightIndices.contains(index);

          final textStyle = (isPoints || isPos)
              ? GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: isHighlighted
                      ? const Color(0xFF00C853)
                      : (isPos
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.9)),
                  fontWeight: isHighlighted || isPoints
                      ? FontWeight.w900
                      : FontWeight.w500,
                )
              : GoogleFonts.inter(
                  fontSize: 12,
                  color: isHighlighted
                      ? const Color(0xFF00C853)
                      : Colors.white.withValues(alpha: 0.9),
                  fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w500,
                );

          final content = row[i];

          return Expanded(
            flex: widget.flexValues[i],
            child: content is InlineSpan
                ? Text.rich(
                    content,
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                  )
                : content is Widget
                ? content
                : Text(
                    content.toString(),
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
          );
        }),
      ),
    );
  }
}
