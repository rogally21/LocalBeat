// fatto da Vuoler21
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// APPROSSIMAZIONE del loader uiverse (sostituibile con l'originale)
class UiverseLoader extends StatefulWidget {
  final double size;
  const UiverseLoader({super.key, this.size = 48});
  @override
  State<UiverseLoader> createState() => _LState();
}

class _LState extends State<UiverseLoader> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(animation: c, builder: (_, __) => CustomPaint(painter: _P(c.value))));
}

class _P extends CustomPainter {
  final double t;
  _P(this.t);
  @override
  void paint(Canvas cv, Size s) {
    final r = s.width / 2, dot = s.width / 9;
    for (var i = 0; i < 8; i++) {
      final a = 2 * pi * i / 8;
      final k = (((t * 8 - i) % 8) + 8) % 8 / 8;
      cv.drawCircle(Offset(r + (r - dot) * cos(a), r + (r - dot) * sin(a)), dot * (1 - k * .6),
          Paint()..color = Color.lerp(kAccent, kAccent2, i / 8)!.withValues(alpha: 1 - k * .9));
    }
  }
  @override
  bool shouldRepaint(_P o) => true;
}
