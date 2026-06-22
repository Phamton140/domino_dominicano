import 'dart:ui';

import 'models/move.dart';
import 'models/player.dart';
import 'models/tile.dart';

/// Orientación visual de una ficha sobre la mesa.
enum TileOrientation {
  horizontal, // ancho = 2 * squareSize, alto = squareSize
  vertical, // ancho = squareSize, alto = 2 * squareSize
}

/// Dirección de crecimiento de un extremo de la mesa.
enum Direction {
  right,
  left,
  up,
  down,
}

/// Geometría calculada de una ficha colocada sobre la mesa.
class TileGeometry {
  final Move move;
  final Offset center;
  final TileOrientation orientation;
  final double _squareSize;

  const TileGeometry({
    required this.move,
    required this.center,
    required this.orientation,
    required double squareSize,
  }) : _squareSize = squareSize;

  /// Tamaño del lado corto de la ficha (mitad del largo).
  double get squareSize => _squareSize;

  /// Ancho de la ficha en píxeles.
  double get width => orientation == TileOrientation.horizontal
      ? 2 * _squareSize
      : _squareSize;

  /// Alto de la ficha en píxeles.
  double get height => orientation == TileOrientation.horizontal
      ? _squareSize
      : 2 * _squareSize;

  /// Rectángulo delimitador de la ficha.
  Rect get bounds => Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      );

  /// Indica si esta ficha se solapa con otra.
  bool overlaps(TileGeometry other) {
    return bounds.overlaps(other.bounds);
  }

  @override
  String toString() =>
      'TileGeometry(${move.tile}, center: $center, orientation: $orientation)';
}

/// Estado de crecimiento de uno de los extremos de la mesa.
class _EndState {
  /// Punto de conexión donde se unirá la siguiente ficha.
  Offset connectionPoint;

  /// Dirección actual de crecimiento.
  Direction direction;

  /// Geometría de la última ficha colocada en este extremo.
  TileGeometry lastGeometry;

  _EndState({
    required this.connectionPoint,
    required this.direction,
    required this.lastGeometry,
  });
}

/// Calcula la disposición geométrica de las fichas sobre la mesa.
///
/// Responsabilidades:
/// - Colocar la primera ficha en el centro de la mesa.
/// - Aplicar la orientación visual correcta según quién realizó la salida.
/// - Colocar los dobles perpendiculares a la ficha anterior.
/// - Implementar el crecimiento en "Z" cuando se alcanzan los límites.
/// - Mantener las fichas conectadas visualmente sin superposiciones.
///
/// La fuente de verdad sobre la inversión de cada ficha (qué cara queda
/// expuesta hacia afuera) es [Move.tileWasSwapped], que el `Board` y el
/// `Round` calculan y persisten. El layout geométrico no recalcula la
/// inversión; sólo consume ese flag a través de [TileGeometry].
class BoardLayout {
  final List<Move> moves;
  final PlayerPosition starterPosition;
  final double squareSize;
  final Rect tableBounds;

  /// Si es true, las fichas pueden exceder [tableBounds] sin lanzar
  /// error (útil para renderizar cadenas largas en áreas pequeñas con
  /// scroll/zoom). Si es false (por defecto), se lanza [StateError]
  /// cuando no hay hueco.
  final bool allowOverflow;

  BoardLayout({
    required this.moves,
    required this.starterPosition,
    required this.squareSize,
    required this.tableBounds,
    this.allowOverflow = false,
  });

  /// Calcula la geometría de todas las fichas jugadas.
  List<TileGeometry> compute() {
    if (moves.isEmpty) return [];

    final geometries = <TileGeometry>[];

    final firstMove = moves.first;
    final firstOrientation = _firstTileOrientation(firstMove.tile);
    final firstGeometry = TileGeometry(
      move: firstMove,
      center: tableBounds.center,
      orientation: firstOrientation,
      squareSize: squareSize,
    );
    geometries.add(firstGeometry);

    final leftEnd = _createInitialEnd(firstGeometry, BoardSide.left);
    final rightEnd = _createInitialEnd(firstGeometry, BoardSide.right);

    for (int i = 1; i < moves.length; i++) {
      final move = moves[i];
      final end = move.side == BoardSide.left ? leftEnd : rightEnd;
      final geometry = _placeAtEnd(end, move, geometries);
      geometries.add(geometry);
      _updateEnd(end, geometry);
    }

    return geometries;
  }

