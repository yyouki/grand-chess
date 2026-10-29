import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/ui/widgets/chess_board_3d_renderer.dart';

void main() {
  group('ChessBoardProjection camera hemisphere', () {
    const size = Size(400, 300);

    test('camera remains above the board before the horizon', () {
      const projection = ChessBoardProjection(
        size: size,
        yaw: 0,
        pitch: 1.2,
        flipped: false,
      );

      expect(projection.depthOf(const Chess3DVector(0, 1, 0)), greaterThan(0));
    });

    test('camera moves below the board after crossing the horizon', () {
      const projection = ChessBoardProjection(
        size: size,
        yaw: 0,
        pitch: 1.9,
        flipped: false,
      );

      expect(projection.depthOf(const Chess3DVector(0, 1, 0)), lessThan(0));
    });
  });
}
