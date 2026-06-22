import 'dart:math';

import 'board.dart';
import 'models/move.dart';
import 'models/player.dart';
import 'models/round_result.dart';
import 'models/tile.dart';
import 'rules/scoring_rules.dart';

/// Información de una bonificación inmediata detectada durante la ronda.
///
/// Los pases de salida y los pases redondos otorgan puntos en el momento
/// en que ocurren, no al finalizar la ronda.
class ImmediateBonus {
  final String teamId;
  final int points;
  final String reason;

  const ImmediateBonus({
    required this.teamId,
    required this.points,
    required this.reason,
  });
}

/// Representa una ronda individual de dominó.
///
/// Orden de jugadores: se asume que [players] está ordenado de forma
/// antihoraria comenzando por el jugador local.
/// Índices: 0 = local, 1 = derecho, 2 = compañero, 3 = izquierdo.
class Round {
  final List<Player> players;
  final Board board = Board();
  final Random? random;

  int _starterPlayerIndex = 0;
  int _currentPlayerIndex = 0;
  int _consecutivePasses = 0;
  int _movesCount = 0;
  bool _startBonusEvaluated = false;
  final List<Move> _movesHistory = [];
  RoundResult? _result;
  ImmediateBonus? _pendingImmediateBonus;

  Round({
    required this.players,
    this.random,
  }) {
    if (players.length != 4) {
      throw ArgumentError('Se requieren exactamente 4 jugadores');
    }
  }

  // --- Getters públicos ---

  int get currentPlayerIndex => _currentPlayerIndex;

  Player get currentPlayer => players[_currentPlayerIndex];

  int get starterPlayerIndex => _starterPlayerIndex;

  int get movesCount => _movesCount;

  bool get isFinished => _result != null;

  RoundResult? get result => _result;

  List<Move> get movesHistory => List.unmodifiable(_movesHistory);

  ImmediateBonus? get pendingImmediateBonus => _pendingImmediateBonus;

  void clearPendingImmediateBonus() {
    _pendingImmediateBonus = null;
  }

  // --- Inicialización ---

  /// Reparte 7 fichas a cada jugador.
  void deal() {
    final deck = _generateDeck();
    final rnd = random ?? Random();
    deck.shuffle(rnd);

    for (int i = 0; i < players.length; i++) {
      players[i].hand = deck.sublist(i * 7, (i + 1) * 7);
    }

    board.clear();
    _starterPlayerIndex = 0;
    _currentPlayerIndex = 0;
    _consecutivePasses = 0;
    _movesCount = 0;
    _startBonusEvaluated = false;
    _movesHistory.clear();
    _result = null;
    _pendingImmediateBonus = null;
  }

  /// Inicia la ronda determinando quién sale.
  ///
  /// Si [starterIndex] es null y es la primera ronda, sale quien tenga
  /// el doble seis. En rondas posteriores [starterIndex] debe indicar
  /// el ganador de la ronda anterior.
  void start({int? starterIndex}) {
    if (starterIndex != null) {
      _starterPlayerIndex = starterIndex;
    } else {
      _starterPlayerIndex = _findPlayerWithDoubleSix();
    }
    _currentPlayerIndex = _starterPlayerIndex;
  }

  int _findPlayerWithDoubleSix() {
    for (int i = 0; i < players.length; i++) {
      if (players[i].hasTile(DominoTile.doubleSix)) return i;
    }
    throw StateError('Ningún jugador tiene el doble seis');
  }

  // --- Jugadas válidas ---

  /// Devuelve las jugadas válidas para el jugador indicado.
  List<Move> validMovesFor(int playerIndex) {
    final player = players[playerIndex];
    final moves = <Move>[];

    if (board.isEmpty) {
      // Primera jugada: cualquier ficha del jugador inicial es válida.
      for (final tile in player.hand) {
        moves.add(Move(player: player, tile: tile, side: BoardSide.right));
      }
      return moves;
    }

    for (final tile in player.hand) {
      for (final side in board.validSidesFor(tile)) {
        moves.add(Move(player: player, tile: tile, side: side));
      }
    }
    return moves;
  }

