import 'models/move.dart';
import 'models/tile.dart';

/// Representa una ficha ya colocada sobre la mesa.
class PlayedTile {
  final DominoTile tile;

  /// Indica si la ficha fue invertida al colocarse.
  final bool wasSwapped;

  const PlayedTile(this.tile, this.wasSwapped);

  /// Valor expuesto en el extremo izquierdo de la cadena.
  int get exposedLeft => wasSwapped ? tile.right : tile.left;

  /// Valor expuesto en el extremo derecho de la cadena.
  int get exposedRight => wasSwapped ? tile.left : tile.right;
}

/// Representa el estado de la mesa de dominó.
class Board {
  final List<PlayedTile> _playedTiles = [];

  bool get isEmpty => _playedTiles.isEmpty;

  int get length => _playedTiles.length;

  List<PlayedTile> get playedTiles => List.unmodifiable(_playedTiles);

  /// Valor del extremo izquierdo. -1 si la mesa está vacía.
  int get leftEnd =>
      _playedTiles.isEmpty ? -1 : _playedTiles.first.exposedLeft;

  /// Valor del extremo derecho. -1 si la mesa está vacía.
  int get rightEnd =>
      _playedTiles.isEmpty ? -1 : _playedTiles.last.exposedRight;

  /// Indica si ambos extremos abiertos tienen el mismo valor.
  bool get endsAreEqual => !isEmpty && leftEnd == rightEnd;

  /// Coloca la primera ficha de la ronda en el centro de la mesa.
  ///
  /// No se realiza ninguna validación de coincidencia porque es la salida.
  void placeFirst(DominoTile tile) {
    if (_playedTiles.isNotEmpty) {
      throw StateError('La mesa ya tiene fichas');
    }
    _playedTiles.add(PlayedTile(tile, false));
  }

  /// Indica si se puede colocar la ficha en el extremo izquierdo.
  bool canPlaceOnLeft(DominoTile tile) => !isEmpty && tile.matches(leftEnd);

  /// Indica si se puede colocar la ficha en el extremo derecho.
  bool canPlaceOnRight(DominoTile tile) => !isEmpty && tile.matches(rightEnd);

  /// Coloca la ficha en el extremo izquierdo.
  ///
  /// La ficha se invierte cuando su lado izquierdo coincide con el extremo
  /// de la mesa, de modo que el lado derecho de la ficha quede hacia adentro
  /// y el lado izquierdo quede como nuevo extremo libre.
  void placeOnLeft(DominoTile tile) {
    if (!canPlaceOnLeft(tile)) {
      throw StateError('No se puede colocar $tile en el extremo izquierdo');
    }
    final swapped = tile.left == leftEnd;
    _playedTiles.insert(0, PlayedTile(tile, swapped));
  }

  /// Coloca la ficha en el extremo derecho.
  ///
  /// La ficha se invierte cuando su lado izquierdo no coincide con el extremo
  /// de la mesa, de modo que el lado izquierdo de la ficha quede hacia adentro
  /// y el lado derecho quede como nuevo extremo libre.
  void placeOnRight(DominoTile tile) {
    if (!canPlaceOnRight(tile)) {
      throw StateError('No se puede colocar $tile en el extremo derecho');
    }
    final swapped = tile.left != rightEnd;
    _playedTiles.add(PlayedTile(tile, swapped));
  }

  /// Coloca una ficha respetando la regla de extremos iguales.
  ///
  /// Si ambos extremos tienen el mismo valor, la ficha debe colocarse
  /// obligatoriamente por el lado derecho (lado más cercano).
  /// Devuelve el lado por el cual se colocó.
  BoardSide placeTile(DominoTile tile) {
    if (isEmpty) {
      placeFirst(tile);
      return BoardSide.right;
    }

    final canLeft = canPlaceOnLeft(tile);
    final canRight = canPlaceOnRight(tile);

    if (!canLeft && !canRight) {
      throw StateError('La ficha $tile no puede colocarse en ningún extremo');
    }

    if (endsAreEqual) {
      // Doble punta: se fuerza a jugar por la derecha.
      if (!canRight) {
        throw StateError('Doble punta: la ficha debe jugar por la derecha');
      }
      placeOnRight(tile);
      return BoardSide.right;
    }

    if (canRight) {
      placeOnRight(tile);
      return BoardSide.right;
    }

    placeOnLeft(tile);
    return BoardSide.left;
  }



  /// Devuelve todos los lados válidos para colocar la ficha.
  ///
  /// Si los extremos son iguales, devuelve solo el lado derecho
  /// (lado más cercano), aunque la ficha también encaje por el izquierdo.
  List<BoardSide> validSidesFor(DominoTile tile) {
    if (isEmpty) return [BoardSide.right];

    final canLeft = canPlaceOnLeft(tile);
    final canRight = canPlaceOnRight(tile);

    if (!canLeft && !canRight) return [];

    if (endsAreEqual) {
      return canRight ? [BoardSide.right] : [];
    }

    final sides = <BoardSide>[];
    if (canRight) sides.add(BoardSide.right);
    if (canLeft) sides.add(BoardSide.left);
    return sides;
  }

  void clear() {
    _playedTiles.clear();
  }
}
