import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart' as engine;
import 'package:grand_chess/game/chess_clock.dart';

void main() {
  group('ChessClockController', () {
    test('counts down the active side and adds increment after a move', () {
      final clock = ChessClockController(
        timeControl: ChessTimeControl.blitz3,
      );
      addTearDown(clock.dispose);

      clock.start();
      clock.elapse(const Duration(seconds: 5));
      expect(clock.whiteRemaining, const Duration(minutes: 2, seconds: 55));
      expect(clock.blackRemaining, const Duration(minutes: 3));
      expect(clock.activeSide, engine.Color.white);

      clock.completeMove(
        newPly: 1,
        sideThatMoved: engine.Color.white,
        sideToMove: engine.Color.black,
      );
      expect(clock.whiteRemaining, const Duration(minutes: 2, seconds: 57));
      expect(clock.activeSide, engine.Color.black);
      expect(clock.currentPly, 1);

      clock.elapse(const Duration(seconds: 10));
      clock.completeMove(
        newPly: 2,
        sideThatMoved: engine.Color.black,
        sideToMove: engine.Color.white,
      );
      expect(clock.blackRemaining, const Duration(minutes: 2, seconds: 52));
      expect(clock.activeSide, engine.Color.white);
    });

    test('undo and redo restore the same saved times', () {
      final clock = ChessClockController(
        timeControl: ChessTimeControl.blitz5,
      );
      addTearDown(clock.dispose);
      clock.start();

      clock.elapse(const Duration(seconds: 8));
      clock.completeMove(
        newPly: 1,
        sideThatMoved: engine.Color.white,
        sideToMove: engine.Color.black,
      );
      final whiteAfterMove = clock.whiteRemaining;
      clock.elapse(const Duration(seconds: 12));
      clock.completeMove(
        newPly: 2,
        sideThatMoved: engine.Color.black,
        sideToMove: engine.Color.white,
      );
      final blackAfterMove = clock.blackRemaining;

      clock.restoreToPly(1, engine.Color.black);
      expect(clock.currentPly, 1);
      expect(clock.whiteRemaining, whiteAfterMove);
      expect(clock.blackRemaining, const Duration(minutes: 5));
      expect(clock.activeSide, engine.Color.black);

      clock.restoreToPly(2, engine.Color.white);
      expect(clock.currentPly, 2);
      expect(clock.blackRemaining, blackAfterMove);
      expect(clock.activeSide, engine.Color.white);
    });

    test('flags the active player at zero', () {
      final clock = ChessClockController(
        timeControl: ChessTimeControl.bullet1,
      );
      addTearDown(clock.dispose);
      clock.start();

      clock.elapse(const Duration(minutes: 1));

      expect(clock.whiteRemaining, Duration.zero);
      expect(clock.flaggedSide, engine.Color.white);
      expect(clock.isRunning, isFalse);
    });

    test('untimed mode does not start a running clock', () {
      final clock = ChessClockController(
        timeControl: ChessTimeControl.untimed,
      );
      addTearDown(clock.dispose);

      clock.start();
      clock.elapse(const Duration(minutes: 3));

      expect(clock.isEnabled, isFalse);
      expect(clock.isRunning, isFalse);
      expect(clock.whiteRemaining, Duration.zero);
      expect(clock.flaggedSide, isNull);
    });

    test('formats minutes and hours consistently', () {
      expect(
        ChessClockController.format(const Duration(minutes: 3)),
        '03:00',
      );
      expect(
        ChessClockController.format(const Duration(minutes: 9, seconds: 7)),
        '09:07',
      );
      expect(
        ChessClockController.format(const Duration(hours: 1, seconds: 2)),
        '01:00:02',
      );
    });
  });
}
