import 'package:flutter/material.dart';

import '../../engine/models/tile.dart';
import '../../engine/board_layout.dart';
import '../theme.dart';

/// Dibuja una ficha de dominó en una posición y orientación concretas.
///
/// Si [tile] es null, dibuja el reverso (lomo) de la ficha. Esto se usa
/// para las manos de los oponentes donde no se muestran los valores.
///
/// Si [compact] es true, la ficha se renderiza con forma cuadrada (1:1)
/// con los dos valores apilados verticalmente, independientemente de la
/// orientación. Se usa en la mano local para que las fichas se vean más
/// "rellenas" sin la proporción 1:2 de una ficha real de dominó.
///
/// El widget NO deduce nada: recibe [connectedValue] y [freeValue]
/// directamente, y los coloca en las posiciones visuales correctas
/// según [orientation] y [connectedEdge]. Toda la lógica de inversión
/// la resuelve [BoardLayout] antes de invocar al widget.
class DominoTileWidget extends StatelessWidget {
  final DominoTile? tile;
  final TileOrientation orientation;
  final ConnectedEdge connectedEdge;

  /// Valor del modelo que se dibuja en el borde conectado a la ficha
  /// anterior. Lo calcula [BoardLayout] a partir de [Move.tileWasSwapped]
  /// y la dirección de crecimiento.
  final int connectedValue;

  /// Valor del modelo que se dibuja en el borde libre (el opuesto al
  /// conectado). Lo calcula [BoardLayout].
  final int freeValue;

  final double squareSize;
  final bool highlighted;
  final bool dim;
  final bool compact;

  const DominoTileWidget({
    super.key,
    required this.tile,
    required this.orientation,
    required this.connectedEdge,
    required this.connectedValue,
    required this.freeValue,
    required this.squareSize,
    this.highlighted = false,
    this.dim = false,
    this.compact = false,
  });

  /// Constructor conveniente para dibujar la mano del jugador local
  /// con valores visibles.
  factory DominoTileWidget.face({
    Key? key,
    required DominoTile tile,
    required TileOrientation orientation,
    required ConnectedEdge connectedEdge,
    required int connectedValue,
    required int freeValue,
    required double squareSize,
    bool highlighted = false,
    bool compact = false,
  }) {
    return DominoTileWidget(
      key: key,
      tile: tile,
      orientation: orientation,
      connectedEdge: connectedEdge,
      connectedValue: connectedValue,
      freeValue: freeValue,
      squareSize: squareSize,
      highlighted: highlighted,
      compact: compact,
    );
  }

