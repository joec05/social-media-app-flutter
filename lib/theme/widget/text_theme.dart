import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextDisplayTheme {
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.sourceSansPro(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black),
    displayMedium: GoogleFonts.sourceSansPro(fontSize: 17.0, fontWeight: FontWeight.w700, color: Colors.black),
    displaySmall: GoogleFonts.sourceSansPro(fontSize: 15.5, fontWeight: FontWeight.normal, color: Colors.black),
    headlineMedium: GoogleFonts.sourceSansPro(fontSize: 17.0, fontWeight: FontWeight.w600, color: Colors.black),
    headlineSmall: GoogleFonts.sourceSansPro(fontSize: 15.5, fontWeight: FontWeight.normal, color: Colors.black),
    titleLarge: GoogleFonts.sourceSansPro(fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.black),
    bodyLarge: GoogleFonts.sourceSansPro(fontSize: 17.0, color: Colors.black),
    bodyMedium: GoogleFonts.sourceSansPro(fontSize: 15.5, color: Colors.black),
  );

  static TextTheme darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.sourceSansPro(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
    displayMedium: GoogleFonts.sourceSansPro(fontSize: 17.0, fontWeight: FontWeight.w700, color: Colors.white),
    displaySmall: GoogleFonts.sourceSansPro(fontSize: 15.5, fontWeight: FontWeight.normal, color: Colors.white),
    headlineMedium: GoogleFonts.sourceSansPro(fontSize: 17.0, fontWeight: FontWeight.w600, color: Colors.white),
    headlineSmall: GoogleFonts.sourceSansPro(fontSize: 15.5, fontWeight: FontWeight.normal, color: Colors.white),
    titleLarge: GoogleFonts.sourceSansPro(fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.white),
    bodyLarge: GoogleFonts.sourceSansPro(fontSize: 17.0, color: Colors.white),
    bodyMedium: GoogleFonts.sourceSansPro(fontSize: 15.5, color: Colors.white),
  );
}
