import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(28));
  static const BorderRadius panelRadius = BorderRadius.all(Radius.circular(32));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(999));
  static const double navBarHeight = 64;
  static const double pagePadding = 20;
  static const double compactPagePadding = 16;
  static const double sectionGap = 16;
  static const double compactSectionGap = 12;
  static const double cardGap = 12;
  static const double compactCardGap = 10;
  static const double cardPadding = 18;
  static const double compactCardPadding = 16;

  static ThemeData light() {
    return _theme(Brightness.light);
  }

  static ThemeData dark() {
    return _theme(Brightness.dark);
  }

  static ThemeData _theme(Brightness brightness) {
    const seedColor = Color(0xFF6A5CFF);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final baseTheme = ThemeData(useMaterial3: true, brightness: brightness);
    final textTheme = _textTheme(baseTheme.textTheme, colorScheme);
    final isDark = brightness == Brightness.dark;
    final scaffoldColor = isDark
        ? const Color(0xFF0D1022)
        : const Color(0xFFF6F4FF);
    final cardColor = isDark
        ? colorScheme.surfaceContainerLow
        : colorScheme.surface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldColor,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scaffoldColor,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: cardColor,
        shadowColor: colorScheme.shadow.withValues(alpha: isDark ? 0.26 : 0.08),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: const RoundedRectangleBorder(borderRadius: chipRadius),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: navBarHeight,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.92),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.surfaceContainerHighest;
            }

            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.42);
            }

            return null;
          }),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.42);
            }

            return null;
          }),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            final alpha = states.contains(WidgetState.disabled) ? 0.18 : 0.38;
            return BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: alpha),
            );
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.surfaceContainerLowest;
            }

            return colorScheme.surface.withValues(alpha: isDark ? 0.86 : 0.92);
          }),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(22)),
            ),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: const RoundedRectangleBorder(borderRadius: cardRadius),
        iconColor: colorScheme.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
        backgroundColor: isDark
            ? const Color(0xFF171A31)
            : const Color(0xFF18162D),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: colorScheme.tertiaryContainer,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer.withValues(alpha: 0.55),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.72)
            : colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.surfaceContainerLowest;
            }

            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primaryContainer.withValues(alpha: 0.8);
            }

            return colorScheme.surface.withValues(alpha: isDark ? 0.38 : 0.68);
          }),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
          shape: const WidgetStatePropertyAll(CircleBorder()),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme colorScheme) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        height: 1.02,
        color: colorScheme.onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 1.06,
        color: colorScheme.onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        height: 1.08,
        color: colorScheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.08,
        color: colorScheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.16,
        color: colorScheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        height: 1.45,
        color: colorScheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.45,
        color: colorScheme.onSurfaceVariant,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  static LinearGradient heroGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      colors: [
        colorScheme.primaryContainer,
        Color.lerp(
              colorScheme.primaryContainer,
              colorScheme.tertiaryContainer,
              0.55,
            ) ??
            colorScheme.secondaryContainer,
        colorScheme.secondaryContainer,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient accentGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      colors: [
        colorScheme.primary,
        Color.lerp(colorScheme.primary, colorScheme.tertiary, 0.6) ??
            colorScheme.tertiary,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient avatarGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      colors: [
        Color.lerp(colorScheme.primary, colorScheme.tertiary, 0.2) ??
            colorScheme.primary,
        colorScheme.secondary,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static List<BoxShadow> softShadow(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = theme.brightness == Brightness.dark ? 0.22 : 0.08;
    return [
      BoxShadow(
        color: theme.colorScheme.shadow.withValues(alpha: opacity),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
    ];
  }

  static List<BoxShadow> floatingShadow(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = theme.brightness == Brightness.dark ? 0.3 : 0.12;
    return [
      BoxShadow(
        color: theme.colorScheme.shadow.withValues(alpha: opacity),
        blurRadius: 36,
        offset: const Offset(0, 18),
      ),
    ];
  }

  static BoxDecoration surfaceDecoration(
    BuildContext context, {
    Color? color,
    Gradient? gradient,
    BorderRadius borderRadius = panelRadius,
    bool prominent = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BoxDecoration(
      color: gradient == null ? (color ?? colorScheme.surface) : null,
      gradient: gradient,
      borderRadius: borderRadius,
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(
          alpha: prominent ? 0.32 : 0.18,
        ),
      ),
      boxShadow: prominent ? floatingShadow(context) : softShadow(context),
    );
  }

  static BoxDecoration glassDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.surface.withValues(alpha: 0.7),
      borderRadius: chipRadius,
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
      ),
    );
  }

  static EdgeInsets screenPadding({bool compact = false}) {
    return EdgeInsets.all(compact ? compactPagePadding : pagePadding);
  }

  static EdgeInsets sectionPadding({bool compact = false}) {
    return EdgeInsets.all(compact ? compactCardPadding : cardPadding);
  }

  static double sectionSpacing({bool compact = false}) {
    return compact ? compactSectionGap : sectionGap;
  }

  static double listSpacing({bool compact = false}) {
    return compact ? compactCardGap : cardGap;
  }
}
