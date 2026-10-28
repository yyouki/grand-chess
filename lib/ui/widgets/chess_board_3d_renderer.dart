import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../chess_engine/chess_engine.dart' hide Color;
import '../../chess_engine/chess_engine.dart' as engine;
import '../theme/board_colors.dart';

class Chess3DScenePainter extends CustomPainter {
  const Chess3DScenePainter({
    required this.position,
    required this.selected,
    required this.targets,
    required this.lastMove,
    required this.checkedKing,
    required this.cursor,
    required this.cursorVisible,
    required this.projection,
  });

  final Position position;
  final Square? selected;
  final List<Move> targets;
  final Move? lastMove;
  final Square? checkedKing;
  final Square cursor;
  final bool cursorVisible;
  final ChessBoardProjection projection;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 0.9,
        colors: [Color(0xFF3A414D), Color(0xFF171B22)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final baseFaces = <_Face>[];
    _addBoardFrame(baseFaces);
    _addBoardTiles(baseFaces);
    _drawFaces(canvas, baseFaces);

    _drawPieceShadows(canvas, size);
    final pieceFaces = <_Face>[];
    _addPieces(pieceFaces);
    _drawFaces(canvas, pieceFaces);

    _drawMarkers(canvas, size);
    _drawCoordinates(canvas, size);
    _drawCursor(canvas);
    _drawOuterRim(canvas);
  }

  void _addBoardFrame(List<_Face> faces) {
    const left = -4.28;
    const right = 4.28;
    const near = 4.28;
    const far = -4.28;
    const top = -0.035;
    const bottom = -0.34;

    _addFace(faces, [
      const Chess3DVector(left, top, far),
      const Chess3DVector(right, top, far),
      const Chess3DVector(right, top, near),
      const Chess3DVector(left, top, near),
    ], const Color(0xFF85502F));
    _addFace(faces, [
      const Chess3DVector(left, bottom, near),
      const Chess3DVector(right, bottom, near),
      const Chess3DVector(right, top, near),
      const Chess3DVector(left, top, near),
    ], const Color(0xFF4D2A1C));
    _addFace(faces, [
      const Chess3DVector(left, bottom, far),
      const Chess3DVector(left, bottom, near),
      const Chess3DVector(left, top, near),
      const Chess3DVector(left, top, far),
    ], const Color(0xFF633923));
    _addFace(faces, [
      const Chess3DVector(right, bottom, far),
      const Chess3DVector(right, top, far),
      const Chess3DVector(right, top, near),
      const Chess3DVector(right, bottom, near),
    ], const Color(0xFF704128));
    _addFace(faces, [
      const Chess3DVector(left, bottom, far),
      const Chess3DVector(right, bottom, far),
      const Chess3DVector(right, top, far),
      const Chess3DVector(left, top, far),
    ], const Color(0xFF5A321F));

    // A thin, brighter wooden lip gives the board a finished furniture-like edge.
    const lip = 4.38;
    _addFace(faces, [
      const Chess3DVector(-lip, -0.02, -lip),
      const Chess3DVector(lip, -0.02, -lip),
      const Chess3DVector(lip, -0.02, lip),
      const Chess3DVector(-lip, -0.02, lip),
    ], const Color(0xFFAA7548));
  }

  void _addBoardTiles(List<_Face> faces) {
    for (var row = 0; row < 8; row++) {
      for (var column = 0; column < 8; column++) {
        final square = projection.squareAtVisualPosition(column, row);
        final isLight = (square.file + square.rank).isOdd;
        var color = isLight ? const Color(0xFFEEDFC8) : const Color(0xFF895431);

        if (lastMove != null &&
            (lastMove!.from == square || lastMove!.to == square)) {
          color = Color.alphaBlend(const Color(0x889CCB4A), color);
        }
        if (selected == square) {
          color = Color.alphaBlend(const Color(0xCCF2D34C), color);
        }
        if (checkedKing == square) {
          color = Color.alphaBlend(const Color(0xCCDF3F4D), color);
        }

        final x = column.toDouble() - 3.5;
        final z = row.toDouble() - 3.5;
        _addFace(faces, [
          Chess3DVector(x - 0.5, 0.0, z - 0.5),
          Chess3DVector(x + 0.5, 0.0, z - 0.5),
          Chess3DVector(x + 0.5, 0.0, z + 0.5),
          Chess3DVector(x - 0.5, 0.0, z + 0.5),
        ], color);

        // Small, quiet bevels between individual squares make the surface read
        // as separate finished wooden tiles rather than a flat printed image.
        _addFace(faces, [
          Chess3DVector(x - 0.5, 0.002, z - 0.5),
          Chess3DVector(x + 0.5, 0.002, z - 0.5),
          Chess3DVector(x + 0.5, 0.002, z - 0.46),
          Chess3DVector(x - 0.5, 0.002, z - 0.46),
        ], isLight ? const Color(0xFFE7D4B7) : const Color(0xFF744426));
      }
    }
  }

