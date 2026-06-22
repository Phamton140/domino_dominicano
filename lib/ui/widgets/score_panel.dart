import 'package:flutter/material.dart';

import '../../engine/models/team.dart';
import '../theme.dart';

/// Marcador de los dos equipos de la partida.
class ScorePanel extends StatelessWidget {
  final Team teamA;
  final Team teamB;
  final int roundNumber;

  const ScorePanel({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.roundNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: DominoTheme.tableBorder,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TeamScore(team: teamA, color: Colors.lightBlueAccent),
          Text(
            'Ronda $roundNumber',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          _TeamScore(team: teamB, color: Colors.redAccent),
        ],
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  final Team team;
  final Color color;

  const _TeamScore({required this.team, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '${team.name}: ${team.score}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
