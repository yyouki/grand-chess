import 'package:flutter/material.dart';

import '../../chess_engine/chess_engine.dart' as engine;
import '../../game/game_controller.dart';
import '../theme/app_theme.dart';
import '../theme/board_colors.dart';

class GameStatusBar extends StatelessWidget {
  const GameStatusBar({
    super.key,
    required this.controller,
    required this.whiteName,
    required this.blackName,
  });

  final GameController controller;
  final String whiteName;
  final String blackName;

  String _turnLabel(engine.Color side) {
    final sideName = side == engine.Color.white ? 'White' : 'Black';
    final playerName = side == engine.Color.white ? whiteName : blackName;
    return playerName == sideName ? sideName : '$playerName ($sideName)';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final state = controller.gameState;
        final outcome = controller.outcome;
        final errorMessage = controller.errorMessage;
        final side = state.position.sideToMove;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (outcome != null) ...[
              Text(
                outcome.headline,
                key: const ValueKey('result-headline'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                outcome.subtitle,
                key: const ValueKey('result-detail'),
                style: const TextStyle(fontSize: 14, color: AppTheme.mutedInk),
              ),
            ] else ...[
              Row(
                children: [
                  _TurnDot(isWhite: side == engine.Color.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_turnLabel(side)} to move',
                      key: const ValueKey('turn-indicator'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
              if (state.isInCheck)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Check',
                    key: ValueKey('check-indicator'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB3261E),
                    ),
                  ),
                ),
            ],
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  errorMessage,
                  key: const ValueKey('error-message'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB3261E),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TurnDot extends StatelessWidget {
  const _TurnDot({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isWhite
              ? BoardColors.pieceWhiteFill
              : BoardColors.pieceBlackFill,
          shape: BoxShape.circle,
          border: Border.all(color: BoardColors.pieceWhiteOutline, width: 1.5),
        ),
      ),
    );
  }
}
