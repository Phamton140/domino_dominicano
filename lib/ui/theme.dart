import 'package:flutter/material.dart';

/// Paleta y estilos compartidos por la UI del juego.
class DominoTheme {
  DominoTheme._();

  /// Color de la mesa (tapete verde tradicional).
  static const Color tableGreen = Color(0xFF1E6B3A);

  /// Color del borde exterior del tapete.
  static const Color tableBorder = Color(0xFF0F3D20);

  /// Color de la cara de las fichas (marfil).
  static const Color tileFace = Color(0xFFF5EFE0);

  /// Color del borde de las fichas.
  static const Color tileBorder = Color(0xFF2B2B2B);

  /// Color de los puntos de las fichas.
  static const Color pipColor = Color(0xFF111111);

  /// Color de las fichas del compañero (azul) y oponentes (rojo).
  static const Color localTileBack = Color(0xFF1B4F8C);
  static const Color opponentTileBack = Color(0xFFB0413E);

  /// Color de la ficha seleccionada en la mano local.
  static const Color selectedTile = Color(0xFFFFD24A);

  /// Color de las jugadas válidas resaltadas.
  static const Color validHint = Color(0xFF6BD66B);

  /// Construye el [ThemeData] base de la app.
  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tableGreen,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: tableBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: tableBorder,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
