import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget that animates a numerical count from a beginning to an end value.
class AnimatedCount extends StatefulWidget {
  final double begin;
  final double end;
  final Duration duration;
  final TextStyle? style;
  final String currencySymbol;
  final int decimalDigits;
  final NumberFormat? numberFormat;

  const AnimatedCount({
    super.key,
    required this.begin,
    required this.end,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.currencySymbol = '₹',
    this.decimalDigits = 0,
    this.numberFormat,
  });

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _latestBeginValue;

  @override
  void initState() {
    super.initState();
    _latestBeginValue = widget.begin;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _updateAnimation(widget.begin, widget.end);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the beginning value only if the end value has changed.
    if (oldWidget.end != widget.end) {
      _latestBeginValue = oldWidget.end;
      _updateAnimation(_latestBeginValue, widget.end);
      _controller.forward(from: 0.0);
    }
  }

  void _updateAnimation(double begin, double end) {
    _animation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final format = widget.numberFormat ??
            NumberFormat.currency(
              locale: 'en_IN',
              symbol: widget.currencySymbol,
              decimalDigits: widget.decimalDigits,
            );
        return Text(
          format.format(_animation.value),
          style: widget.style,
        );
      },
    );
  }
}