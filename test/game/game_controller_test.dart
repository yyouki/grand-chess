import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart';
import 'package:grand_chess/game/game_controller.dart';
import 'package:grand_chess/game/game_outcome.dart';

void main() {
  const codec = FenCodec();
  const blackToMoveFen =
      'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';
  const foolsMateFen =
      'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';
  const malformedFen = 'not a fen at all';
  const noWhiteKingFen = '4k3/8/8/8/8/8/8/8 w - - 0 1';

  GameController acceptedController(String fen) {
    final result = GameController.fromFen(fen);
    expect(result.isOk, isTrue, reason: 'expected "$fen" to be accepted');
    final controller = result.valueOrNull!;
    addTearDown(controller.dispose);
    return controller;
  }

  group('GameController.fromFen with a valid FEN', () {
    test('starts on exactly the position that was given', () {
      final controller = acceptedController(blackToMoveFen);

      final fen = codec.toFen(controller.gameState.position);
      expect(fen, blackToMoveFen);
      expect(controller.gameState.moveHistory, isEmpty);
    });

    test('still accepts the standard starting position', () {
      final controller = acceptedController(FenCodec.startingPositionFen);

      final fen = codec.toFen(controller.gameState.position);
      expect(fen, FenCodec.startingPositionFen);
      expect(controller.isGameOver, isFalse);
      expect(controller.selectedSquare, isNull);
    });

    test('reports the outcome when the position is already finished', () {
      final controller = acceptedController(foolsMateFen);

      expect(controller.isGameOver, isTrue);
      expect(controller.outcome?.reason, GameEndReason.checkmate);
      expect(controller.outcome?.result, GameResult.blackWins);
    });
  });

  group('GameController.fromFen with an invalid FEN', () {
    test('returns InvalidFenError for malformed text', () {
      final result = GameController.fromFen(malformedFen);

      expect(result.isErr, isTrue);
      expect(result.errorOrNull, isA<InvalidFenError>());
      expect(result.valueOrNull, isNull);
    });

    test('returns InvalidChessPositionError for an impossible board', () {
      final result = GameController.fromFen(noWhiteKingFen);

      expect(result.isErr, isTrue);
      expect(result.errorOrNull, isA<InvalidChessPositionError>());
      expect(result.valueOrNull, isNull);
    });

    test('reports the same error the engine reports', () {
      for (final fen in [malformedFen, noWhiteKingFen]) {
        final fromController = GameController.fromFen(fen).errorOrNull;
        final fromEngine = GameState.fromFen(fen).errorOrNull;

        expect(fromController, isNotNull);
        expect(fromEngine, isNotNull);
        expect(fromController!.runtimeType, fromEngine!.runtimeType);
        expect(fromController.message, fromEngine.message);
      }
    });
  });
}
