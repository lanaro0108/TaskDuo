import 'package:flutter/material.dart';

abstract final class Brand {
  static const purple = Color(0xff7160ff);
  static const blue = Color(0xff5077ff);
  static const lilac = Color(0xffaf8af8);
  static const mint = Color(0xff43cba7);
  static const gold = Color(0xffffbd30);
  static const orange = Color(0xffff8853);
}

class Palette {
  const Palette(this.dark);
  final bool dark;
  static Palette of(BuildContext c) =>
      Palette(Theme.of(c).brightness == Brightness.dark);
  Color get background =>
      dark ? const Color(0xff101725) : const Color(0xfff8f9ff);
  Color get surface => dark ? const Color(0xff192338) : Colors.white;
  Color get raised => dark ? const Color(0xff202b43) : const Color(0xfff0effc);
  Color get ink => dark ? const Color(0xfff6f5ff) : const Color(0xff171944);
  Color get muted => dark ? const Color(0xffa6afca) : const Color(0xff68708e);
  Color get line => dark ? const Color(0xff2b3550) : const Color(0xffeeedf9);
  Color get tint => dark ? const Color(0xff282e5c) : const Color(0xffeeebff);
  Color get track => dark ? const Color(0xff414978) : const Color(0xffdeddfb);
  List<Color> get hero => dark
      ? const [Color(0xff2e346b), Color(0xff25294d)]
      : const [Color(0xffe9e5ff), Color(0xffe9edff)];
  List<Color> get reward => dark
      ? const [Color(0xff302959), Color(0xff43326f)]
      : const [Color(0xffffedf4), Color(0xffe9ddff)];
}

ThemeData taskDuoTheme(Brightness brightness) {
  final p = Palette(brightness == Brightness.dark);
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.purple,
    brightness: brightness,
    surface: p.surface,
    primary: brightness == Brightness.dark
        ? const Color(0xffa79bff)
        : Brand.purple,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: p.background,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w900,
        color: p.ink,
        letterSpacing: -0.9,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        height: 1.2,
        fontWeight: FontWeight.w900,
        color: p.ink,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w900,
        color: p.ink,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: p.ink,
        letterSpacing: -0.25,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: p.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: p.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: p.muted,
      ),
      bodySmall: TextStyle(
        fontSize: 11,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: p.muted,
      ),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: p.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.raised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Brand.purple, width: 1.5),
      ),
      hintStyle: TextStyle(color: p.muted, fontSize: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.purple,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.track,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: brightness == Brightness.dark
          ? const Color(0xffe9e5ff)
          : const Color(0xff242044),
      contentTextStyle: TextStyle(
        fontFamily: 'Nunito',
        color: brightness == Brightness.dark
            ? const Color(0xff242044)
            : Colors.white,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
