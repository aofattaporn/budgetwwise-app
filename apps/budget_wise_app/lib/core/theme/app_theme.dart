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
    primary: Color(0xFF18181B),
    accent: Color(0xFF3B82F6),
    accentLight: Color(0xFFEFF6FF),
    scaffoldBg: Color(0xFFFAFAFA),
    cardBg: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF4F4F7),
    textPrimary: Color(0xFF18181B),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    textOnPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF10B981),
    expense: Color(0xFFEF4444),
    incomeLight: Color(0xFFECFDF5),
    expenseLight: Color(0xFFFEF2F2),
    border: Color(0xFFE5E7EB),
    divider: Color(0xFFF3F4F6),
  );

  // ── Dark palette ──────────────────────────────────────────────────────
  // Lighter indigo accent for contrast on near-black zinc surfaces.
  static const dark = AppColors._(
    primary: Color(0xFFE4E4F0),
    accent: Color(0xFF60A5FA),
    accentLight: Color(0xFF1C2A40),
    scaffoldBg: Color(0xFF121214),
    cardBg: Color(0xFF1C1C1F),
    surfaceLight: Color(0xFF27272B),
    textPrimary: Color(0xFFE4E4E7),
    textSecondary: Color(0xFFA1A1AA),
    textTertiary: Color(0xFF71717A),
    textOnPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF34D399),
    expense: Color(0xFFF87171),
    incomeLight: Color(0xFF132A22),
    expenseLight: Color(0xFF2A1717),
    border: Color(0xFF2E2E36),
    divider: Color(0xFF242428),
  );

  /// Resolve the palette for the current brightness.
  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

class AppDimens {
  AppDimens._();

  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;
  static const double radiusPill = 100.0;

  static const double pagePadding = 20.0;
  static const double cardPadding = 18.0;

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
      border: isDark ? Border.all(color: _c.border, width: 0.5) : null,
      boxShadow: isDark
          ? null
          : const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
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
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        borderSide: BorderSide(color: _c.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        borderSide: BorderSide(color: _c.expense),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Buttons ────────────────────────────────────────────────────────────
  ButtonStyle get primaryButton {
    final isDark = identical(_c, AppColors.dark);
    return ElevatedButton.styleFrom(
      backgroundColor: isDark ? _c.accent : _c.primary,
      foregroundColor: _c.textOnPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }

  ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
        foregroundColor: _c.textSecondary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
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
      backgroundColor: _c.cardBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(title, style: titleMedium),
      centerTitle: false,
      iconTheme: IconThemeData(color: _c.textPrimary),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: showBack,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(color: _c.border, height: 0.5),
      ),
    );
  }

  // ── Bottom Sheet ───────────────────────────────────────────────────────
  Widget sheetHandle() => Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: _c.border,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  // ── Icon Container ─────────────────────────────────────────────────────
  Widget iconBox({
    required IconData icon,
    double size = 40,
    Color? bgColor,
    Color? iconColor,
    double iconSize = 20,
    double radius = 10,
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
