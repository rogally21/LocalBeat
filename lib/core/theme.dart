// fatto da Vuoler21
import 'package:flutter/material.dart';

const kAccent = Color(0xFF8B7CFF);
const kAccent2 = Color(0xFF3DE0D0);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF07070A),
      colorScheme: ColorScheme.fromSeed(seedColor: kAccent, brightness: Brightness.dark),
      sliderTheme: const SliderThemeData(
          trackHeight: 3, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5)),
    );