  bool canPlay(int playerIndex) => validMovesFor(playerIndex).isNotEmpty;

  // --- Acciones de juego ---

  /// El jugador actual coloca una ficha.
  ///
  /// Si [chosenSide] es null, se elige el único lado válido. Si la ficha
  /// encaja en ambos extremos y no hay doble punta, se requiere elegir lado.
  void playTile(DominoTile tile, {BoardSide? chosenSide}) {
    _ensureNotFinished();
    _ensureCurrentPlayerCanUse(tile);

    final player = currentPlayer;
    final leftBefore = board.leftEnd;
    final rightBefore = board.rightEnd;

    final validMoves = validMovesFor(_currentPlayerIndex);
    final matchingMoves = validMoves.where((m) => m.tile == tile).toList();
    if (matchingMoves.isEmpty) {
      throw StateError('La ficha $tile no es una jugada válida en este turno');
    }

    final side = chosenSide ?? matchingMoves.first.side;
    if (!matchingMoves.any((m) => m.side == side)) {
      throw ArgumentError('Lado $side no válido para la ficha $tile');
    }

    final bool tileWasSwapped;
    if (board.isEmpty) {
      tileWasSwapped = false;
    } else if (side == BoardSide.left) {
      tileWasSwapped = tile.left == board.leftEnd;
    } else {
      tileWasSwapped = tile.left != board.rightEnd;
    }

    if (board.isEmpty) {
      board.placeFirst(tile);
    } else if (side == BoardSide.left) {
      board.placeOnLeft(tile);
    } else {
      board.placeOnRight(tile);
    }

    _movesHistory.add(Move(
      player: player,
      tile: tile,
      side: side,
      tileWasSwapped: tileWasSwapped,
    ));

    player.removeTile(tile);
    _movesCount++;
    _consecutivePasses = 0;

    // Dominación: el jugador se quedó sin fichas.
    if (player.hasEmptyHand) {
      _finishDomination(
        player,
        tile,
        leftEndBefore: leftBefore,
        rightEndBefore: rightBefore,
      );
      return;
    }

    _advanceTurn();
  }

  /// El jugador actual pasa porque no tiene jugada válida.
  void pass() {
    _ensureNotFinished();

    if (canPlay(_currentPlayerIndex)) {
      throw StateError(
        'El jugador ${currentPlayer.name} tiene jugadas válidas y no puede pasar',
      );
    }

    _consecutivePasses++;

    // Pase inmediatamente después de la salida.
    if (_movesCount == 1 && !_startBonusEvaluated) {
      _evaluateStartPassBonus();
      _startBonusEvaluated = true;
    }

    // Tres pases consecutivos: se evalúa pase redondo o tranque.
    if (_consecutivePasses == 3) {
      _advanceTurn();
      _evaluatePaseRedondoOrTranque();
      return;
    }

    _advanceTurn();
  }

  // --- Finalización de la ronda ---

  void _finishDomination(
    Player winner,
    DominoTile lastTile, {
    required int leftEndBefore,
    required int rightEndBefore,
  }) {
    final isCapicua = ScoringRules.isCapicua(
      leftEnd: leftEndBefore,
      rightEnd: rightEndBefore,
      playedTile: lastTile,
    );

    final allHandScores = players.map((p) => p.handScore).toList();
    final points = ScoringRules.dominationPoints(
      allHandScores: allHandScores,
      isCapicua: isCapicua,
    );

    final type = isCapicua ? RoundEndType.capicua : RoundEndType.domination;
    final description = isCapicua
        ? 'Capicúa de ${winner.name}'
        : 'Dominación de ${winner.name}';

    _result = RoundResult(
      type: type,
      winningTeamId: winner.teamId,
      pointsAwarded: points,
      nextRoundStarterPlayerId: winner.id,
      description: description,
    );
  }

  void _finishTranque(Player winner) {
    final allHandScores = players.map((p) => p.handScore).toList();
    final points = ScoringRules.tranquePoints(allHandScores);

    _result = RoundResult(
      type: RoundEndType.tranque,
      winningTeamId: winner.teamId,
      pointsAwarded: points,
      nextRoundStarterPlayerId: winner.id,
      description: 'Tranque ganado por ${winner.name}',
    );
  }

