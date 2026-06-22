import 'package:flutter/material.dart';

import '../../engine/board_layout.dart';
import '../../engine/models/player.dart';
import '../../engine/models/tile.dart';
import 'domino_tile_widget.dart';

/// Vista de la mano de un jugador.
///
/// Si [faceUp] es true (mano del jugador local) muestra los valores y
/// resalta la [selectedTile]. Si es false (oponentes) muestra los
/// lomos apilados.
class HandView extends StatelessWidget {
  final Player player;
  final List<DominoTile> tiles;
  final bool faceUp;
  final DominoTile? selectedTile;
  final Set<DominoTile> validTiles;
  final void Function(DominoTile)? onTileTap;
  final bool isCurrentPlayer;
  final double squareSize;

  const HandView({
    super.key,
    required this.player,
    required this.tiles,
    required this.faceUp,
    required this.squareSize,
    this.selectedTile,
    this.validTiles = const {},
    this.onTileTap,
    this.isCurrentPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return _EmptyHand(name: player.name);
    }

    if (faceUp) {
      return _FaceUpHand(
        tiles: tiles,
        selectedTile: selectedTile,
        validTiles: validTiles,
        onTileTap: onTileTap,
        isCurrentPlayer: isCurrentPlayer,
        squareSize: squareSize,
      );
    }

    return _FaceDownHand(
      count: tiles.length,
      orientation: _opponentOrientation(player.position),
      squareSize: squareSize,
      isCurrentPlayer: isCurrentPlayer,
    );
  }

  TileOrientation _opponentOrientation(PlayerPosition position) {
    // Oponente derecho/izquierdo → fichas en vertical; compañero → horizontal.
    return switch (position) {
      PlayerPosition.right || PlayerPosition.left =>
        TileOrientation.vertical,
      PlayerPosition.top => TileOrientation.horizontal,
      PlayerPosition.bottom => TileOrientation.horizontal,
    };
  }
}

class _EmptyHand extends StatelessWidget {
  final String name;
  const _EmptyHand({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        '$name (sin fichas)',
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
    );
  }
}

class _FaceUpHand extends StatelessWidget {
  final List<DominoTile> tiles;
  final DominoTile? selectedTile;
  final Set<DominoTile> validTiles;
  final void Function(DominoTile)? onTileTap;
  final bool isCurrentPlayer;
  final double squareSize;

  const _FaceUpHand({
    required this.tiles,
    required this.selectedTile,
    required this.validTiles,
    required this.onTileTap,
    required this.isCurrentPlayer,
    required this.squareSize,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final tile in tiles) ...[
            _HandTileButton(
              tile: tile,
              isSelected: tile == selectedTile,
              isValid: isCurrentPlayer && validTiles.contains(tile),
              onTap: isCurrentPlayer && onTileTap != null
                  ? () => onTileTap!(tile)
                  : null,
              squareSize: squareSize,
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _HandTileButton extends StatelessWidget {
  final DominoTile tile;
  final bool isSelected;
  final bool isValid;
  final VoidCallback? onTap;
  final double squareSize;

  const _HandTileButton({
    required this.tile,
    required this.isSelected,
    required this.isValid,
    required this.onTap,
    required this.squareSize,
  });

  @override
  Widget build(BuildContext context) {
    final tileWidget = DominoTileWidget.face(
      tile: tile,
      orientation: TileOrientation.vertical,
      squareSize: squareSize,
      highlighted: isSelected,
    );

    final wrapped = onTap == null
        ? tileWidget
        : GestureDetector(
            onTap: onTap,
            child: AnimatedScale(
              scale: isValid ? 1.0 : 0.95,
              duration: const Duration(milliseconds: 150),
              child: tileWidget,
            ),
          );

    // Ficha seleccionada: padding superior 0 (queda al tope).
    // Ficha no seleccionada: padding superior 4 (se "hunde" hacia abajo).
    return Padding(
      padding: EdgeInsets.only(top: isSelected ? 0 : 4),
      child: wrapped,
    );
  }
}

class _FaceDownHand extends StatelessWidget {
  final int count;
  final TileOrientation orientation;
  final double squareSize;
  final bool isCurrentPlayer;

  const _FaceDownHand({
    required this.count,
    required this.orientation,
    required this.squareSize,
    required this.isCurrentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    if (orientation == TileOrientation.vertical) {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < count; i++) ...[
              DominoTileWidget.back(
                orientation: orientation,
                squareSize: squareSize,
                dim: !isCurrentPlayer,
              ),
              const SizedBox(height: 2),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < count; i++) ...[
            DominoTileWidget.back(
              orientation: orientation,
              squareSize: squareSize,
              dim: !isCurrentPlayer,
            ),
            const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}
