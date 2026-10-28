import 'package:flutter/material.dart';

import '../../chess_engine/chess_engine.dart' hide Color;
import '../../chess_engine/chess_engine.dart' as engine;
import '../theme/board_colors.dart';

class PieceGlyph extends StatelessWidget {
  const PieceGlyph({super.key, required this.piece, required this.size});

  final Piece piece;
  final double size;

  static const Map<PieceType, String> _symbols = <PieceType, String>{
    PieceType.king: '\u265A\uFE0E',
    PieceType.queen: '\u265B\uFE0E',
    PieceType.rook: '\u265C\uFE0E',
    PieceType.bishop: '\u265D\uFE0E',
    PieceType.knight: '\u265E\uFE0E',
    PieceType.pawn: '\u265F\uFE0E',
  };

  static String symbolFor(PieceType type) => _symbols[type]!;

  static String describe(Piece piece) {
    return '${piece.color.name} ${piece.type.name}';
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.color == engine.Color.white;
    final symbol = symbolFor(piece.type);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.05
      ..strokeJoin = StrokeJoin.round
      ..color = isWhite
          ? BoardColors.pieceWhiteOutline
          : BoardColors.pieceBlackOutline;
    final base = TextStyle(
      fontSize: size,
      height: 1.0,
      decoration: TextDecoration.none,
    );
    return Semantics(
      label: describe(piece),
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(symbol, style: base.copyWith(foreground: outline)),
            Text(
              symbol,
              style: base.copyWith(
                color: isWhite
                    ? BoardColors.pieceWhiteFill
                    : BoardColors.pieceBlackFill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
