import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Smooth upward-counting numeric display with currency and formatting support
class AnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String? prefix;
  final String? suffix;
  final bool isCurrency;
  final int decimalDigits;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.prefix,
    this.suffix,
    this.isCurrency = false,
    this.decimalDigits = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, currentVal, child) {
        String formattedNumber;
        if (isCurrency) {
          final formatter = NumberFormat.currency(
            symbol: prefix ?? '₹',
            decimalDigits: decimalDigits,
          );
          formattedNumber = formatter.format(currentVal);
        } else {
          final formatter = NumberFormat.decimalPattern();
          formattedNumber = '${prefix ?? ''}${formatter.format(decimalDigits > 0 ? currentVal : currentVal.round())}${suffix ?? ''}';
        }

        return Text(
          formattedNumber,
          style: style,
        );
      },
    );
  }
}
