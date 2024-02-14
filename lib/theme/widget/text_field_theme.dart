import 'package:flutter/material.dart';

class TextFieldTheme {
  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    prefixIconColor: Colors.blue,
    floatingLabelStyle: const TextStyle(color: Colors.teal),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7.5),
      borderSide: const BorderSide(width: 2, color: Color.fromARGB(255, 151, 82, 57)),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    prefixIconColor: Colors.blue,
    floatingLabelStyle: const TextStyle(color: Colors.teal),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7.5),
      borderSide: const BorderSide(width: 2, color: Color.fromARGB(255, 151, 82, 57)),
    ),
  );
}