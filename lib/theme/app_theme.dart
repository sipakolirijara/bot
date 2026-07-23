import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color kainuwaPurple = Color(0xFF7C3AED);
  static const Color darkBackground = Color(0xFF09090E);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: kainuwaPurple,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: kainuwaPurple,
        surface: Color(0xFF13131A),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFA0A0B0),
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );
  }
}
