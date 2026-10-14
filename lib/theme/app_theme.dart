import 'package:flutter/material.dart';

import 'tokens.dart';

/// The Shukaansi brand palette (logo colours) and the surfaces built on it.
abstract final class AppColors {
  /// Deep Teal: actions, active navigation, headings in the brand.
  static const teal = Color(0xFF054744);

  /// Brand gold for icons, badges and highlights. Too light for text on
  /// white: gold text uses [goldText].
  static const gold = Color(0xFFE0AA4F);
  static const goldDark = Color(0xFFC9923A);
  static const goldLight = Color(0xFFF4C66D);

  /// Gold dark enough for text and small icons on light surfaces (AA).
  static const goldText = Color(0xFF85590F);

  /// Logo and splash background.
  static const ivory = Color(0xFFFEFEFC);

  /// App pages: white cards on a warm-neutral page.
  static const warmNeutral = Color(0xFFF7F6F2);
  static const darkPage = Color(0xFF071B1A);
  static const darkCard = Color(0xFF0F2927);

  /// Soft mint behind icons, info chips and the selected tab.
  static const mint = Color(0xFFE3EFED);
  static const primaryLight = Color(0xFF0B5F5A);

  /// Text on light surfaces.
  static const textPrimary = Color(0xFF12201F);
  static const textSecondary = Color(0xFF5C6B6A);
  static const divider = Color(0xFFE7E5DF);
  static const success = Color(0xFF2E7D4F);

  /// Over photos (always dark imagery): text, scrim, shadow, viewer.
  static const onPhoto = Colors.white;
  static const photoScrim = Color(0xB3000000);
  static const photoShadow = Color(0x61000000);
  static const photoViewer = Colors.black;

  /// The one colour for "photo verified" marks.
  static const verified = Color(0xFF1D72E8);
}

abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  /// The app's visual system (docs/ui-redesign-spec.md): white surfaces on a
  /// warm-neutral page, Deep Teal for actions and active navigation,
  /// restrained brand gold, flat surfaces without borders.
  static final refinedLight = _refined(Brightness.light);
  static final refinedDark = _refined(Brightness.dark);

  static ThemeData _refined(Brightness brightness) {
    final light = brightness == Brightness.light;
    final base = _build(brightness);
    final colors = base.colorScheme.copyWith(
      surface: light ? AppColors.warmNeutral : AppColors.darkPage,
      surfaceContainerLowest: light ? Colors.white : AppColors.darkCard,
      surfaceContainerLow: light
          ? const Color(0xFFFBFAF7)
          : const Color(0xFF14302D),
      outlineVariant: light ? AppColors.divider : const Color(0xFF254340),
      primaryContainer: light ? AppColors.mint : const Color(0xFF14403C),
      onPrimaryContainer: light ? AppColors.teal : const Color(0xFFCDE9E5),
      onSurface: light ? AppColors.textPrimary : null,
      onSurfaceVariant: light ? AppColors.textSecondary : null,
    );
    final text = base.textTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );
    return base.copyWith(
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Sizes are explicit: ThemeData's text theme gets its sizes only when
        // Theme.of localizes it, which component themes don't go through.
        titleTextStyle: text.titleLarge?.copyWith(
          fontSize: 22,
          height: 1.27,
          fontWeight: FontWeight.w700,
        ),
      ),
      // Flat white cards, no outline: separation comes from the page colour.
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: colors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      // Selected segments use the green wash, keeping gold for accents.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.primaryContainer
                : colors.surfaceContainerLowest,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.outlineVariant),
          ),
        ),
      ),
      // Flat buttons: the colour carries the hierarchy, not a shadow.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      // Fields match the cards and buttons: white, rounded, a soft outline
      // that turns teal when focused.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        border: _field(colors.outlineVariant),
        enabledBorder: _field(colors.outlineVariant),
        focusedBorder: _field(colors.primary, width: 1.6),
        errorBorder: _field(colors.error),
        focusedErrorBorder: _field(colors.error, width: 1.6),
        disabledBorder: _field(colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static OutlineInputBorder _field(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData _build(Brightness brightness) {
    final accent = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: brightness,
    );
    final colors =
        ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: brightness,
        ).copyWith(
          primary: brightness == Brightness.light
              ? AppColors.teal
              : const Color(0xFF86D1C9),
          onPrimary: brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF003733),
          surface: brightness == Brightness.light
              ? AppColors.ivory
              : AppColors.darkPage,
          secondary: brightness == Brightness.light
              ? AppColors.goldText
              : AppColors.goldLight,
          onSecondary: accent.onPrimary,
          secondaryContainer: accent.primaryContainer,
          onSecondaryContainer: accent.onPrimaryContainer,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );

    return ThemeData(
      useMaterial3: true,
      // Bundled brand font (assets/fonts, SIL Open Font License).
      fontFamily: AppTheme.fontFamily,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(48, AppSizes.button),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 1.5),
          minimumSize: const Size(48, AppSizes.button),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: shape,
        ),
      ),
      // Cards: flat, rounded, separated by a subtle border rather than shadow.
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      // Selected chips share the selected-card look: green wash and border.
      chipTheme: ChipThemeData(
        selectedColor: Color.alphaBlend(
          colors.primary.withValues(alpha: 0.10),
          colors.surface,
        ),
        checkmarkColor: colors.primary,
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.outlineVariant,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
