import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yvl/providers/settings_provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:yvl/providers/player_provider.dart';
import 'package:yvl/utils/app_colors.dart';

const String kDefaultFontFamily = 'ADLaM Display';

extension ColorWithHSL on Color {
  HSLColor get hsl => HSLColor.fromColor(this);
  Color withSaturation(double saturation) =>
      hsl.withSaturation(clampDouble(saturation, 0.0, 1.0)).toColor();
  Color withLightness(double lightness) =>
      hsl.withLightness(clampDouble(lightness, 0.0, 1.0)).toColor();
  Color withHue(double hue) =>
      hsl.withHue(clampDouble(hue, 0.0, 360.0)).toColor();
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

final currentPaletteProvider = FutureProvider<PaletteGenerator?>((ref) async {
  final mediaItem = ref.watch(currentMediaItemProvider).value;
  if (mediaItem?.artUri == null) return null;
  try {
    final imageProvider = NetworkImage(mediaItem!.artUri.toString());
    return await PaletteGenerator.fromImageProvider(imageProvider, maximumColorCount: 20);
  } catch (e) {
    return null;
  }
});

class ThemeColorNotifier extends StateNotifier<Color?> {
  ThemeColorNotifier(this.ref) : super(null) { _init(); }
  final Ref ref;
  void _init() {
    ref.listen(currentPaletteProvider, (previous, next) {
      next.whenData((palette) {
        if (palette != null) {
          final color = palette.dominantColor?.color ??
              palette.darkMutedColor?.color ??
              palette.darkVibrantColor?.color ??
              palette.lightMutedColor?.color ??
              palette.lightVibrantColor?.color;
          if (color != null) state = color;
        }
      });
    });
  }
}

final themeColorProvider = StateNotifierProvider<ThemeColorNotifier, Color?>((ref) {
  return ThemeColorNotifier(ref);
});

final dynamicColorSchemeProvider = StateProvider<ColorScheme?>((ref) => null);

class ThemeLogic {
  static const Color _darkPrimaryText = AppColors.primaryText;
  static const Color _darkSecondaryText = AppColors.secondaryText;
  static const Color _lightPrimaryText = Colors.black;
  static const Color _lightSecondaryText = Color(0xFF424242);

  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.r.toInt(), g = color.g.toInt(), b = color.b.toInt();
    for (int i = 1; i < 10; i++) strengths.add(0.1 * i);
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.toARGB32(), swatch);
  }

  static ThemeData _buildDarkTheme(String fontFamily, {ColorScheme? dynamicColorScheme}) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white.withValues(alpha: 0.002),
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: true,
    ));

    const Color scaffold = Color(0xFF000000);
    const Color surface = Color(0xFF080808);
    const Color card = Color(0xFF0F0F0F);

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffold,
      canvasColor: card,
      primaryColor: const Color(0xFF00BCD4),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00BCD4),
        secondary: Color(0xFF555555),
        surface: surface,
        onSurface: Colors.white,
        outline: Color(0xFF333333),
      ),
      cardColor: card,
      dividerColor: const Color(0xFF222222),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF101010),
        modalBarrierColor: Colors.black87,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: _darkPrimaryText),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, color: _darkPrimaryText),
        titleSmall: TextStyle(color: Color(0xFFCCCCCC)),
        bodyMedium: TextStyle(color: _darkSecondaryText),
        labelMedium: TextStyle(fontWeight: FontWeight.w800, fontSize: 23, color: _darkPrimaryText),
        labelSmall: TextStyle(fontSize: 15, color: _darkSecondaryText, letterSpacing: 0, fontWeight: FontWeight.bold),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearTrackColor: Color(0xFF1A1A1A),
        color: Colors.white,
      ),
      sliderTheme: const SliderThemeData(
        inactiveTrackColor: Color(0xFF222222),
        activeTrackColor: Colors.white,
        thumbColor: Colors.white,
        trackHeight: 4,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF00BCD4),
        selectionColor: Color(0xFF00BCD4),
        selectionHandleColor: Color(0xFF00BCD4),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF00BCD4)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        },
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF101010)),
      tabBarTheme: const TabBarThemeData(indicatorColor: Colors.white),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        subtitleTextStyle: TextStyle(color: Color(0xFF888888), fontSize: 12),
      ),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.getTextTheme(fontFamily, baseTheme.textTheme),
    );
  }

  static ThemeData _buildSkyTheme(String fontFamily) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white.withValues(alpha: 0.002),
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: true,
    ));

    const Color scaffold = Color(0xFF050A14);
    const Color surface = Color(0xFF0A1628);
    const Color card = Color(0xFF0D1F35);

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffold,
      canvasColor: card,
      primaryColor: const Color(0xFF00E5FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00E5FF),
        secondary: Color(0xFF40C4FF),
        surface: surface,
        onSurface: Colors.white,
        outline: Color(0xFF1A3050),
      ),
      cardColor: card,
      dividerColor: const Color(0xFF1A3050),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0A1628),
        modalBarrierColor: Colors.black87,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        titleSmall: TextStyle(color: Color(0xFFB0C4DE)),
        bodyMedium: TextStyle(color: Color(0xFF90A4AE)),
        labelMedium: TextStyle(fontWeight: FontWeight.w800, fontSize: 23, color: Colors.white),
        labelSmall: TextStyle(fontSize: 15, color: Color(0xFF90A4AE), letterSpacing: 0, fontWeight: FontWeight.bold),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearTrackColor: Color(0xFF1A3050),
        color: Color(0xFF00E5FF),
      ),
      sliderTheme: const SliderThemeData(
        inactiveTrackColor: Color(0xFF1A3050),
        activeTrackColor: Color(0xFF00E5FF),
        thumbColor: Colors.white,
        trackHeight: 4,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF00E5FF),
        selectionColor: Color(0xFF00E5FF),
        selectionHandleColor: Color(0xFF00E5FF),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF00E5FF)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        },
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0A1628)),
      tabBarTheme: const TabBarThemeData(indicatorColor: Color(0xFF00E5FF)),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        subtitleTextStyle: TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
      ),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.getTextTheme(fontFamily, baseTheme.textTheme),
    );
  }

  static ThemeData _buildDoodleTheme(String fontFamily) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black.withValues(alpha: 0.002),
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: true,
    ));

    const Color scaffold = Color(0xFFFFFCF0);
    const Color surface = Color(0xFFFFF8E8);
    const Color card = Color(0xFFFFFFFF);
    const Color primary = Color(0xFFFF6B6B);
    const Color secondary = Color(0xFF4ECDC4);
    const Color onSurface = Color(0xFF2D2D2D);

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffold,
      canvasColor: card,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        outline: Color(0xFFE8DFD0),
      ),
      cardColor: card,
      dividerColor: const Color(0xFFEDE4D6),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFBF0),
        modalBarrierColor: Color(0x66000000),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: onSurface),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, color: onSurface),
        titleSmall: TextStyle(color: Color(0xFF6B5E4E)),
        bodyMedium: TextStyle(color: Color(0xFF6B5E4E)),
        labelMedium: TextStyle(fontWeight: FontWeight.w800, fontSize: 23, color: onSurface),
        labelSmall: TextStyle(fontSize: 15, color: Color(0xFF6B5E4E), letterSpacing: 0, fontWeight: FontWeight.bold),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearTrackColor: Color(0xFFEDE4D6),
        color: primary,
      ),
      sliderTheme: const SliderThemeData(
        inactiveTrackColor: Color(0xFFEDE4D6),
        activeTrackColor: primary,
        thumbColor: primary,
        trackHeight: 4,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0xFFFFB3B3),
        selectionHandleColor: primary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        },
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFFFFFBF0)),
      tabBarTheme: const TabBarThemeData(indicatorColor: primary),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 16),
        subtitleTextStyle: TextStyle(color: Color(0xFF6B5E4E), fontSize: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.getTextTheme(fontFamily, baseTheme.textTheme),
    );
  }

  static ThemeData _buildLightTheme(String fontFamily, {ColorScheme? dynamicColorScheme}) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black.withValues(alpha: 0.002),
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: true,
    ));
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      canvasColor: const Color(0xFFFFFFFF),
      primaryColor: dynamicColorScheme?.primary ?? const Color(0xFF1DB954),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: dynamicColorScheme?.copyWith(surface: const Color(0xFFF5F5F5)) ??
          const ColorScheme.light(
            primary: Color(0xFF1DB954),
            secondary: Color(0xFF888888),
            surface: Color(0xFFF5F5F5),
            onSurface: Colors.black,
          ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF1DB954),
        linearTrackColor: Colors.black12,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: _lightPrimaryText),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, color: _lightPrimaryText),
        labelMedium: TextStyle(fontWeight: FontWeight.w800, fontSize: 23, color: _lightPrimaryText),
        labelSmall: TextStyle(fontSize: 15, color: _lightSecondaryText, letterSpacing: 0, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: _lightSecondaryText),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        modalBarrierColor: Colors.black26,
      ),
      sliderTheme: const SliderThemeData(
        thumbColor: Colors.black,
        activeTrackColor: Color(0xFF5bc0be),
        trackHeight: 4,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF5bc0be)),
      ),
      dividerColor: const Color(0xFFE0E0E0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.getTextTheme(fontFamily, baseTheme.textTheme),
    );
  }

  static ThemeData createThemeData(
    MaterialColor? primarySwatch,
    ThemeType themeType, {
    MaterialColor? titleColorSwatch,
    Color? textColor,
    Brightness? systemBrightness,
    ColorScheme? dynamicColorScheme,
    String fontFamily = kDefaultFontFamily,
  }) {
    switch (themeType) {
      case ThemeType.dark:
        return _buildDarkTheme(fontFamily, dynamicColorScheme: dynamicColorScheme);
      case ThemeType.sky:
        return _buildSkyTheme(fontFamily);
      case ThemeType.light:
        return _buildLightTheme(fontFamily, dynamicColorScheme: dynamicColorScheme);
      case ThemeType.doodle:
        return _buildDoodleTheme(fontFamily);
      default:
        return _buildDarkTheme(fontFamily, dynamicColorScheme: dynamicColorScheme);
    }
  }
}

final themeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(settingsProvider);
  final themeType = settings.themeType;
  final fontFamily = settings.appFontFamily;
  final dynamicColorScheme = ref.watch(dynamicColorSchemeProvider);

  final effectiveType = themeType == ThemeType.auto
      ? (WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light
            ? ThemeType.light
            : ThemeType.dark)
      : themeType;

  switch (effectiveType) {
    case ThemeType.light:
      return ThemeLogic.createThemeData(null, ThemeType.light,
          dynamicColorScheme: dynamicColorScheme, fontFamily: fontFamily);
    case ThemeType.sky:
      return ThemeLogic.createThemeData(null, ThemeType.sky, fontFamily: fontFamily);
    case ThemeType.doodle:
      return ThemeLogic.createThemeData(null, ThemeType.doodle, fontFamily: fontFamily);
    default:
      return ThemeLogic.createThemeData(null, ThemeType.dark,
          dynamicColorScheme: dynamicColorScheme, fontFamily: fontFamily);
  }
});
