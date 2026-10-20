import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

void main() {
  const san = SanGenerator();

  group('Basic SAN', () {
    test('pawn moves show only the destination square', () {
      final position = Position.initial();
      final m = Move(from: Square.fromAlgebraic('e2'), to: Square.fromAlgebraic('e4'));
      expect(san.generate(position, m), 'e4');
    });

    test('piece moves are prefixed with the piece letter', () {
      final position = Position.initial();
      final m = Move(from: Square.fromAlgebraic('g1'), to: Square.fromAlgebraic('f3'));
      expect(san.generate(position, m), 'Nf3');
    });

    test('captures are marked with "x"', () {
      final position = const FenCodec()
          .parse('rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2')
          .valueOrNull!;
      final m = Move(from: Square.fromAlgebraic('e4'), to: Square.fromAlgebraic('d5'));
      expect(san.generate(position, m), 'exd5');
    });

    test('promotion is suffixed with "=" and the promoted piece letter', () {
      final position = const FenCodec()
          .parse('8/4P3/8/8/8/k7/8/4K3 w - - 0 1')
          .valueOrNull!;
      final m = Move(
        from: Square.fromAlgebraic('e7'),
        to: Square.fromAlgebraic('e8'),
        promotion: PieceType.queen,
      );
      expect(san.generate(position, m), 'e8=Q');
    });

    test('a promotion that gives check also carries the "+" suffix', () {
      final position = const FenCodec()
          .parse('8/4P3/8/8/4k3/8/8/4K3 w - - 0 1')
          .valueOrNull!;
      final m = Move(
        from: Square.fromAlgebraic('e7'),
        to: Square.fromAlgebraic('e8'),
        promotion: PieceType.queen,
      );
      expect(san.generate(position, m), 'e8=Q+');
    });

    test('kingside and queenside castling use O-O notation', () {
      final position = const FenCodec()
          .parse('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1')
          .valueOrNull!;
      final kingside = Move(from: Square.fromAlgebraic('e1'), to: Square.fromAlgebraic('g1'));
      final queenside = Move(from: Square.fromAlgebraic('e1'), to: Square.fromAlgebraic('c1'));
      expect(san.generate(position, kingside), 'O-O');
      expect(san.generate(position, queenside), 'O-O-O');
    });
  });

  group('Disambiguation', () {
    test('uses the origin file when two pieces on different files can reach the same square', () {
      final position = const FenCodec()
          .parse('4k3/8/8/8/8/8/8/1N1N2K1 w - - 0 1')
          .valueOrNull!;
      final fromB1 = Move(from: Square.fromAlgebraic('b1'), to: Square.fromAlgebraic('c3'));
      final fromD1 = Move(from: Square.fromAlgebraic('d1'), to: Square.fromAlgebraic('c3'));
      expect(san.generate(position, fromB1), 'Nbc3');
      expect(san.generate(position, fromD1), 'Ndc3');
    });

    test('falls back to the origin rank when the file alone does not disambiguate', () {
      final position = const FenCodec()
          .parse('R7/6k1/8/8/8/8/8/R3K3 w - - 0 1')
          .valueOrNull!;
      final fromRank1 = Move(from: Square.fromAlgebraic('a1'), to: Square.fromAlgebraic('a5'));
      final fromRank8 = Move(from: Square.fromAlgebraic('a8'), to: Square.fromAlgebraic('a5'));
      expect(san.generate(position, fromRank1), 'R1a5');
      expect(san.generate(position, fromRank8), 'R8a5');
    });
  });

  group('Move resolution', () {
    test('a minimal Move and the canonical Move give the same SAN', () {
      final position = const FenCodec()
          .parse('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1')
          .valueOrNull!;
      final minimal = Move(
        from: Square.fromAlgebraic('e1'),
        to: Square.fromAlgebraic('g1'),
      );
      final canonical = const MoveGenerator()
          .generateLegalMoves(position)
          .firstWhere((m) => m == minimal);
      expect(canonical.isCastleKingside, isTrue);
      expect(san.generate(position, canonical), 'O-O');
      expect(san.generate(position, minimal), 'O-O');
    });

    test('an illegal move is rejected instead of producing misleading SAN', () {
      final position = Position.initial();
      final illegal = Move(
        from: Square.fromAlgebraic('e2'),
        to: Square.fromAlgebraic('e5'),
      );
      expect(
        () => san.generate(position, illegal),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Check and checkmate suffixes', () {
    test('a move that gives check is suffixed with "+"', () {
      final position = const FenCodec()
          .parse('4k3/8/8/8/8/8/8/R3K3 w - - 0 1')
          .valueOrNull!;
      final m = Move(from: Square.fromAlgebraic('a1'), to: Square.fromAlgebraic('a8'));
      expect(san.generate(position, m), 'Ra8+');
    });

    test('a move that delivers checkmate is suffixed with "#"', () {
      final position = const FenCodec()
          .parse('6k1/5ppp/8/8/8/8/8/4R1K1 w - - 0 1')
          .valueOrNull!;
      final m = Move(from: Square.fromAlgebraic('e1'), to: Square.fromAlgebraic('e8'));
      expect(san.generate(position, m), 'Re8#');
    });

    test('a quiet move that neither checks nor mates has no suffix', () {
      final position = Position.initial();
      final m = Move(from: Square.fromAlgebraic('e2'), to: Square.fromAlgebraic('e4'));
      expect(san.generate(position, m), isNot(contains('+')));
      expect(san.generate(position, m), isNot(contains('#')));
    });
  });
}
