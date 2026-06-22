import 'package:flutter/material.dart';

import '../../engine/models/tile.dart';
import '../game_controller.dart';
import '../widgets/board_view.dart';
import '../widgets/hand_view.dart';
import '../widgets/score_panel.dart';

/// Pantalla principal con la partida en curso.
class GameScreen extends StatefulWidget {
  final GameController controller;

  const GameScreen({super.key, required this.controller});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  DominoTile? _selectedTile;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    // Si la ronda terminó, mostrar diálogo.
    if (widget.controller.phase == GamePhase.roundFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRoundResult());
    } else if (widget.controller.phase == GamePhase.gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOver());
    }
    if (mounted) setState(() {});
  }

  void _showRoundResult() {
    final result = widget.controller.lastResult;
    if (result == null) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Fin de ronda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.description),
              const SizedBox(height: 8),
              Text('+${result.pointsAwarded} puntos'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.controller.continueAfterRound();
              },
              child: const Text('Siguiente ronda'),
            ),
          ],
        );
      },
    );
  }

  void _showGameOver() {
    final winner = widget.controller.game.teams[
        widget.controller.game.winnerTeamId];
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Partida terminada'),
          content: Text('¡${winner?.name ?? "?"} gana la partida!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final players = c.players;
    final local = c.localPlayer;
    final moves = c.currentMoves;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dominó Dominicano'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Salir de la partida',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          ScorePanel(
            teamA: c.game.teams['A']!,
            teamB: c.game.teams['B']!,
            roundNumber: c.game.roundNumber,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Mano del compañero (arriba).
                  SizedBox(
                    height: 64,
                    child: _opponentHand(c, players[2]),
                  ),
                  // Fila central: mano izquierda, mesa, mano derecha.
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: _opponentHand(c, players[3]),
                        ),
                        Expanded(
                          child: BoardView(
                            moves: moves,
                            starterPosition: local.position,
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: _opponentHand(c, players[1]),
                        ),
                      ],
                    ),
                  ),
                  // Controles.
                  _ControlsBar(
                    controller: c,
                    selectedTile: _selectedTile,
                    onPass: _onPass,
                    onPlay: _onPlay,
                  ),
                  // Mano local.
                  SizedBox(
                    height: 80,
                    child: _localHand(c),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opponentHand(GameController c, dynamic player) {
    return HandView(
      player: player,
      tiles: List<DominoTile>.from(player.hand),
      faceUp: false,
      isCurrentPlayer: c.currentPlayer.id == player.id,
      squareSize: 18,
    );
  }

  Widget _localHand(GameController c) {
    return HandView(
      player: c.localPlayer,
      tiles: List<DominoTile>.from(c.localPlayer.hand),
      faceUp: true,
      selectedTile: _selectedTile,
      validTiles: c.localValidTiles,
      isCurrentPlayer: c.isLocalTurn,
      squareSize: 30,
      onTileTap: _onTileTap,
    );
  }

  void _onTileTap(DominoTile tile) {
    final c = widget.controller;
    if (!c.isLocalTurn) return;
    final valid = c.validMovesForLocal.where((m) => m.tile == tile).toList();
    if (valid.isEmpty) {
      setState(() {
        _selectedTile = null;
      });
      return;
    }
    if (valid.length == 1) {
      setState(() {
        _selectedTile = tile;
      });
    } else {
      setState(() {
        _selectedTile = _selectedTile == tile ? null : tile;
      });
    }
  }

  void _onPlay() {
    final c = widget.controller;
    if (_selectedTile == null) return;
    if (c.playTile(_selectedTile!)) {
      setState(() {
        _selectedTile = null;
      });
    }
  }

  void _onPass() {
    final c = widget.controller;
    if (c.pass()) {
      setState(() {
        _selectedTile = null;
      });
    }
  }
}

class _ControlsBar extends StatelessWidget {
  final GameController controller;
  final DominoTile? selectedTile;
  final VoidCallback onPlay;
  final VoidCallback onPass;

  const _ControlsBar({
    required this.controller,
    required this.selectedTile,
    required this.onPlay,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final canPlay = selectedTile != null && c.isLocalTurn;
    final canPass = c.isLocalTurn && !c.localCanPlay;
    final statusText = _statusText();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: canPass ? onPass : null,
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Pasar'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: canPlay ? onPlay : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Jugar'),
          ),
        ],
      ),
    );
  }

  String _statusText() {
    final c = controller;
    if (c.phase == GamePhase.roundFinished) {
      return 'Ronda terminada — toca "Siguiente" en el diálogo';
    }
    if (c.phase == GamePhase.gameOver) {
      return 'Partida terminada';
    }
    if (!c.isLocalTurn) {
      return 'Turno de ${c.currentPlayer.name}…';
    }
    if (c.localCanPlay) {
      return 'Tu turno — toca una ficha válida';
    }
    return 'Tu turno — no tienes jugadas, pasa';
  }
}
