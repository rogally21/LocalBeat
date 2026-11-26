// fatto da Vuoler21
import 'dart:ui';
import 'package:flutter/material.dart';

/// Liquid Glass: blur + gradiente traslucido + bordo soft + ombra leggera
class Glass extends StatelessWidget {
  final Widget child;
  final double radius, blur;
  final EdgeInsets padding;
  const Glass({super.key, required this.child, this.radius = 24, this.blur = 28,
      this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: const [
        BoxShadow(color: Color(0x55000000), blurRadius: 28, offset: Offset(0, 10))
      ]),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withValues(alpha: .18), Colors.white.withValues(alpha: .05)]),
              border: Border.all(color: Colors.white.withValues(alpha: .20), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
