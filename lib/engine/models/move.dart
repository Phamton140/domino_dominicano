import 'player.dart';
import 'tile.dart';

/// Lado de la mesa donde se coloca una ficha.
enum BoardSide {
  left,
  right,
}

/// Representa una jugada realizada por un jugador.
class Move {
  final Player player;
  final DominoTile tile;
  final BoardSide side;

  /// Indica si la ficha fue colocada invertida para que coincidiera
  /// con el extremo de la mesa.
  final bool tileWasSwapped;

  const Move({
    required this.player,
    required this.tile,
    required this.side,
    this.tileWasSwapped = false,
  });

  @override
  String toString() => '${player.name} juega $tile por ${side.name}';
}
