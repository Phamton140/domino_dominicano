import '../models/tile.dart';

/// Constantes de puntuación del Dominó Dominicano.
class ScoringConstants {
  static const int targetScore = 200;
  static const int threshold170 = 170;
  static const int bonusCapicua = 30;
  static const int bonusPaseRedondo = 30;
  static const int bonusSalidaDoble = 30;
  static const int bonusSalidaCompletaDoble = 60;
  static const int bonusSalidaNormal = 60;
}

/// Tipos de bonificación de salida.
enum StartBonusType {
  none,
  double30,
  double60,
  normal60,
}

class ScoringRules {
  const ScoringRules._();

  /// Calcula los puntos totales de una mano de fichas.
  static int handScore(List<DominoTile> hand) {
    return hand.fold(0, (sum, tile) => sum + tile.totalValue);
  }

  /// Determina si un equipo con la puntuación dada puede recibir puntos
  /// por pase de salida o pase redondo.
  static bool canReceivePassBonus(int teamScore) =>
      teamScore < ScoringConstants.threshold170;

  /// Determina el tipo de bonificación de salida correspondiente.
  ///
  /// La evaluación se realiza después de conocer las capacidades de juego
  /// de los jugadores involucrados.
  ///
  /// [nextPlayerCanPlay]: indica si el jugador siguiente a la salida puede jugar.
  /// [partnerCanPlay]: indica si el compañero del jugador que salió puede jugar.
  /// [afterPartnerCanPlay]: indica si el cuarto jugador puede jugar.
  static StartBonusType determineStartBonus({
    required bool startTileIsDouble,
    required bool nextPlayerCanPlay,
    required bool partnerCanPlay,
    required bool afterPartnerCanPlay,
  }) {
    if (startTileIsDouble) {
      if (!nextPlayerCanPlay) {
        if (partnerCanPlay) {
          // El compañero sí tiene jugada válida.
          return StartBonusType.double30;
        }
        if (!afterPartnerCanPlay) {
          // Ninguno de los tres jugadores restantes puede jugar.
          return StartBonusType.double60;
        }
      }
      // Se pierde el pase de salida.
      return StartBonusType.none;
    } else {
      // Salida con ficha normal.
      if (!nextPlayerCanPlay) {
        return StartBonusType.normal60;
      }
      return StartBonusType.none;
    }
  }

  /// Puntos correspondientes a un tipo de bonificación de salida.
  static int pointsForStartBonus(StartBonusType type) {
    return switch (type) {
      StartBonusType.none => 0,
      StartBonusType.double30 => ScoringConstants.bonusSalidaDoble,
      StartBonusType.double60 => ScoringConstants.bonusSalidaCompletaDoble,
      StartBonusType.normal60 => ScoringConstants.bonusSalidaNormal,
    };
  }

  /// Indica si una jugada de dominación es capicúa.
  ///
  /// Requisitos:
  /// - La ficha jugada encaja con ambos extremos abiertos.
  /// - Los extremos abiertos tienen valores diferentes.
  static bool isCapicua({
    required int leftEnd,
    required int rightEnd,
    required DominoTile playedTile,
  }) {
    if (leftEnd == rightEnd) return false;

    final matchesBoth =
        (playedTile.left == leftEnd && playedTile.right == rightEnd) ||
            (playedTile.left == rightEnd && playedTile.right == leftEnd);

    return matchesBoth;
  }

  /// Calcula los puntos de una dominación.
  static int dominationPoints({
    required List<int> allHandScores,
    required bool isCapicua,
  }) {
    final tableTotal = allHandScores.fold(0, (sum, score) => sum + score);
    final bonus = isCapicua ? ScoringConstants.bonusCapicua : 0;
    return tableTotal + bonus;
  }

  /// Calcula los puntos de un tranque.
  static int tranquePoints(List<int> allHandScores) {
    return allHandScores.fold(0, (sum, score) => sum + score);
  }
}
