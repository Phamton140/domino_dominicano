import 'dart:math';

import '../../engine/models/move.dart';
import '../../engine/round.dart';

/// Bot dummy: juega la primera ficha válida disponible.
///
/// Suficiente para la fase 3 (validar la UI en local). Será reemplazado
/// por bots más inteligentes en la fase 5.
class RandomBot {
  final Random? _random;

  RandomBot({Random? random}) : _random = random;

  /// Elige una jugada para el jugador [playerIndex] de [round].
  /// Devuelve null si el jugador debe pasar.
  Move? pickMove(Round round, int playerIndex) {
    final moves = round.validMovesFor(playerIndex);
    if (moves.isEmpty) return null;
    if (_random == null) return moves.first;
    return moves[_random.nextInt(moves.length)];
  }
}
