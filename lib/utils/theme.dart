import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData.light().copyWith(
  colorScheme: ThemeData.light().colorScheme.copyWith(
        primary: Colors.orange,
      ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.orange,
  ),
);

ThemeData darkTheme = ThemeData.dark().copyWith(
  colorScheme: ThemeData.dark().colorScheme.copyWith(
        primary: Colors.orange,
      ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.orange,
  ),
);