  /// Determina la orientación visual de la primera ficha según quién salió.
  ///
  /// Regla: la ficha larga debe "apuntar" hacia el jugador local.
  /// - Si sale local o compañero con doble: horizontal.
  /// - Si sale adversario con doble: vertical.
  /// - Si sale local o compañero con ficha normal: vertical.
  /// - Si sale adversario con ficha normal: horizontal.
  TileOrientation _firstTileOrientation(DominoTile tile) {
    final isLocalOrPartner = starterPosition == PlayerPosition.bottom ||
        starterPosition == PlayerPosition.top;

    if (tile.isDouble) {
      return isLocalOrPartner
          ? TileOrientation.horizontal
          : TileOrientation.vertical;
    }

    return isLocalOrPartner
        ? TileOrientation.vertical
        : TileOrientation.horizontal;
  }

  _EndState _createInitialEnd(TileGeometry firstGeometry, BoardSide side) {
    final halfWidth = firstGeometry.width / 2;

    final direction = side == BoardSide.left ? Direction.left : Direction.right;
    final connectionPoint = side == BoardSide.left
        ? firstGeometry.center.translate(-halfWidth, 0)
        : firstGeometry.center.translate(halfWidth, 0);

    return _EndState(
      connectionPoint: connectionPoint,
      direction: direction,
      lastGeometry: firstGeometry,
    );
  }

  /// Coloca [move] en el extremo [end], rotando 90° sobre la última ficha
  /// si la posición natural colisiona o se sale de la mesa.
  ///
  /// Tras 4 intentos fallidos lanza [StateError] indicando que la mesa
  /// no tiene espacio para la ficha.
  TileGeometry _placeAtEnd(
    _EndState end,
    Move move,
    List<TileGeometry> existing,
  ) {
    for (int attempts = 0; attempts < 4; attempts++) {
      final orientation = _tileOrientation(end, move.tile);
      final center = _centerFromConnection(
        end.connectionPoint,
        end.direction,
        orientation,
      );
      final geometry = TileGeometry(
        move: move,
        center: center,
        orientation: orientation,
        squareSize: squareSize,
      );

      if (_canPlace(geometry, existing)) {
        return geometry;
      }

      // Si se permite overflow, salir del loop cuando ya probamos
      // todas las direcciones y aún así no cabe. En ese caso,
      // colocamos la ficha en la última posición intentada aunque
      // se salga de los límites.
      if (allowOverflow && attempts == 3) {
        return geometry;
      }

      _rotateEnd(end);
    }

    throw StateError(
      'No se pudo colocar la ficha ${move.tile} dentro de los límites de la mesa',
    );
  }

  /// Rota la dirección de crecimiento 90° en sentido antihorario y
  /// reposiciona el punto de conexión para que la siguiente ficha
  /// toque a la última colocada.
  ///
  /// Patrón antihorario (igual que las manecillas de un reloj vistas
  /// en un espejo):
  /// - `right` → `up`   → connectionPoint en el borde superior.
  /// - `up`    → `left` → connectionPoint en el borde izquierdo.
  /// - `left`  → `down` → connectionPoint en el borde inferior.
  /// - `down`  → `right` → connectionPoint en el borde derecho.
  ///
  /// El connectionPoint se coloca en el centro del borde de la última
  /// ficha en la NUEVA dirección de crecimiento, de modo que la
  /// siguiente ficha se conecte tocando ese borde.
  void _rotateEnd(_EndState end) {
    final last = end.lastGeometry;
    final halfWidth = last.width / 2;
    final halfHeight = last.height / 2;

    final pivot = switch (end.direction) {
      // Estaba creciendo a la derecha → ahora hacia arriba.
      // Conexión por el borde superior de la última ficha.
      Direction.right => Offset(last.center.dx, last.center.dy - halfHeight),
      // Estaba creciendo hacia arriba → ahora hacia la izquierda.
      // Conexión por el borde izquierdo de la última ficha.
      Direction.up => Offset(last.center.dx - halfWidth, last.center.dy),
      // Estaba creciendo a la izquierda → ahora hacia abajo.
      // Conexión por el borde inferior de la última ficha.
      Direction.left => Offset(last.center.dx, last.center.dy + halfHeight),
      // Estaba creciendo hacia abajo → ahora hacia la derecha.
      // Conexión por el borde derecho de la última ficha.
      Direction.down => Offset(last.center.dx + halfWidth, last.center.dy),
    };

    end.direction = _nextDirection(end.direction);
    end.connectionPoint = pivot;
  }