  /// Constructor conveniente para dibujar el lomo de una ficha de un
  /// oponente (sin valores visibles).
  factory DominoTileWidget.back({
    Key? key,
    required TileOrientation orientation,
    required double squareSize,
    bool dim = false,
    bool compact = false,
  }) {
    return DominoTileWidget(
      key: key,
      tile: null,
      orientation: orientation,
      connectedEdge: ConnectedEdge.left,
      connectedValue: 0,
      freeValue: 0,
      squareSize: squareSize,
      dim: dim,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double w;
    final double h;
    if (compact) {
      // Modo compacto: ficha cuadrada 1:1 con valores apilados.
      final side = squareSize * 1.5;
      w = side;
      h = side;
    } else if (orientation == TileOrientation.horizontal) {
      w = squareSize * 2;
      h = squareSize;
    } else {
      w = squareSize;
      h = squareSize * 2;
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: _faceColor(),
        border: Border.all(
          color: highlighted ? DominoTheme.selectedTile : DominoTheme.tileBorder,
          width: highlighted ? 2 : 0.5,
        ),
        borderRadius: BorderRadius.circular(squareSize * 0.12),
        boxShadow: [
          if (!dim)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: tile == null
          ? const SizedBox.shrink()
          : _PipsLayout(
              firstValue: _firstValue,
              secondValue: _secondValue,
              squareSize: squareSize,
              orientation: orientation,
              compact: compact,
            ),
    );
  }

  /// Valor que se dibuja en la posición visual "primera":
  /// - horizontal: izquierda
  /// - vertical: arriba
  int get _firstValue {
    if (compact) return connectedValue;
    if (orientation == TileOrientation.horizontal) {
      return connectedEdge == ConnectedEdge.left
          ? connectedValue
          : freeValue;
    }
    // vertical
    return connectedEdge == ConnectedEdge.top
        ? connectedValue
        : freeValue;
  }

  /// Valor que se dibuja en la posición visual "segunda":
  /// - horizontal: derecha
  /// - vertical: abajo
  int get _secondValue {
    if (compact) return freeValue;
    if (orientation == TileOrientation.horizontal) {
      return connectedEdge == ConnectedEdge.left
          ? freeValue
          : connectedValue;
    }
    // vertical
    return connectedEdge == ConnectedEdge.top
        ? freeValue
        : connectedValue;
  }

  Color _faceColor() {
    if (dim) return DominoTheme.opponentTileBack;
    if (tile == null) return DominoTheme.opponentTileBack;
    return DominoTheme.tileFace;
  }
}

/// Disposición de los puntos de un valor (0..6) sobre el espacio disponible.
///
/// En una ficha tradicional (mitad cuadrada) los pips se distribuyen en
/// una rejilla 3x3. En una mitad rectangular de la mano (compact), los
/// pips deben distribuirse en la dimensión **corta** para que la
/// distribución se centre vertical u horizontalmente según el espacio.
class _PipLayout extends StatelessWidget {
  final int value;
  final double size;

  const _PipLayout({required this.value, required this.size});

  static const _positions = <int, List<_PipPos>>{
    0: [],
    1: [_PipPos.center],
    2: [_PipPos.tl, _PipPos.br],
    3: [_PipPos.tl, _PipPos.center, _PipPos.br],
    4: [_PipPos.tl, _PipPos.tr, _PipPos.bl, _PipPos.br],
    5: [_PipPos.tl, _PipPos.tr, _PipPos.center, _PipPos.bl, _PipPos.br],
    6: [_PipPos.tl, _PipPos.tr, _PipPos.ml, _PipPos.bl, _PipPos.br, _PipPos.mr],
  };

  @override
  Widget build(BuildContext context) {
    final pips = _positions[value] ?? const [];
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // La rejilla 4x4 debe llenar ambas dimensiones. Usamos
        // dimensiones distintas para X e Y para que la rejilla se
        // estire y no queden huecos.
        final unitX = w / 4;
        final unitY = h / 4;
        // El tamaño del pip se basa en la unidad menor para que no se
        // corten, pero los centros se calculan con cada unidad.
        final pipSize = (unitX < unitY ? unitX : unitY) * 0.7;
        return Stack(
          children: pips.map((p) {
            final dx = p.x(unitX);
            final dy = p.y(unitY);
            return Positioned(
              left: dx - pipSize / 2,
              top: dy - pipSize / 2,
              width: pipSize,
              height: pipSize,
              child: Container(
                decoration: const BoxDecoration(
                  color: DominoTheme.pipColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

enum _PipPos { tl, tr, ml, mr, bl, br, center }

extension on _PipPos {
  double x(double unit) {
    return switch (this) {
      _PipPos.tl || _PipPos.bl || _PipPos.ml => unit,
      _PipPos.center => unit * 2,
      _PipPos.tr || _PipPos.br || _PipPos.mr => unit * 3,
    };
  }

  double y(double unit) {
    return switch (this) {
      _PipPos.tl || _PipPos.tr => unit,
      _PipPos.ml || _PipPos.mr || _PipPos.center => unit * 2,
      _PipPos.bl || _PipPos.br => unit * 3,
    };
  }
}

/// Componente que dibuja las dos mitades de una ficha con su línea
/// divisoria central.
///
/// [firstValue] es el valor que se dibuja en la posición visual "primera"
/// (izquierda en horizontal, arriba en vertical). [secondValue] es el
/// valor que se dibuja en la posición "segunda" (derecha o abajo).
class _PipsLayout extends StatelessWidget {
  final int firstValue;
  final int secondValue;
  final double squareSize;
  final TileOrientation orientation;
  final bool compact;

  const _PipsLayout({
    required this.firstValue,
    required this.secondValue,
    required this.squareSize,
    required this.orientation,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Modo compacto: siempre columna (cuadrada con valores apilados).
    if (compact) {
      return Column(
        children: [
          Expanded(
            child: _PipLayout(
              value: firstValue,
              size: squareSize,
            ),
          ),
          Container(
            height: 1.5,
            color: DominoTheme.tileBorder,
          ),
          Expanded(
            child: _PipLayout(
              value: secondValue,
              size: squareSize,
            ),
          ),
        ],
      );
    }

    // Ficha vertical (1:2): los dos valores se apilan en columna,
    // separados por una línea horizontal.
    if (orientation == TileOrientation.vertical) {
      return Column(
        children: [
          Expanded(
            child: _PipLayout(
              value: firstValue,
              size: squareSize,
            ),
          ),
          Container(
            height: 1.5,
            color: DominoTheme.tileBorder,
          ),
          Expanded(
            child: _PipLayout(
              value: secondValue,
              size: squareSize,
            ),
          ),
        ],
      );
    }

    // Ficha horizontal (2:1): los dos valores se ponen en fila,
    // separados por una línea vertical.
    return Row(
      children: [
        Expanded(
          child: _PipLayout(
            value: firstValue,
            size: squareSize,
          ),
        ),
        Container(
          width: 1.5,
          color: DominoTheme.tileBorder,
        ),
        Expanded(
          child: _PipLayout(
            value: secondValue,
            size: squareSize,
          ),
        ),
      ],
    );
  }
}
