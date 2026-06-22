import 'tile.dart';

/// Posición fija de un jugador en la mesa, vista desde la perspectiva
/// del jugador local.
enum PlayerPosition {
  bottom, // jugador local
  right, // adversario derecho
  top, // compañero
  left, // adversario izquierdo
}

/// Representa un jugador de la partida.
class Player {
  final String id;
  final String name;
  final PlayerPosition position;
  final String teamId;
  List<DominoTile> hand;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.teamId,
    List<DominoTile>? hand,
  }) : hand = hand ?? [];

  bool get isLocal => position == PlayerPosition.bottom;

  bool get isPartner => position == PlayerPosition.top;

  bool get isOpponent =>
      position == PlayerPosition.left || position == PlayerPosition.right;

  /// Suma de puntos de las fichas que aún tiene en la mano.
  int get handScore => hand.fold(0, (sum, tile) => sum + tile.totalValue);

  /// Cantidad de fichas restantes.
  int get tileCount => hand.length;

  /// Indica si la mano está vacía (dominación).
  bool get hasEmptyHand => hand.isEmpty;

  bool hasTile(DominoTile tile) => hand.any((t) => t == tile);

  void removeTile(DominoTile tile) {
    final index = hand.indexWhere((t) => t == tile);
    if (index == -1) {
      throw StateError('El jugador $id no posee la ficha $tile');
    }
    hand.removeAt(index);
  }

  Player copy() {
    return Player(
      id: id,
      name: name,
      position: position,
      teamId: teamId,
      hand: List.of(hand),
    );
  }
}
