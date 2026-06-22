/// Tipos de finalización de una ronda.
enum RoundEndType {
  domination,
  capicua,
  tranque,
  startPassBonus,
  startPassCompleteBonus,
}

/// Resultado de una ronda finalizada.
class RoundResult {
  final RoundEndType type;
  final String winningTeamId;
  final int pointsAwarded;

  /// Jugador que iniciará la siguiente ronda.
  final String nextRoundStarterPlayerId;

  /// Descripción legible del resultado.
  final String description;

  const RoundResult({
    required this.type,
    required this.winningTeamId,
    required this.pointsAwarded,
    required this.nextRoundStarterPlayerId,
    required this.description,
  });

  @override
  String toString() =>
      '$description | +$pointsAwarded pts para equipo $winningTeamId';
}
