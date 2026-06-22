/// Representa un equipo de la partida.
class Team {
  final String id;
  final String name;
  final List<String> playerIds;
  int score;

  Team({
    required this.id,
    required this.name,
    required this.playerIds,
    this.score = 0,
  });

  bool get reached170 => score >= 170;

  bool get reached200 => score >= 200;

  void addPoints(int points) {
    if (points < 0) {
      throw ArgumentError('No se pueden sumar puntos negativos');
    }
    score += points;
  }

  Team copy() {
    return Team(
      id: id,
      name: name,
      playerIds: List.of(playerIds),
      score: score,
    );
  }
}
