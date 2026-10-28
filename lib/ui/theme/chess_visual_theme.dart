import 'package:flutter/material.dart';

/// Finishes that change the board's wood and square colors without changing
/// chess rules or move validation.
enum BoardFinish { walnut, tournament, midnight }

extension BoardFinishStyle on BoardFinish {
  String get label => switch (this) {
    BoardFinish.walnut => 'Walnut wood',
    BoardFinish.tournament => 'Tournament green',
    BoardFinish.midnight => 'Midnight blue',
  };

  Color get lightSquare => switch (this) {
    BoardFinish.walnut => const Color(0xFFF0DFBE),
    BoardFinish.tournament => const Color(0xFFE7E4D8),
    BoardFinish.midnight => const Color(0xFFD9E1EF),
  };

  Color get darkSquare => switch (this) {
    BoardFinish.walnut => const Color(0xFF87512F),
    BoardFinish.tournament => const Color(0xFF4E755B),
    BoardFinish.midnight => const Color(0xFF334C70),
  };

  Color get frameTop => switch (this) {
    BoardFinish.walnut => const Color(0xFF98603B),
    BoardFinish.tournament => const Color(0xFF604833),
    BoardFinish.midnight => const Color(0xFF26354A),
  };

  Color get frameNear => switch (this) {
    BoardFinish.walnut => const Color(0xFF4D2A1C),
    BoardFinish.tournament => const Color(0xFF3B2A22),
    BoardFinish.midnight => const Color(0xFF172437),
  };

  Color get frameSide => switch (this) {
    BoardFinish.walnut => const Color(0xFF633923),
    BoardFinish.tournament => const Color(0xFF493327),
    BoardFinish.midnight => const Color(0xFF1C2A3D),
  };

  Color get frameFar => switch (this) {
    BoardFinish.walnut => const Color(0xFF5A321F),
    BoardFinish.tournament => const Color(0xFF533C2B),
    BoardFinish.midnight => const Color(0xFF202F45),
  };
}

/// Material presets for the sculpted pieces. These palettes retain a clear
/// white/black distinction while giving players a choice of finish.
enum PieceFinish { classic, marble, gold }

extension PieceFinishStyle on PieceFinish {
  String get label => switch (this) {
    PieceFinish.classic => 'Classic ivory',
    PieceFinish.marble => 'White marble',
    PieceFinish.gold => 'Ivory and gold',
  };

  Color highlight(bool isWhite) => switch ((this, isWhite)) {
    (PieceFinish.classic, true) => const Color(0xFFFFFFFF),
    (PieceFinish.classic, false) => const Color(0xFF343943),
    (PieceFinish.marble, true) => const Color(0xFFFFFDF7),
    (PieceFinish.marble, false) => const Color(0xFF1C252F),
    (PieceFinish.gold, true) => const Color(0xFFFFF3D2),
    (PieceFinish.gold, false) => const Color(0xFF29231D),
  };

  Color shadow(bool isWhite) => switch ((this, isWhite)) {
    (PieceFinish.classic, true) => const Color(0xFFE5E7EB),
    (PieceFinish.classic, false) => const Color(0xFF080A0E),
    (PieceFinish.marble, true) => const Color(0xFFD5D9E1),
    (PieceFinish.marble, false) => const Color(0xFF090E14),
    (PieceFinish.gold, true) => const Color(0xFFC99B42),
    (PieceFinish.gold, false) => const Color(0xFF090909),
  };
}
