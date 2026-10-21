import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DESIGN SYSTEM – Theme-aware colors, dimensions & styles
/// Use `context.colors` and `context.styles` for theme-aware access.
/// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  final Color primary;
  final Color accent;
  final Color accentLight;
  final Color scaffoldBg;
  final Color cardBg;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnPrimary;
  final Color income;
  final Color expense;
  final Color incomeLight;
  final Color expenseLight;
  final Color border;
  final Color divider;

  const AppColors._({
    required this.primary,
    required this.accent,
    required this.accentLight,
    required this.scaffoldBg,
    required this.cardBg,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnPrimary,
    required this.income,
    required this.expense,
    required this.incomeLight,
    required this.expenseLight,
    required this.border,
    required this.divider,
  });

  // ── Light palette ─────────────────────────────────────────────────────
  // Modern indigo brand on cool zinc neutrals.
  static const light = AppColors._(
    primary: Color(0xFF2F6BFF),
    accent: Color(0xFF5B9DFF),
    accentLight: Color(0xFFE8F0FF),
    scaffoldBg: Color(0xFFF5F7FB),
    cardBg: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFEDF1F8),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF5B6475),
    textTertiary: Color(0xFF8E97A8),
    textOnPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF2FBF8A),
    expense: Color(0xFFFF6F85),
    incomeLight: Color(0xFFE3F7EF),
    expenseLight: Color(0xFFFFEAEE),
    border: Color(0xFFE3E8F0),
    divider: Color(0xFFEDF0F6),
  );

  // ── Dark palette ──────────────────────────────────────────────────────
  // Lighter indigo accent for contrast on near-black zinc surfaces.
  static const dark = AppColors._(
    primary: Color(0xFF8DB8FF),
    accent: Color(0xFF4F9BFF),
    accentLight: Color(0xFF14264A),
    scaffoldBg: Color(0xFF07080B),
    cardBg: Color(0xFF12141A),
    surfaceLight: Color(0xFF1A1D26),
    textPrimary: Color(0xFFF1F3F8),
    textSecondary: Color(0xFFA3AAB8),
    textTertiary: Color(0xFF6B7280),
    textOnPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF5FDDAE),
    expense: Color(0xFFFF8D9B),
    incomeLight: Color(0xFF14302A),
    expenseLight: Color(0xFF3A1F28),
    border: Color(0xFF242836),
    divider: Color(0xFF1C1F28),
  );

  /// Resolve the palette for the current brightness.
  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

class AppDimens {
  AppDimens._();

  static const double radiusSm = 14.0;
  static const double radiusMd = 20.0;
  static const double radiusLg = 28.0;
  static const double radiusPill = 100.0;

  static const double pagePadding = 20.0;
  static const double cardPadding = 20.0;

  static const double iconSm = 32.0;
  static const double iconMd = 40.0;
  static const double iconLg = 48.0;
}

class AppStyles {
  final AppColors _c;

  const AppStyles._(this._c);

  /// Resolve styles for the current theme.
  static AppStyles of(BuildContext context) => AppStyles._(AppColors.of(context));

  // ── Card ───────────────────────────────────────────────────────────────
  /// Elevated surface. In light mode it floats on a soft, layered shadow; in
  /// dark mode shadows don't read, so a hairline border defines the edge.
  BoxDecoration get card {
    final isDark = identical(_c, AppColors.dark);
    return BoxDecoration(
      color: _c.cardBg,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      border: isDark ? Border.all(color: _c.border, width: 1) : null,
      boxShadow: isDark
          ? null
          : const [
              BoxShadow(
                color: Color(0x142F6BFF),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
    );
  }

  /// Large summary card. Light: vivid blue gradient. Dark: deep navy gradient
  /// with a hairline highlight and a soft blue glow.
  BoxDecoration get hero {
    final isDark = identical(_c, AppColors.dark);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF1E3A8A), Color(0xFF0F1B3D), Color(0xFF0B1226)]
            : const [Color(0xFF5B9DFF), Color(0xFF2F6BFF)],
      ),
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      border: isDark
          ? Border.all(color: const Color(0x335B9DFF), width: 1)
          : null,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2F6BFF).withValues(alpha: isDark ? 0.28 : 0.30),
          blurRadius: isDark ? 36 : 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  BoxDecoration get cardFlat => BoxDecoration(
        color: _c.cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      );

  // ── Text ───────────────────────────────────────────────────────────────
  TextStyle get displayLarge => TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: _c.textPrimary,
        letterSpacing: -0.6,
      );

  TextStyle get displayMedium => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: _c.textPrimary,
        letterSpacing: -0.4,
      );

  TextStyle get titleLarge => TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: _c.textPrimary,
        letterSpacing: -0.2,
      );

  TextStyle get titleMedium => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _c.textPrimary,
      );

  TextStyle get bodyLarge => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _c.textPrimary,
      );

  TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        color: _c.textPrimary,
      );

  TextStyle get bodySmall => TextStyle(
        fontSize: 13,
        color: _c.textSecondary,
      );

  TextStyle get caption => TextStyle(
        fontSize: 12,
        color: _c.textTertiary,
      );

  TextStyle get label => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _c.textSecondary,
        letterSpacing: 0.3,
      );

  // ── Input ──────────────────────────────────────────────────────────────
  TextStyle get inputText => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _c.textPrimary,
      );

  InputDecoration input({
    String? label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: _c.textTertiary, fontSize: 14),
      prefixIcon: prefix,
      suffixIcon: suffix,
      prefixText: prefixText,
      prefixStyle: TextStyle(color: _c.textSecondary, fontSize: 16),
      filled: true,
      fillColor: _c.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide(color: _c.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide(color: _c.expense),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  // ── Buttons ────────────────────────────────────────────────────────────
  ButtonStyle get primaryButton {
    final isDark = identical(_c, AppColors.dark);
    return ElevatedButton.styleFrom(
      backgroundColor: isDark ? _c.accent : _c.primary,
      foregroundColor: _c.textOnPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
        foregroundColor: _c.textSecondary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        ),
        side: BorderSide(color: _c.border),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );

  // ── Minimal AppBar ─────────────────────────────────────────────────────
  AppBar appBar({
    required String title,
    List<Widget>? actions,
    bool showBack = true,
    Widget? leading,
  }) {
    final isDark = identical(_c, AppColors.dark);
    return AppBar(
      backgroundColor: _c.scaffoldBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(title, style: titleLarge),
      centerTitle: false,
      iconTheme: IconThemeData(color: _c.textPrimary),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: showBack,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  // ── Bottom Sheet ───────────────────────────────────────────────────────
  Widget sheetHandle() => Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: _c.border,
          borderRadius: BorderRadius.circular(3),
        ),
      );

  // ── Icon Container ─────────────────────────────────────────────────────
  Widget iconBox({
    required IconData icon,
    double size = 40,
    Color? bgColor,
    Color? iconColor,
    double iconSize = 20,
    double radius = 14,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor ?? _c.surfaceLight,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: iconColor ?? _c.accent),
    );
  }
}

// ─── Convenience Extension ───────────────────────────────────────────────────

extension AppThemeContext on BuildContext {
  AppColors get colors => AppColors.of(this);
  AppStyles get styles => AppStyles.of(this);
}
