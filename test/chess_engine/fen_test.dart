import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

void main() {
  const codec = FenCodec();

  void expectRoundTrip(String fen) {
    final parsed = codec.parse(fen);
    expect(parsed.isOk, isTrue, reason: 'expected "$fen" to parse successfully');
    final regenerated = codec.toFen(parsed.valueOrNull!);
    expect(regenerated, fen, reason: 'round-trip mismatch for "$fen"');
  }

  group('FEN round-trip', () {
    test('starting position', () {
      expectRoundTrip(FenCodec.startingPositionFen);
    });

    test('position with only some castling rights remaining', () {
      expectRoundTrip('r3k2r/8/8/8/8/8/8/R3K2R w Kq - 4 12');
    });

    test('position with no castling rights at all', () {
      expectRoundTrip('4k3/8/8/8/8/8/8/4K3 w - - 0 1');
    });

    test('position with an en passant target square', () {
      expectRoundTrip('rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3');
    });

    test('halfmove clock and fullmove number are preserved', () {
      expectRoundTrip('4k3/8/8/8/8/8/8/4K3 w - - 37 91');
    });

    test('promoted pieces on the board round-trip correctly', () {
      expectRoundTrip('Q3k3/8/8/8/8/8/8/4K3 b - - 0 1');
      expectRoundTrip('4k3/8/8/8/8/8/8/n3K3 w - - 0 1');
    });

    test('a position with many empty squares round-trips (compact digits)', () {
      expectRoundTrip('8/8/4k3/8/8/3K4/8/8 w - - 0 1');
    });

    test('black to move round-trips correctly', () {
      expectRoundTrip('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1');
    });
  });

  group('Semantic validation — syntactically valid, invalid chess position', () {
    test('a position with no white king is rejected', () {
      final result = codec.parse('4k3/8/8/8/8/8/8/8 w - - 0 1');
      expect(result.isErr, isTrue);
      expect(result.errorOrNull, isA<InvalidChessPositionError>());
    });

    test('a position with no black king is rejected', () {
      final result = codec.parse('8/8/8/8/8/8/8/4K3 w - - 0 1');
      expect(result.isErr, isTrue);
      expect(result.errorOrNull, isA<InvalidChessPositionError>());
    });

    test('a position with two white kings is rejected', () {
      final result = codec.parse('4k3/8/8/8/8/8/8/3KK3 w - - 0 1');
      expect(result.isErr, isTrue);
      expect(result.errorOrNull, isA<InvalidChessPositionError>());
    });

    test('a pawn on rank 1 is rejected', () {
      final result = codec.parse('4k3/8/8/8/8/8/8/3PK3 w - - 0 1');
      expect(result.isErr, isTrue);
      expect(result.errorOrNull, isA<InvalidChessPositionError>());
    });

    test('a pawn on rank 8 is rejected', () {
      final result = codec.parse('3pk3/8/8/8/8/8/8/4K3 w - - 0 1');
      expect(result.isErr, isTrue);
      expect(result.errorOrNull, isA<InvalidChessPositionError>());
    });

    test('semantic errors are a distinct type from syntax errors', () {
      final syntaxError = codec.parse(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR x KQkq - 0 1',
      );
      final semanticError = codec.parse('8/8/8/8/8/8/8/4K3 w - - 0 1');
      expect(syntaxError.errorOrNull, isA<InvalidFenError>());
      expect(semanticError.errorOrNull, isA<InvalidChessPositionError>());
      expect(
        syntaxError.errorOrNull.runtimeType,
        isNot(semanticError.errorOrNull.runtimeType),
      );
    });

    test('unusual but syntactically valid castling rights are NOT rejected '
        '(semantic validation is deliberately narrow — see FenCodec docs)', () {
      // No rook actually on h1, yet "K" is claimed. Deliberately accepted:
      // rejecting this would make otherwise-valid puzzle/study FEN import
      // more fragile than useful.
      final result = codec.parse('4k3/8/8/8/8/8/8/4K3 w K - 0 1');
      expect(result.isOk, isTrue);
    });
  });

  group('Invalid FEN handling', () {
    test('wrong number of fields is rejected, not silently accepted', () {
      final result = codec.parse('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -');
      expect(result.isErr, isTrue);
    });

    test('a rank that does not sum to 8 squares is rejected', () {
      final result = codec.parse(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
      expect(result.isErr, isTrue);
    });

    test('an invalid piece letter is rejected', () {
      final result = codec.parse(
        'rnbqkbnx/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
      expect(result.isErr, isTrue);
    });

    test('an invalid active color is rejected', () {
      final result = codec.parse(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR x KQkq - 0 1',
      );
      expect(result.isErr, isTrue);
    });

    test('a malformed en passant square is rejected', () {
      final result = codec.parse(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq z9 0 1',
      );
      expect(result.isErr, isTrue);
    });

    test('a negative halfmove clock is rejected', () {
      final result = codec.parse(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - -1 1',
      );
      expect(result.isErr, isTrue);
    });

    test('invalid FEN never produces a usable position — no silent corruption', () {
      final result = codec.parse('not a fen at all');
      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });
}
