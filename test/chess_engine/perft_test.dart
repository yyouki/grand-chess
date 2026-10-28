import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';

/// Counts the number of leaf nodes (legal move sequences) reachable from
/// [position] at exactly [depth] plies. This is the standard chess
/// programming technique for validating a move generator: a single
/// move-generation bug (a missing legal move, or an illegal move wrongly
/// allowed) will almost always make the count diverge from the known
/// correct reference value at some depth.
int perft(Position position, int depth) {
  if (depth == 0) return 1;
  const generator = MoveGenerator();
  var nodes = 0;
  for (final move in generator.generateLegalMoves(position)) {
    nodes += perft(position.applyMove(move), depth - 1);
  }
  return nodes;
}

void main() {
  const codec = FenCodec();

  Position positionFor(String fen) => codec.parse(fen).valueOrNull!;

  group('Perft — starting position', () {
    final position = positionFor(FenCodec.startingPositionFen);

    test('depth 1', () => expect(perft(position, 1), 20));
    test('depth 2', () => expect(perft(position, 2), 400));
    test('depth 3', () => expect(perft(position, 3), 8902));
    test('depth 4', () => expect(perft(position, 4), 197281));
  });

  group('Perft — Kiwipete (castling, en passant, promotion stress test)', () {
    final position = positionFor(
      'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
    );

    test('depth 1', () => expect(perft(position, 1), 48));
    test('depth 2', () => expect(perft(position, 2), 2039));
    test('depth 3', () => expect(perft(position, 3), 97862));
  });

  group('Perft — position 3 (endgame, en passant heavy)', () {
    final position = positionFor('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1');

    test('depth 1', () => expect(perft(position, 1), 14));
    test('depth 2', () => expect(perft(position, 2), 191));
    test('depth 3', () => expect(perft(position, 3), 2812));
    test('depth 4', () => expect(perft(position, 4), 43238));
  });

  group('Perft — position 4 (promotion + castling combined)', () {
    final position = positionFor(
      'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
    );

    test('depth 1', () => expect(perft(position, 1), 6));
    test('depth 2', () => expect(perft(position, 2), 264));
    test('depth 3', () => expect(perft(position, 3), 9467));
  });

  group('Perft — position 5 (tactical middlegame)', () {
    final position = positionFor(
      'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
    );

    test('depth 1', () => expect(perft(position, 1), 44));
    test('depth 2', () => expect(perft(position, 2), 1486));
    test('depth 3', () => expect(perft(position, 3), 62379));
  });
}
