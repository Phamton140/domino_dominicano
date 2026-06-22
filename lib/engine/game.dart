import 'dart:math';

import 'models/player.dart';
import 'models/team.dart';
import 'round.dart';
import 'rules/scoring_rules.dart';

/// Estado general de la partida.
enum GameStatus { waiting, inProgress, finished }

/// Orquesta la partida completa de dominó.
///
/// Se encarga de crear jugadores y equipos, iniciar rondas,
/// aplicar puntuaciones y determinar el ganador de la partida.
class Game {
  final List<Player> players;
  final Map<String, Team> teams;
  final Random? random;

  int _roundNumber = 0;
  Round? _currentRound;
  GameStatus _status = GameStatus.waiting;
  String? _winnerTeamId;

  Game({
    required this.players,
    required this.teams,
    this.random,
  }) {
    if (players.length != 4) {
      throw ArgumentError('Se requieren exactamente 4 jugadores');
    }
    if (teams.length != 2) {
      throw ArgumentError('Se requieren exactamente 2 equipos');
    }
  }

  // --- Getters ---

  GameStatus get status => _status;

  Round? get currentRound => _currentRound;

  String? get winnerTeamId => _winnerTeamId;

  int get roundNumber => _roundNumber;

  bool get isFinished => _status == GameStatus.finished;

  // --- Factory ---

  /// Crea una partida estándar con 4 jugadores locales y 2 equipos.
  static Game createLocalGame({Random? random}) {
    final players = [
      Player(
        id: 'p0',
        name: 'Local',
        position: PlayerPosition.bottom,
        teamId: 'A',
      ),
      Player(
        id: 'p1',
        name: 'Derecho',
        position: PlayerPosition.right,
        teamId: 'B',
      ),
      Player(
        id: 'p2',
        name: 'Compañero',
        position: PlayerPosition.top,
        teamId: 'A',
      ),
      Player(
        id: 'p3',
        name: 'Izquierdo',
        position: PlayerPosition.left,
        teamId: 'B',
      ),
    ];

    final teams = {
      'A': Team(id: 'A', name: 'Equipo A', playerIds: ['p0', 'p2']),
      'B': Team(id: 'B', name: 'Equipo B', playerIds: ['p1', 'p3']),
    };

    return Game(players: players, teams: teams, random: random);
  }

  // --- Control de partida ---

  /// Inicia una partida nueva, repartiendo la primera ronda.
  void startNewGame() {
    _roundNumber = 1;
    _winnerTeamId = null;
    _status = GameStatus.inProgress;

    for (final team in teams.values) {
      team.score = 0;
    }

    _startRound(starterIndex: null);
  }

  /// Inicia la siguiente ronda usando el ganador de la anterior.
  void startNextRound() {
    if (_status != GameStatus.inProgress) {
      throw StateError('La partida no está en curso');
    }

    final previousResult = _currentRound?.result;
    if (previousResult == null) {
      throw StateError('La ronda actual no ha terminado');
    }

    _roundNumber++;

    final starterIndex = players
        .indexWhere((p) => p.id == previousResult.nextRoundStarterPlayerId);
    if (starterIndex == -1) {
      throw StateError('Jugador inicial no encontrado');
    }

    _startRound(starterIndex: starterIndex);
  }

  void _startRound({int? starterIndex}) {
    _currentRound = Round(players: players, random: random);
    _currentRound!.deal();
    _currentRound!.start(starterIndex: starterIndex);
  }

  /// Aplica las bonificaciones inmediatas pendientes de la ronda actual.
  ///
  /// Debe llamarse después de cada pase que pueda generar una bonificación.
  void applyPendingBonuses() {
    final round = _currentRound;
    if (round == null) return;

    final bonus = round.pendingImmediateBonus;
    if (bonus == null) return;

    final team = teams[bonus.teamId];
    if (team == null) return;

    // Regla de los 170: solo se aplican bonos de salida/pase redondo
    // si el equipo tiene menos de 170 puntos.
    final isPassBonus =
        bonus.reason.contains('Pase') || bonus.reason.contains('pase');
    if (isPassBonus && !ScoringRules.canReceivePassBonus(team.score)) {
      round.clearPendingImmediateBonus();
      return;
    }

    team.addPoints(bonus.points);
    round.clearPendingImmediateBonus();

    _checkGameEnd();
  }

  /// Aplica los puntos del resultado final de la ronda (dominación/tranque).
  void applyRoundResult() {
    final round = _currentRound;
    if (round == null) return;

    final result = round.result;
    if (result == null) return;

    final team = teams[result.winningTeamId];
    if (team == null) return;

    team.addPoints(result.pointsAwarded);
    _checkGameEnd();
  }

  void _checkGameEnd() {
    for (final team in teams.values) {
      if (team.reached200) {
        _status = GameStatus.finished;
        _winnerTeamId = team.id;
        return;
      }
    }
  }
}
