import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class AppTheme {
  ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    textTheme: TextDisplayTheme.lightTextTheme,
    inputDecorationTheme: TextFieldTheme.lightInputDecorationTheme,
  );

  ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    textTheme: TextDisplayTheme.darkTextTheme,
    inputDecorationTheme: TextFieldTheme.darkInputDecorationTheme,
  );
}

final AppTheme globalTheme = AppTheme();
