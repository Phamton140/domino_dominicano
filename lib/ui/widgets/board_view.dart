import 'package:flutter/material.dart';

import '../../engine/board_layout.dart';
import '../../engine/models/move.dart';
import '../../engine/models/player.dart';
import 'domino_tile_widget.dart';
import '../theme.dart';

/// Tamaño lógico de una ficha en la mesa, en píxeles lógicos.
///
/// Es un valor FIJO: las fichas no cambian de tamaño ni al añadirse
/// nuevas fichas a la cadena ni al redimensionarse el área disponible.
/// La cámara virtual se desplaza sobre la cadena para que entre toda
/// en pantalla, pero las fichas conservan siempre sus dimensiones.
const double kBoardTileSquareSize = 26.0;

/// Vista de la mesa de dominó.
///
/// Recibe los [moves] de la ronda actual y el [starterPosition] y dibuja
/// cada ficha en su posición calculada por [BoardLayout] usando un
/// [kBoardTileSquareSize] constante. La cadena puede exceder el área
/// visible: en ese caso se centra dentro de un `SingleChildScrollView`
/// y el usuario puede hacer scroll/pinch para verla.
class BoardView extends StatelessWidget {
  final List<Move> moves;
  final PlayerPosition starterPosition;

  const BoardView({
    super.key,
    required this.moves,
    required this.starterPosition,
  });

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return const _EmptyBoard();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // El BoardLayout coloca la primera ficha en el centro del
        // tableBounds y rota la dirección (formando la Z clásica
        // del dominó) cuando la siguiente ficha está a punto de
        // colapsar con el borde. Usamos el área visible como
        // tableBounds para activar el patrón en Z. allowOverflow
        // permite que fichas que excedan el área se sigan renderizando
        // (el InteractiveViewer permite pan/zoom).
        final layout = BoardLayout(
          moves: moves,
          starterPosition: starterPosition,
          squareSize: kBoardTileSquareSize,
          tableBounds: Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
          allowOverflow: true,
        );
        final geometries = layout.compute();

        // El área de juego es FIJA: ocupa todo el espacio disponible
        // y NO cambia de tamaño al añadirse fichas. La primera ficha
        // siempre queda en su centro, sin importar cuántas fichas se
        // coloquen. Si la cadena excede el área, el InteractiveViewer
        // permite pan/zoom.
        final areaWidth = constraints.maxWidth;
        final areaHeight = constraints.maxHeight;
        final centerX = areaWidth / 2;
        final centerY = areaHeight / 2;
        final firstTileW = geometries.first.width;
        final firstTileH = geometries.first.height;

        return Container(
          decoration: BoxDecoration(
            color: DominoTheme.tableGreen,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DominoTheme.tableBorder, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: InteractiveViewer(
              minScale: 0.4,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(200),
              child: SizedBox(
                width: areaWidth,
                height: areaHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                for (final g in geometries)
                  Positioned(
                    // Posición relativa al centro del área. La
                    // primera ficha está en tableBounds.center;
                    // la trasladamos al centro del área visible
                    // (centerX, centerY). Las siguientes se
                    // posicionan en torno a ese centro.
                    left: centerX + (g.center.dx - areaWidth / 2) - g.width / 2,
                    top: centerY + (g.center.dy - areaHeight / 2) - g.height / 2,
                    width: g.width,
                    height: g.height,
                    child: DominoTileWidget.face(
                      tile: g.move.tile,
                      orientation: g.orientation,
                      squareSize: g.squareSize,
                      swapped: g.move.tileWasSwapped,
                    ),
                  ),
                    // Marcar el centro del área con un widget invisible
                    // para anclar el InteractiveViewer ahí. Sin esto,
                    // el viewer centra el contenido en su tamaño
                    // intrínseco, que sería 0 (las Positioned con left
                    // negativos no aportan tamaño).
                    Positioned(
                      left: centerX - firstTileW / 2,
                      top: centerY - firstTileH / 2,
                      width: firstTileW,
                      height: firstTileH,
                      child: const IgnorePointer(
                        child: SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DominoTheme.tableGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DominoTheme.tableBorder, width: 2),
      ),
      child: const Center(
        child: Text(
          'Esperando la primera ficha…',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }
}
