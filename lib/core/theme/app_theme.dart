import 'package:flex_color_scheme/flex_color_scheme.dart';
// import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Use a professional, modern color scheme (inspired by Airbnb/Cult.fit)
  static final light = FlexThemeData.light(
    scheme: FlexScheme.materialBaseline,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
      // useTextTheme: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      inputDecoratorRadius: 12,
      inputDecoratorUnfocusedBorderIsColored: false,
      fabRadius: 16,
      chipRadius: 10,
      cardRadius: 16,
      popupMenuRadius: 12,
      dialogRadius: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
  );

  static final dark = FlexThemeData.dark(
    scheme: FlexScheme.materialBaseline,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      // useTextTheme: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      inputDecoratorRadius: 12,
      inputDecoratorUnfocusedBorderIsColored: false,
      fabRadius: 16,
      chipRadius: 10,
      cardRadius: 16,
      popupMenuRadius: 12,
      dialogRadius: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
  );
}
