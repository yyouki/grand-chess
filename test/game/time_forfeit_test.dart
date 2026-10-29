import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart' as engine;
import 'package:grand_chess/game/game_controller.dart';
import 'package:grand_chess/game/game_outcome.dart';

void main() {
  test('a time forfeit ends the session with the opponent winning', () {
    final controller = GameController();
    addTearDown(controller.dispose);

    controller.flagFell(engine.Color.white);

    expect(controller.isGameOver, isTrue);
    expect(controller.outcome?.reason, GameEndReason.timeForfeit);
    expect(controller.outcome?.result, engine.GameResult.blackWins);
    expect(controller.outcome?.subtitle, 'White ran out of time');
    expect(controller.canUndo, isTrue);

    controller.undoMove();

    expect(controller.isGameOver, isFalse);
  });
}