  // --- Helpers de validación ---

  void _ensureNotFinished() {
    if (isFinished) {
      throw StateError('La ronda ya ha terminado');
    }
  }

  void _ensureCurrentPlayerCanUse(DominoTile tile) {
    if (!currentPlayer.hasTile(tile)) {
      throw StateError(
        'El jugador ${currentPlayer.name} no tiene la ficha $tile',
      );
    }

    final validMoves = validMovesFor(_currentPlayerIndex);
    final moveExists = validMoves.any((m) => m.tile == tile);
    if (!moveExists) {
      throw StateError('La ficha $tile no es una jugada válida en este turno');
    }
  }

  // --- Avance de turnos ---

  void _advanceTurn() {
    _currentPlayerIndex = (_currentPlayerIndex + 1) % players.length;
  }

  int _nextPlayerIndex(int fromIndex) {
    return (fromIndex + 1) % players.length;
  }

  // --- Bonificaciones especiales ---

  void _evaluateStartPassBonus() {
    // Se llama cuando el jugador siguiente a la salida pasa.
    final starter = players[_starterPlayerIndex];
    final startTile = board.playedTiles.first.tile;
    final nextIndex = _nextPlayerIndex(_starterPlayerIndex);
    final partnerIndex = _nextPlayerIndex(nextIndex);
    final afterPartnerIndex = _nextPlayerIndex(partnerIndex);

    final nextCanPlay = canPlay(nextIndex);
    if (nextCanPlay) return; // No hay pase de salida.

    final partnerCanPlay = canPlay(partnerIndex);
    final afterPartnerCanPlay = canPlay(afterPartnerIndex);

    final bonusType = ScoringRules.determineStartBonus(
      startTileIsDouble: startTile.isDouble,
      nextPlayerCanPlay: nextCanPlay,
      partnerCanPlay: partnerCanPlay,
      afterPartnerCanPlay: afterPartnerCanPlay,
    );

    final points = ScoringRules.pointsForStartBonus(bonusType);
    if (points > 0) {
      _pendingImmediateBonus = ImmediateBonus(
        teamId: starter.teamId,
        points: points,
        reason: startTile.isDouble
            ? 'Pase de salida con doble'
            : 'Pase de salida con ficha normal',
      );
    }
  }

  void _evaluatePaseRedondoOrTranque() {
    // Se llama después de 3 pases consecutivos, con el turno en el jugador
    // que inició la secuencia (quien hizo la última jugada).
    final lastPlayerIndex = _currentPlayerIndex;

    if (canPlay(lastPlayerIndex)) {
      // Pase redondo: el mismo jugador puede jugar de nuevo.
      final player = players[lastPlayerIndex];
      _pendingImmediateBonus = ImmediateBonus(
        teamId: player.teamId,
        points: ScoringConstants.bonusPaseRedondo,
        reason: 'Pase redondo',
      );
      // El turno ya está en el jugador correcto, no se avanza.
      _consecutivePasses = 0;
      return;
    }

    // Tranque: nadie puede jugar.
    _resolveTranque(lastPlayerIndex);
  }

  void _resolveTranque(int lastPlayerIndex) {
    // El jugador que provocó el tranque es quien hizo la última jugada.
    // El jugador involucrado en la comparación es el siguiente en el turno.
    final trancador = players[lastPlayerIndex];
    final opponentIndex = _nextPlayerIndex(lastPlayerIndex);
    final opponent = players[opponentIndex];

    final trancadorScore = trancador.handScore;
    final opponentScore = opponent.handScore;

    final Player winner;
    if (trancadorScore < opponentScore) {
      winner = trancador;
    } else if (opponentScore < trancadorScore) {
      winner = opponent;
    } else {
      // Empate: gana quien provocó el tranque.
      winner = trancador;
    }

    _finishTranque(winner);
  }

  // --- Generación del mazo ---

  List<DominoTile> _generateDeck() {
    final deck = <DominoTile>[];
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        deck.add(DominoTile(i, j));
      }
    }
    return deck;
  }
}
