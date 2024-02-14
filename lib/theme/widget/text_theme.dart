import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextDisplayTheme {
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.sourceSansPro(fontSize: 20.0, fontWeight: FontWeight.bold),
    displayMedium: GoogleFonts.sourceSansPro(fontSize: 17.0, fontWeight: FontWeight.w700),
    displaySmall: GoogleFonts.sourceSansPro(fontSize: 15.5, fontWeight: FontWeight.normal),
    headlineMedium: GoogleFonts.sourceSansPro(fontSize: 17.0, fontWeight: FontWeight.w600),
    headlineSmall: GoogleFonts.sourceSansPro(fontSize: 15.5, fontWeight: FontWeight.normal),
    titleLarge: GoogleFonts.sourceSansPro(fontSize: 20.0, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.sourceSansPro(fontSize: 17.0),
    bodyMedium: GoogleFonts.sourceSansPro(fontSize: 15.5),
  );

  static TextTheme darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.sourceSansPro(fontSize: 20.0, fontWeight: FontWeight.bold),
    displayMedium: GoogleFonts.sourceSansPro(fontSize: 17.0, fontWeight: FontWeight.w700),
    displaySmall: GoogleFonts.sourceSansPro(fontSize: 15.5, fontWeight: FontWeight.normal),
    headlineMedium: GoogleFonts.sourceSansPro(fontSize: 17.0, fontWeight: FontWeight.w600),
    headlineSmall: GoogleFonts.sourceSansPro(fontSize: 15.5, fontWeight: FontWeight.normal),
    titleLarge: GoogleFonts.sourceSansPro(fontSize: 20.0, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.sourceSansPro(fontSize: 17.0),
    bodyMedium: GoogleFonts.sourceSansPro(fontSize: 15.5),
  );
}
