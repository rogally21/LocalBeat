// fatto da Vuoler21
import 'package:flutter/material.dart';
import 'now_playing.dart';

void openNowPlaying(BuildContext c) => Navigator.push(
    c,
    PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const NowPlaying(),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child)));