  void _addPieces(List<_Face> faces) {
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final square = Square(file, rank);
        final piece = position.pieceAt(square);
        if (piece == null) {
          continue;
        }
        final center = projection.worldCenterOf(square);
        final isWhite = piece.color == engine.Color.white;
        final highlight = isWhite
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF555B64);
        final shadow = isWhite
            ? const Color(0xFFC7C1B6)
            : const Color(0xFF080A0E);
        final material = _PieceMaterial(highlight: highlight, shadow: shadow);
        final profile = _profileFor(piece.type);
        _addLathe(faces, center.x, center.z, profile, material);

        switch (piece.type) {
          case PieceType.king:
            _addBox(
              faces,
              center.x,
              0.98,
              center.z,
              0.075,
              0.25,
              0.075,
              material,
            );
            _addBox(
              faces,
              center.x,
              1.015,
              center.z,
              0.23,
              0.065,
              0.075,
              material,
            );
            break;
          case PieceType.queen:
            for (var index = 0; index < 5; index++) {
              final angle = math.pi * 2 * index / 5;
              _addLathe(
                faces,
                center.x + math.cos(angle) * 0.15,
                center.z + math.sin(angle) * 0.15,
                const <(double, double)>[
                  (0.0, 0.0),
                  (0.035, 0.015),
                  (0.032, 0.045),
                  (0.018, 0.065),
                  (0.0, 0.08),
                ],
                material,
              );
            }
            break;
          case PieceType.rook:
            for (var index = 0; index < 8; index++) {
              final angle = math.pi * 2 * index / 8;
              _addBox(
                faces,
                center.x + math.cos(angle) * 0.20,
                0.785,
                center.z + math.sin(angle) * 0.20,
                0.085,
                0.13,
                0.085,
                material,
              );
            }
            break;
          case PieceType.bishop:
            _addBox(
              faces,
              center.x,
              0.82,
              center.z,
              0.055,
              0.14,
              0.055,
              material,
            );
            _addBox(
              faces,
              center.x,
              0.83,
              center.z,
              0.16,
              0.045,
              0.055,
              material,
            );
            break;
          case PieceType.knight:
            _addKnightHead(faces, center.x, center.z, material);
            break;
          case PieceType.pawn:
            break;
        }
      }
    }
  }

  List<(double, double)> _profileFor(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return const [
          (0.24, 0.015),
          (0.30, 0.05),
          (0.30, 0.11),
          (0.23, 0.15),
          (0.16, 0.21),
          (0.13, 0.33),
          (0.17, 0.38),
          (0.22, 0.41),
          (0.23, 0.47),
          (0.20, 0.52),
          (0.15, 0.58),
          (0.08, 0.64),
          (0.0, 0.67),
        ];
      case PieceType.knight:
        return const [
          (0.24, 0.015),
          (0.30, 0.05),
          (0.30, 0.11),
          (0.23, 0.15),
          (0.16, 0.21),
          (0.13, 0.33),
          (0.19, 0.39),
          (0.18, 0.44),
          (0.0, 0.47),
        ];
      case PieceType.bishop:
        return const [
          (0.25, 0.015),
          (0.31, 0.05),
          (0.31, 0.12),
          (0.23, 0.16),
          (0.16, 0.22),
          (0.14, 0.37),
          (0.20, 0.44),
          (0.15, 0.50),
          (0.10, 0.61),
          (0.07, 0.73),
          (0.035, 0.82),
          (0.0, 0.85),
        ];
      case PieceType.rook:
        return const [
          (0.26, 0.015),
          (0.32, 0.05),
          (0.32, 0.12),
          (0.24, 0.16),
          (0.17, 0.22),
          (0.17, 0.51),
          (0.22, 0.54),
          (0.24, 0.60),
          (0.24, 0.70),
          (0.0, 0.70),
        ];
      case PieceType.queen:
        return const [
          (0.27, 0.015),
          (0.32, 0.05),
          (0.32, 0.12),
          (0.24, 0.16),
          (0.16, 0.23),
          (0.15, 0.48),
          (0.20, 0.53),
          (0.22, 0.59),
          (0.17, 0.65),
          (0.13, 0.73),
          (0.22, 0.77),
          (0.18, 0.82),
          (0.0, 0.85),
        ];
      case PieceType.king:
        return const [
          (0.28, 0.015),
          (0.33, 0.05),
          (0.33, 0.12),
          (0.25, 0.16),
          (0.16, 0.23),
          (0.15, 0.51),
          (0.20, 0.56),
          (0.22, 0.62),
          (0.16, 0.68),
          (0.13, 0.76),
          (0.22, 0.80),
          (0.18, 0.85),
          (0.0, 0.88),
        ];
    }
  }

  void _addKnightHead(
    List<_Face> faces,
    double centerX,
    double centerZ,
    _PieceMaterial material,
  ) {
    const outline = <(double, double)>[
      (-0.13, 0.35),
      (-0.19, 0.46),
      (-0.15, 0.57),
      (-0.07, 0.65),
      (-0.10, 0.78),
      (0.00, 0.72),
      (0.08, 0.69),
      (0.17, 0.61),
      (0.12, 0.55),
      (0.21, 0.52),
      (0.13, 0.47),
      (0.02, 0.43),
      (0.00, 0.35),
    ];
    final front = <Chess3DVector>[
      for (final point in outline)
        Chess3DVector(centerX + point.$1, point.$2, centerZ - 0.085),
    ];
    final back = <Chess3DVector>[
      for (final point in outline)
        Chess3DVector(centerX + point.$1, point.$2, centerZ + 0.085),
    ];
    _addFace(faces, front, material.highlight, shade: 0.90);
    _addFace(faces, back.reversed.toList(), material.shadow, shade: 0.95);
    for (var index = 0; index < front.length; index++) {
      final next = (index + 1) % front.length;
      _addFace(
        faces,
        [front[index], front[next], back[next], back[index]],
        material.shadow,
        shade: 0.92,
      );
    }
    // A small raised mane follows the back of the horse's head.
    _addBox(faces, centerX - 0.09, 0.52, centerZ, 0.055, 0.25, 0.10, material);
  }

  void _addLathe(
    List<_Face> faces,
    double centerX,
    double centerZ,
    List<(double, double)> profile,
    _PieceMaterial material,
  ) {
    const segments = 16;
    for (var layer = 0; layer < profile.length - 1; layer++) {
      final lower = profile[layer];
      final upper = profile[layer + 1];
      for (var segment = 0; segment < segments; segment++) {
        final angleA = math.pi * 2 * segment / segments;
        final angleB = math.pi * 2 * (segment + 1) / segments;
        final normalAngle = (angleA + angleB) / 2;
        final light = 0.78 + 0.22 * (0.5 + 0.5 * math.cos(normalAngle - 0.8));
        final color = Color.lerp(material.shadow, material.highlight, light)!;
        _addFace(faces, [
          Chess3DVector(
            centerX + lower.$1 * math.cos(angleA),
            lower.$2,
            centerZ + lower.$1 * math.sin(angleA),
          ),
          Chess3DVector(
            centerX + lower.$1 * math.cos(angleB),
            lower.$2,
            centerZ + lower.$1 * math.sin(angleB),
          ),
          Chess3DVector(
            centerX + upper.$1 * math.cos(angleB),
            upper.$2,
            centerZ + upper.$1 * math.sin(angleB),
          ),
          Chess3DVector(
            centerX + upper.$1 * math.cos(angleA),
            upper.$2,
            centerZ + upper.$1 * math.sin(angleA),
          ),
        ], color);
      }
    }
    final first = profile.first;
    if (first.$1 > 0.01) {
      _addFace(
        faces,
        [
          for (var index = segments - 1; index >= 0; index--)
            Chess3DVector(
              centerX + first.$1 * math.cos(math.pi * 2 * index / segments),
              first.$2,
              centerZ + first.$1 * math.sin(math.pi * 2 * index / segments),
            ),
        ],
        material.shadow,
        shade: 0.88,
      );
    }
  }

  void _addBox(
    List<_Face> faces,
    double centerX,
    double centerY,
    double centerZ,
    double width,
    double height,
    double depth,
    _PieceMaterial material,
  ) {
    final x0 = centerX - width / 2;
    final x1 = centerX + width / 2;
    final y0 = centerY - height / 2;
    final y1 = centerY + height / 2;
    final z0 = centerZ - depth / 2;
    final z1 = centerZ + depth / 2;
    final a = Chess3DVector(x0, y0, z0);
    final b = Chess3DVector(x1, y0, z0);
    final c = Chess3DVector(x1, y0, z1);
    final d = Chess3DVector(x0, y0, z1);
    final e = Chess3DVector(x0, y1, z0);
    final f = Chess3DVector(x1, y1, z0);
    final g = Chess3DVector(x1, y1, z1);
    final h = Chess3DVector(x0, y1, z1);
    _addFace(faces, [a, b, f, e], material.shadow, shade: 0.84);
    _addFace(faces, [b, c, g, f], material.highlight, shade: 0.90);
    _addFace(faces, [c, d, h, g], material.shadow, shade: 0.88);
    _addFace(faces, [d, a, e, h], material.shadow, shade: 0.82);
    _addFace(faces, [e, f, g, h], material.highlight);
    _addFace(faces, [d, c, b, a], material.shadow, shade: 0.86);
  }

  void _addFace(
    List<_Face> faces,
    List<Chess3DVector> vertices,
    Color color, {
    double shade = 1.0,
  }) {
    final averageDepth =
        vertices
            .map(projection.depthOf)
            .fold<double>(0, (sum, depth) => sum + depth) /
        vertices.length;
    faces.add(
      _Face(
        vertices: vertices,
        color: Color.lerp(color, Colors.white, (shade - 1).abs() * 0.08)!,
        depth: averageDepth,
      ),
    );
  }

  void _drawFaces(Canvas canvas, List<_Face> faces) {
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final face in faces) {
      final path = Path();
      for (var index = 0; index < face.vertices.length; index++) {
        final point = projection.project(face.vertices[index]);
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      paint.color = face.color;
      canvas.drawPath(path, paint);
    }
  }

  void _drawPieceShadows(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x500D0E11)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        size.shortestSide * 0.006,
      );
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final square = Square(file, rank);
        if (position.pieceAt(square) == null) {
          continue;
        }
        final center = projection.centerOf(square, height: 0.01);
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: size.shortestSide * 0.052,
            height: size.shortestSide * 0.020,
          ),
          paint,
        );
      }
    }
  }

  void _drawMarkers(Canvas canvas, Size size) {
    final radius = size.shortestSide * 0.014;
    final fill = Paint()
      ..color = const Color(0xAA17202B)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xE8DDF4B2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.008;

    for (final move in targets) {
      final center = projection.centerOf(move.to, height: 0.012);
      if (move.isCapture) {
        canvas.drawCircle(center, radius * 2.2, stroke);
      } else {
        canvas.drawCircle(center, radius * 0.72, fill);
        canvas.drawCircle(center, radius * 0.48, stroke);
      }
    }
  }

  void _drawCoordinates(Canvas canvas, Size size) {
    final fontSize = math.max(8.0, size.shortestSide * 0.023);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: const Color(0xCC382719),
      height: 1,
    );

    for (var row = 0; row < 8; row++) {
      final rankSquare = projection.squareAtVisualPosition(0, row);
      final rankText = (rankSquare.rank + 1).toString();
      final rankPainter = TextPainter(
        text: TextSpan(text: rankText, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final rankPoint = projection.project(
        Chess3DVector(-3.88, 0.015, row.toDouble() - 3.5),
      );
      rankPainter.paint(
        canvas,
        Offset(
          rankPoint.dx - rankPainter.width / 2,
          rankPoint.dy - rankPainter.height / 2,
        ),
      );

      final fileSquare = projection.squareAtVisualPosition(row, 7);
      final fileText = String.fromCharCode(97 + fileSquare.file);
      final filePainter = TextPainter(
        text: TextSpan(
          text: fileText,
          style: style.copyWith(color: const Color(0xDDF4E5D2)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final filePoint = projection.project(
        Chess3DVector(row.toDouble() - 3.5, 0.016, 3.88),
      );
      filePainter.paint(
        canvas,
        Offset(
          filePoint.dx - filePainter.width / 2,
          filePoint.dy - filePainter.height / 2,
        ),
      );
    }
  }

  void _drawCursor(Canvas canvas) {
    if (!cursorVisible) {
      return;
    }
    final path = Path();
    final polygon = projection.polygonOf(cursor);
    path.moveTo(polygon.first.dx, polygon.first.dy);
    for (final point in polygon.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = projection.size.shortestSide * 0.009
        ..color = BoardColors.keyboardCursor,
    );
  }

  void _drawOuterRim(Canvas canvas) {
    final path = Path();
    const half = 4.29;
    final points = [
      projection.project(const Chess3DVector(-half, -0.01, -half)),
      projection.project(const Chess3DVector(half, -0.01, -half)),
      projection.project(const Chess3DVector(half, -0.01, half)),
      projection.project(const Chess3DVector(-half, -0.01, half)),
    ];
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = projection.size.shortestSide * 0.007
        ..color = const Color(0xC3C38D5E),
    );
  }

  @override
  bool shouldRepaint(covariant Chess3DScenePainter oldDelegate) => true;
}

class ChessBoardProjection {
  const ChessBoardProjection({
    required this.size,
    required this.yaw,
    required this.pitch,
    required this.flipped,
  });

  final Size size;
  final double yaw;
  final double pitch;
  final bool flipped;

  double get _scale => size.shortestSide / 11.6;

  Offset project(Chess3DVector point) {
    final cosineYaw = math.cos(yaw);
    final sineYaw = math.sin(yaw);
    final cosinePitch = math.cos(pitch);
    final sinePitch = math.sin(pitch);
    final rotatedX = point.x * cosineYaw - point.z * sineYaw;
    final rotatedZ = point.x * sineYaw + point.z * cosineYaw;
    final depth = rotatedZ * cosinePitch + point.y * sinePitch;
    final perspective = 40 / (40 - depth);
    return Offset(
      size.width / 2 + rotatedX * perspective * _scale,
      size.height * 0.52 -
          (point.y * cosinePitch - rotatedZ * sinePitch) * perspective * _scale,
    );
  }

  double depthOf(Chess3DVector point) {
    final rotatedZ = point.x * math.sin(yaw) + point.z * math.cos(yaw);
    return rotatedZ * math.cos(pitch) + point.y * math.sin(pitch);
  }

  Square squareAtVisualPosition(int column, int row) {
    return Square(flipped ? 7 - column : column, flipped ? row : 7 - row);
  }

  (int, int) visualPosition(Square square) {
    return (
      flipped ? 7 - square.file : square.file,
      flipped ? square.rank : 7 - square.rank,
    );
  }

  Chess3DVector worldCenterOf(Square square, {double height = 0}) {
    final visual = visualPosition(square);
    return Chess3DVector(visual.$1 - 3.5, height, visual.$2 - 3.5);
  }

  Offset centerOf(Square square, {double height = 0}) {
    return project(worldCenterOf(square, height: height));
  }

  List<Offset> polygonOf(Square square) {
    final center = worldCenterOf(square);
    return [
      project(Chess3DVector(center.x - 0.5, 0, center.z - 0.5)),
      project(Chess3DVector(center.x + 0.5, 0, center.z - 0.5)),
      project(Chess3DVector(center.x + 0.5, 0, center.z + 0.5)),
      project(Chess3DVector(center.x - 0.5, 0, center.z + 0.5)),
    ];
  }
}

class Chess3DVector {
  const Chess3DVector(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class _Face {
  const _Face({
    required this.vertices,
    required this.color,
    required this.depth,
  });

  final List<Chess3DVector> vertices;
  final Color color;
  final double depth;
}

class _PieceMaterial {
  const _PieceMaterial({required this.highlight, required this.shadow});

  final Color highlight;
  final Color shadow;
}
