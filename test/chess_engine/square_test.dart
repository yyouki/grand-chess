import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

void main() {
  group('Square.fromAlgebraic — valid input', () {
    test('accepts every corner and a middle square', () {
      expect(Square.fromAlgebraic('a1'), const Square(0, 0));
      expect(Square.fromAlgebraic('h8'), const Square(7, 7));
      expect(Square.fromAlgebraic('a8'), const Square(0, 7));
      expect(Square.fromAlgebraic('h1'), const Square(7, 0));
      expect(Square.fromAlgebraic('e4'), const Square(4, 3));
    });

    test('round-trips through .algebraic for every square on the board', () {
      for (var file = 0; file < 8; file++) {
        for (var rank = 0; rank < 8; rank++) {
          final square = Square(file, rank);
          expect(Square.fromAlgebraic(square.algebraic), square);
        }
      }
    });
  });

  group('Square.fromAlgebraic — invalid input is rejected deterministically', () {
    test('rejects an out-of-range file letter', () {
      expect(() => Square.fromAlgebraic('i1'), throwsArgumentError);
      expect(() => Square.fromAlgebraic('z1'), throwsArgumentError);
    });

    test('rejects an out-of-range rank digit', () {
      expect(() => Square.fromAlgebraic('a0'), throwsArgumentError);
      expect(() => Square.fromAlgebraic('a9'), throwsArgumentError);
    });

    test('rejects the wrong length', () {
      expect(() => Square.fromAlgebraic('a'), throwsArgumentError);
      expect(() => Square.fromAlgebraic('a12'), throwsArgumentError);
      expect(() => Square.fromAlgebraic(''), throwsArgumentError);
    });

    test('rejects malformed input that is not a letter+digit pair', () {
      expect(() => Square.fromAlgebraic('11'), throwsArgumentError);
      expect(() => Square.fromAlgebraic('ab'), throwsArgumentError);
      expect(() => Square.fromAlgebraic('A1'), throwsArgumentError);
    });
  });

  group('Square.tryFromAlgebraic — non-throwing equivalent', () {
    test('returns Ok for valid input', () {
      final result = Square.tryFromAlgebraic('e4');
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, const Square(4, 3));
    });

    test('returns Err for invalid input instead of throwing', () {
      final result = Square.tryFromAlgebraic('z9');
      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });
}
