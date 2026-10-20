import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

Set<String> destinationsFrom(GameState state, String fromAlgebraic) {
  final from = Square.fromAlgebraic(fromAlgebraic);
  return state.legalMoves
      .where((m) => m.from == from)
      .map((m) => m.to.algebraic)
      .toSet();
}

void main() {
  group('Basic check', () {
    test('king is reported in check when attacked by a rook on an open file/rank', () {
      final state = GameState.fromFen(
        'R3k3/8/8/8/8/8/8/4K3 b - - 0 1',
      ).valueOrNull!;
      expect(state.isInCheck, isTrue);
    });

    test('king can escape check by moving off the attacked line', () {
      final state = GameState.fromFen(
        'R3k3/8/8/8/8/8/8/4K3 b - - 0 1',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'e8'), {'d7', 'e7', 'f7'});
    });

    test('is not in check in a quiet position', () {
      expect(GameState.initial().isInCheck, isFalse);
    });
  });

  group('Pinned pieces', () {
    test('a pinned knight has zero legal moves (no move preserves the pin line)', () {
      final state = GameState.fromFen(
        '4r2k/8/8/8/4N3/8/8/4K3 w - - 0 1',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'e4'), isEmpty);
    });
  });

  group('Discovered check', () {
    test('moving a blocking piece away can reveal check from a piece behind it', () {
      final before = GameState.fromFen(
        'k7/8/8/8/N7/8/8/R3K3 w - - 0 1',
      ).valueOrNull!;
      expect(before.isInCheck, isFalse);

      final after = before
          .applyMove(
            Move(from: Square.fromAlgebraic('a4'), to: Square.fromAlgebraic('c5')),
          )
          .valueOrNull!;
      expect(after.isInCheck, isTrue);
    });
  });

  group('Double check', () {
    test('a move that both uncovers and delivers check restricts replies to king moves only', () {
      final before = GameState.fromFen(
        'k7/8/8/8/N7/8/8/R3K3 w - - 0 1',
      ).valueOrNull!;

      final after = before
          .applyMove(
            Move(from: Square.fromAlgebraic('a4'), to: Square.fromAlgebraic('b6')),
          )
          .valueOrNull!;

      expect(after.isInCheck, isTrue);
      expect(destinationsFrom(after, 'a8'), {'b7', 'b8'});
      expect(after.legalMoves.length, 2);
      expect(
        after.legalMoves.every((m) => m.from == Square.fromAlgebraic('a8')),
        isTrue,
        reason: 'in double check, only king moves can ever be legal',
      );
    });
  });

  group('Illegal king moves', () {
    test('king cannot move onto a square attacked by the opponent', () {
      final state = GameState.fromFen(
        '8/8/8/8/8/4k3/8/4K3 w - - 0 1',
      ).valueOrNull!;
      expect(destinationsFrom(state, 'e1'), isNot(contains('e2')));
    });

    test('king cannot capture a defended piece', () {
      final state = GameState.fromFen(
        '4k3/8/8/8/8/3r4/3p4/4K3 w - - 0 1',
      ).valueOrNull!;
      // d2 pawn is defended by the rook on d3; the king must not be
      // offered a "capture" that would walk into check.
      expect(destinationsFrom(state, 'e1'), isNot(contains('d2')));
    });
  });
}
