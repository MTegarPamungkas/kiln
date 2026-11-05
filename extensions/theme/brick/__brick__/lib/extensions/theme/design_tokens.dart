import 'package:flutter/material.dart';

double _lerp(double start, double end, double t) => start + (end - start) * t;

/// Spacing scale available through `context.spacing`.
@immutable
final class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
  });

  /// Default scale for the comfortable density.
  static const AppSpacing comfortable = AppSpacing();

  /// Tighter scale for the compact density.
  static const AppSpacing compact = AppSpacing(
    xs: 3,
    sm: 6,
    md: 12,
    lg: 18,
    xl: 24,
    xxl: 36,
  );

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  /// Padding used by page bodies.
  EdgeInsets get pagePadding => EdgeInsets.all(lg);

  /// Padding used inside cards and panels.
  EdgeInsets get cardPadding => EdgeInsets.all(md);

  /// Vertical gap between page sections.
  SizedBox get sectionGap => SizedBox(height: xl);

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) {
      return this;
    }
    return AppSpacing(
      xs: _lerp(xs, other.xs, t),
      sm: _lerp(sm, other.sm, t),
      md: _lerp(md, other.md, t),
      lg: _lerp(lg, other.lg, t),
      xl: _lerp(xl, other.xl, t),
      xxl: _lerp(xxl, other.xxl, t),
    );
  }
}

/// Corner radii derived from the base radius prompt.
@immutable
final class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    this.sm = 8,
    this.md = 14,
    this.lg = 20,
    this.xl = 28,
    this.pill = 999,
  });

  /// Derives a radius scale from one base value.
  static AppRadius fromCornerRadius(double value) {
    final base = value < 0 ? 0.0 : value;
    return AppRadius(
      sm: base * 0.6,
      md: base,
      lg: base * 1.4,
      xl: base * 2,
    );
  }

  final double sm;
  final double md;
  final double lg;
  final double xl;

  /// Fully rounded corners for chips and avatar shapes.
  final double pill;

  BorderRadius get smBorder => BorderRadius.circular(sm);

  BorderRadius get mdBorder => BorderRadius.circular(md);

  BorderRadius get lgBorder => BorderRadius.circular(lg);

  BorderRadius get xlBorder => BorderRadius.circular(xl);

  @override
  AppRadius copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? pill,
  }) {
    return AppRadius(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      pill: pill ?? this.pill,
    );
  }

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) {
      return this;
    }
    return AppRadius(
      sm: _lerp(sm, other.sm, t),
      md: _lerp(md, other.md, t),
      lg: _lerp(lg, other.lg, t),
      xl: _lerp(xl, other.xl, t),
      pill: _lerp(pill, other.pill, t),
    );
  }
}
