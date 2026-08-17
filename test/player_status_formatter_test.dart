import 'package:flutter_test/flutter_test.dart';
import 'package:kboom/utils/player_status_formatter.dart';

void main() {
  group('player status formatter', () {
    test('uses a neutral label for the active player', () {
      expect(
        formatPlayerStatusLabel(isCurrentTurnPlayer: true, isEliminated: false),
        'Tour en cours',
      );
    });

    test('shows eliminated players clearly', () {
      expect(
        formatPlayerStatusLabel(isCurrentTurnPlayer: false, isEliminated: true),
        'Éliminé',
      );
    });

    test('keeps other players in a non-score-based state', () {
      expect(
        formatPlayerStatusLabel(isCurrentTurnPlayer: false, isEliminated: false),
        'En jeu',
      );
    });
  });
}