  /// Orientación de [tile] cuando se coloca saliendo de [end].
  ///
  /// Reglas:
  /// - Doble: perpendicular a la última ficha del extremo.
  /// - Ficha normal: sigue la dirección de crecimiento (eje largo en la
  ///   dirección de avance).
  TileOrientation _tileOrientation(_EndState end, DominoTile tile) {
    if (tile.isDouble) {
      return end.lastGeometry.orientation == TileOrientation.horizontal
          ? TileOrientation.vertical
          : TileOrientation.horizontal;
    }

    return switch (end.direction) {
      Direction.right || Direction.left => TileOrientation.horizontal,
      Direction.up || Direction.down => TileOrientation.vertical,
    };
  }

  /// Centro de la nueva ficha a partir del punto de conexión, dirección
  /// y orientación. La ficha se coloca con su borde largo pegado al
  /// connectionPoint en la dirección de crecimiento.
  Offset _centerFromConnection(
    Offset connection,
    Direction direction,
    TileOrientation orientation,
  ) {
    final dx = orientation == TileOrientation.horizontal
        ? squareSize
        : squareSize / 2;
    final dy = orientation == TileOrientation.horizontal
        ? squareSize / 2
        : squareSize;

    return switch (direction) {
      Direction.right => connection.translate(dx, 0),
      Direction.left => connection.translate(-dx, 0),
      Direction.up => connection.translate(0, -dy),
      Direction.down => connection.translate(0, dy),
    };
  }

  /// Tras colocar [geometry], actualiza el extremo: nuevo connectionPoint
  /// en el borde largo de la ficha, en la dirección de crecimiento.
  void _updateEnd(_EndState end, TileGeometry geometry) {
    final halfWidth = geometry.width / 2;
    final halfHeight = geometry.height / 2;

    end.connectionPoint = switch (end.direction) {
      Direction.right => geometry.center.translate(halfWidth, 0),
      Direction.left => geometry.center.translate(-halfWidth, 0),
      Direction.up => geometry.center.translate(0, -halfHeight),
      Direction.down => geometry.center.translate(0, halfHeight),
    };
    end.lastGeometry = geometry;
  }

  /// Indica si una ficha cabe dentro de la mesa y no solapa con las
  /// fichas ya colocadas.
  bool _canPlace(TileGeometry geometry, List<TileGeometry> existing) {
    if (!_fitsInBounds(geometry)) {
      return false;
    }

    for (final other in existing) {
      if (geometry.overlaps(other)) {
        return false;
      }
    }

    return true;
  }

  /// Indica si la ficha está completamente contenida dentro de la mesa.
  bool _fitsInBounds(TileGeometry geometry) {
    final bounds = geometry.bounds;
    return bounds.left >= tableBounds.left &&
        bounds.right <= tableBounds.right &&
        bounds.top >= tableBounds.top &&
        bounds.bottom <= tableBounds.bottom;
  }

  /// Siguiente dirección en el patrón de crecimiento en Z (rotación 90°
  /// antihoraria).
  Direction _nextDirection(Direction current) {
    return switch (current) {
      Direction.right => Direction.up,
      Direction.up => Direction.left,
      Direction.left => Direction.down,
      Direction.down => Direction.right,
    };
  }
}
