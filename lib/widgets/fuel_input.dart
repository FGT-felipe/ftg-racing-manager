import 'package:flutter/material.dart';

class FuelInput extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const FuelInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<FuelInput> createState() => _FuelInputState();
}

class _FuelInputState extends State<FuelInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(FuelInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final currentTextValue = double.tryParse(_controller.text);
      if (currentTextValue != widget.value) {
        _controller.text = widget.value.toStringAsFixed(1);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              enabled: widget.enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              controller: _controller,
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null) {
                  widget.onChanged(d);
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Text(
              "L",
              style: TextStyle(
                fontSize: 8,
                color: Colors.white24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
