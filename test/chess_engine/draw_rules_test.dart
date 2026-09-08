import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

GameState move(GameState state, String from, String to) {
  return state
      .applyMove(
        Move(from: Square.fromAlgebraic(from), to: Square.fromAlgebraic(to)),
      )
      .valueOrNull!;
}

void main() {
  group('Fifty-move rule', () {
    test('one quiet move that reaches a 100 halfmove clock triggers the draw', () {
      final state = GameState.fromFen(
        '4k3/8/8/8/8/8/8/4K3 w - - 99 50',
      ).valueOrNull!;
      final after = move(state, 'e1', 'd1');
      expect(after.position.halfmoveClock, 100);
      expect(after.status, GameStatus.drawByFiftyMoveRule);
      expect(after.result, GameResult.draw);
    });

    test('a pawn move or capture resets the clock instead of drawing', () {
      final state = GameState.fromFen(
        '4k3/8/8/8/8/8/4P3/4K3 w - - 99 50',
      ).valueOrNull!;
      final after = move(state, 'e2', 'e3');
      expect(after.position.halfmoveClock, 0);
      expect(after.status, isNot(GameStatus.drawByFiftyMoveRule));
    });
  });

  group('Threefold repetition', () {
    test('the same position occurring a third time is a draw', () {
      // Verified independently via the Python reference implementation:
      // this exact 8-ply king shuffle returns to the starting position
      // twice more (3 occurrences total).
      var state = GameState.fromFen(
        '4k3/8/8/8/8/8/8/4K3 w - - 0 1',
      ).valueOrNull!;

      const sequence = [
        ['e1', 'e2'], ['e8', 'e7'],
        ['e2', 'e1'], ['e7', 'e8'],
        ['e1', 'e2'], ['e8', 'e7'],
        ['e2', 'e1'], ['e7', 'e8'],
      ];
      for (final step in sequence) {
        state = move(state, step[0], step[1]);
      }

      expect(state.status, GameStatus.drawByThreefoldRepetition);
      expect(state.result, GameResult.draw);
    });

    test('two occurrences alone do not trigger the draw', () {
      var state = GameState.fromFen(
        '4k3/8/8/8/8/8/8/4K3 w - - 0 1',
      ).valueOrNull!;
      const sequence = [
        ['e1', 'e2'], ['e8', 'e7'],
        ['e2', 'e1'], ['e7', 'e8'],
      ];
      for (final step in sequence) {
        state = move(state, step[0], step[1]);
      }
      expect(state.status, isNot(GameStatus.drawByThreefoldRepetition));
    });
  });

  group('Insufficient material', () {
    test('king versus king is an immediate draw', () {
      final state = GameState.fromFen('4k3/8/8/8/8/8/8/4K3 w - - 0 1').valueOrNull!;
      expect(state.status, GameStatus.drawByInsufficientMaterial);
    });

    test('king and bishop versus king is a draw', () {
      final state = GameState.fromFen('4k3/8/8/8/8/8/8/3BK3 w - - 0 1').valueOrNull!;
      expect(state.status, GameStatus.drawByInsufficientMaterial);
    });

    test('king and knight versus king is a draw', () {
      final state = GameState.fromFen('4k3/8/8/8/8/8/8/3NK3 w - - 0 1').valueOrNull!;
      expect(state.status, GameStatus.drawByInsufficientMaterial);
    });

    test('same-colored bishops on each side is a draw', () {
      // c1 and f8 are the same square color.
      final state = GameState.fromFen('5b2/8/8/8/8/8/8/2B1K2k w - - 0 1').valueOrNull!;
      expect(state.status, GameStatus.drawByInsufficientMaterial);
    });

    test('opposite-colored bishops are NOT declared a forced draw', () {
      // c1 and g8 are opposite square colors — checkmate remains possible.
      final state = GameState.fromFen('6b1/8/8/8/8/8/8/2B1K2k w - - 0 1').valueOrNull!;
      expect(state.status, isNot(GameStatus.drawByInsufficientMaterial));
    });

    test('a lone extra pawn is sufficient material (not a draw)', () {
      final state = GameState.fromFen('4k3/8/8/8/8/8/4P3/4K3 w - - 0 1').valueOrNull!;
      expect(state.status, isNot(GameStatus.drawByInsufficientMaterial));
    });
  });
}
