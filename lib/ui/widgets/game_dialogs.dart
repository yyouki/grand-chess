import 'package:flutter/material.dart';

import '../../chess_engine/chess_engine.dart' hide Color;
import '../../chess_engine/chess_engine.dart' as engine;
import '../../game/game_outcome.dart';
import 'piece_glyph.dart';

const List<PieceType> _promotionChoices = <PieceType>[
  PieceType.queen,
  PieceType.rook,
  PieceType.bishop,
  PieceType.knight,
];

Future<PieceType?> showPromotionDialog(
  BuildContext context,
  engine.Color side,
) {
  return showDialog<PieceType>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Promote pawn', key: ValueKey('promotion-title')),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final type in _promotionChoices)
            _PromotionChoice(side: side, type: type),
        ],
      ),
    ),
  );
}

class _PromotionChoice extends StatelessWidget {
  const _PromotionChoice({required this.side, required this.type});

  final engine.Color side;
  final PieceType type;

  static String _label(PieceType type) {
    switch (type) {
      case PieceType.queen:
        return 'Queen';
      case PieceType.rook:
        return 'Rook';
      case PieceType.bishop:
        return 'Bishop';
      case PieceType.knight:
        return 'Knight';
      case PieceType.king:
        return 'King';
      case PieceType.pawn:
        return 'Pawn';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      key: ValueKey('promotion-${type.name}'),
      onPressed: () => Navigator.of(context).pop(type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PieceGlyph(piece: Piece(side, type), size: 40),
          Text(_label(type)),
        ],
      ),
    );
  }
}

enum GameResultAction { viewBoard, newGame }

Future<GameResultAction?> showGameResultDialog(
  BuildContext context,
  GameOutcome outcome,
) {
  return showDialog<GameResultAction>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(outcome.headline, key: const ValueKey('result-title')),
      content: Text(outcome.subtitle, key: const ValueKey('result-subtitle')),
      actions: [
        TextButton(
          key: const ValueKey('result-view-board'),
          onPressed: () =>
              Navigator.of(context).pop(GameResultAction.viewBoard),
          child: const Text('View board'),
        ),
        FilledButton(
          key: const ValueKey('result-new-game'),
          onPressed: () => Navigator.of(context).pop(GameResultAction.newGame),
          child: const Text('New game'),
        ),
      ],
    ),
  );
}
