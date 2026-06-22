import 'package:flutter_test/flutter_test.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/engine/rules/scoring_rules.dart';

void main() {
  group('ScoringRules', () {
    test('handScore suma los puntos de una mano', () {
      final hand = [
        const DominoTile(6, 6),
        const DominoTile(5, 4),
        const DominoTile(0, 1),
      ];
      expect(ScoringRules.handScore(hand), 12 + 9 + 1);
    });

    test('canReceivePassBonus solo por debajo de 170', () {
      expect(ScoringRules.canReceivePassBonus(169), true);
      expect(ScoringRules.canReceivePassBonus(170), false);
      expect(ScoringRules.canReceivePassBonus(200), false);
    });

    group('determineStartBonus', () {
      test('salida con doble, siguiente pasa, compañero juega => 30', () {
        final type = ScoringRules.determineStartBonus(
          startTileIsDouble: true,
          nextPlayerCanPlay: false,
          partnerCanPlay: true,
          afterPartnerCanPlay: false,
        );
        expect(type, StartBonusType.double30);
        expect(ScoringRules.pointsForStartBonus(type), 30);
      });

      test('salida con doble, siguiente pasa, compañero pasa, cuarto juega => 0',
          () {
        final type = ScoringRules.determineStartBonus(
          startTileIsDouble: true,
          nextPlayerCanPlay: false,
          partnerCanPlay: false,
          afterPartnerCanPlay: true,
        );
        expect(type, StartBonusType.none);
      });

      test('salida con doble, todos pasan => 60', () {
        final type = ScoringRules.determineStartBonus(
          startTileIsDouble: true,
          nextPlayerCanPlay: false,
          partnerCanPlay: false,
          afterPartnerCanPlay: false,
        );
        expect(type, StartBonusType.double60);
        expect(ScoringRules.pointsForStartBonus(type), 60);
      });

      test('salida con ficha normal, siguiente pasa => 60', () {
        final type = ScoringRules.determineStartBonus(
          startTileIsDouble: false,
          nextPlayerCanPlay: false,
          partnerCanPlay: false,
          afterPartnerCanPlay: false,
        );
        expect(type, StartBonusType.normal60);
        expect(ScoringRules.pointsForStartBonus(type), 60);
      });

      test('salida con ficha normal, siguiente juega => 0', () {
        final type = ScoringRules.determineStartBonus(
          startTileIsDouble: false,
          nextPlayerCanPlay: true,
          partnerCanPlay: false,
          afterPartnerCanPlay: false,
        );
        expect(type, StartBonusType.none);
      });
    });

    group('isCapicua', () {
      test('detecta capicúa cuando extremos son diferentes y ficha encaja', () {
        expect(
          ScoringRules.isCapicua(
            leftEnd: 4,
            rightEnd: 2,
            playedTile: const DominoTile(4, 2),
          ),
          true,
        );
      });

      test('no es capicúa si extremos son iguales', () {
        expect(
          ScoringRules.isCapicua(
            leftEnd: 4,
            rightEnd: 4,
            playedTile: const DominoTile(4, 4),
          ),
          false,
        );
      });

      test('no es capicúa si la ficha no encaja en ambos extremos', () {
        expect(
          ScoringRules.isCapicua(
            leftEnd: 4,
            rightEnd: 2,
            playedTile: const DominoTile(4, 3),
          ),
          false,
        );
      });
    });

    test('dominationPoints suma puntos restantes y bonificación capicúa', () {
      final points = ScoringRules.dominationPoints(
        allHandScores: [10, 20, 15, 5],
        isCapicua: true,
      );
      expect(points, 50 + 30);
    });

    test('tranquePoints suma todos los puntos restantes', () {
      final points = ScoringRules.tranquePoints([10, 20, 15, 5]);
      expect(points, 50);
    });
  });
}
