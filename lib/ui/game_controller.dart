import 'dart:async';

import 'package:flutter/foundation.dart';

import '../engine/game.dart';
import '../engine/models/move.dart';
import '../engine/models/player.dart';
import '../engine/models/round_result.dart';
import '../engine/models/tile.dart';
import 'bots/random_bot.dart';

/// Estado de alto nivel de la UI.
enum GamePhase { playing, roundFinished, gameOver }

/// Adaptador entre la UI y el motor del juego.
///
/// Mantiene el [Game] subyacente, expone una vista inmutable del estado
/// actual y aplica automáticamente las bonificaciones pendientes y los
/// turnos de los bots.
class GameController extends ChangeNotifier {
  final Game _game;
  final RandomBot _bot = RandomBot();

  /// Inyectable para tests: si se provee, los bots duermen este tiempo
  /// entre jugadas para que la UI pueda animarlas.
  final Duration botDelay;

  Timer? _botTimer;
  bool _disposed = false;

  /// Si es true, los bots juegan automáticamente. False para depuración.
  bool botsEnabled;

  GameController({
    Game? game,
    this.botDelay = const Duration(milliseconds: 600),
    this.botsEnabled = true,
  }) : _game = game ?? Game.createLocalGame() {
    _game.startNewGame();
  }

  Game get game => _game;

  GamePhase get phase {
    if (_game.isFinished) return GamePhase.gameOver;
    final round = _game.currentRound;
    if (round != null && round.isFinished) return GamePhase.roundFinished;
    return GamePhase.playing;
  }

  RoundResult? get lastResult => _game.currentRound?.result;

  List<Player> get players => _game.players;

  Player get localPlayer => _game.players[0];

  Player get currentPlayer => _game.currentRound!.currentPlayer;

  List<Move> get currentMoves => _game.currentRound?.movesHistory ?? const [];

  /// Jugadas válidas para el jugador local en el turno actual.
  List<Move> get validMovesForLocal {
    final round = _game.currentRound;
    if (round == null) return const [];
    if (currentPlayer.id != localPlayer.id) return const [];
    return round.validMovesFor(0);
  }

  bool get isLocalTurn => currentPlayer.id == localPlayer.id;

  /// Tiles de la mano del jugador local que tienen al menos una jugada
  /// válida en el turno actual.
  Set<DominoTile> get localValidTiles =>
      validMovesForLocal.map((m) => m.tile).toSet();

  /// Si el jugador local tiene jugadas válidas.
  bool get localCanPlay => validMovesForLocal.isNotEmpty;

  /// Aplica las bonificaciones pendientes y avanza a la siguiente ronda
  /// si la actual terminó.
  void continueAfterRound() {
    if (phase != GamePhase.roundFinished) return;
    _game.applyRoundResult();
    if (_game.isFinished) {
      notifyListeners();
      return;
    }
    _game.startNextRound();
    _scheduleBotIfNeeded();
    notifyListeners();
  }

  /// Intenta jugar [tile] por el lado local. Si el motor lo rechaza
  /// (ficha inválida, no es turno del local, etc.) retorna false.
  ///
  /// Si la jugada termina la ronda, aplica el resultado y programa el
  /// avance automático a la siguiente ronda.
  bool playTile(DominoTile tile) {
    if (!isLocalTurn) return false;
    final validMoves = validMovesForLocal.where((m) => m.tile == tile).toList();
    if (validMoves.isEmpty) return false;

    // Si la ficha encaja en ambos lados, usar el lado que dicta el Board
    // (válido el primero). Si encaja en uno solo, ése es el lado.
    final move = validMoves.first;
    _game.currentRound!.playTile(tile, chosenSide: move.side);
    _afterHumanAction();
    return true;
  }

  /// Pasa el turno del jugador local. Sólo válido si no tiene jugadas.
  bool pass() {
    if (!isLocalTurn) return false;
    if (localCanPlay) return false;
    _game.currentRound!.pass();
    _afterHumanAction();
    return true;
  }

  void _afterHumanAction() {
    // Aplicar bonificaciones inmediatas (pases de salida, pase redondo).
    _game.applyPendingBonuses();
    notifyListeners();
    _scheduleBotIfNeeded();
  }

  void _scheduleBotIfNeeded() {
    _botTimer?.cancel();
    if (!botsEnabled) return;
    final round = _game.currentRound;
    if (round == null || round.isFinished) return;
    if (isLocalTurn) return;
    if (phase == GamePhase.gameOver) return;
    _botTimer = Timer(botDelay, _playBotTurn);
  }

  void _playBotTurn() {
    if (_disposed) return;
    final round = _game.currentRound;
    if (round == null || round.isFinished) return;
    if (isLocalTurn) return;
    if (phase == GamePhase.gameOver) return;

    final playerIdx = round.currentPlayerIndex;
    final move = _bot.pickMove(round, playerIdx);
    if (move != null) {
      round.playTile(move.tile, chosenSide: move.side);
    } else {
      round.pass();
    }
    _game.applyPendingBonuses();
    notifyListeners();
    _scheduleBotIfNeeded();
  }

  @override
  void dispose() {
    _disposed = true;
    _botTimer?.cancel();
    super.dispose();
  }
}
