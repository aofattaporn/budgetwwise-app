import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        seed: const Color(0xFF2F6BFF),
        scaffold: const Color(0xFFF5F7FB),
        card: const Color(0xFFFFFFFF),
        divider: const Color(0xFFEDF0F6),
        indicator: const Color(0xFFE8F0FF),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        seed: const Color(0xFF4F9BFF),
        scaffold: const Color(0xFF07080B),
        card: const Color(0xFF12141A),
        divider: const Color(0xFF1C1F28),
        indicator: const Color(0xFF14264A),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color seed,
    required Color scaffold,
    required Color card,
    required Color divider,
    required Color indicator,
  }) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final shape28 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(28));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      dividerColor: divider,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: shape28,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: shape28,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: indicator,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
