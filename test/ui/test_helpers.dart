import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/chess_engine/chess_engine.dart' hide Color;
import 'package:grand_chess/game/game_controller.dart';
import 'package:grand_chess/ui/screens/game_screen.dart';
import 'package:grand_chess/ui/widgets/chess_board.dart';
import 'package:grand_chess/ui/widgets/piece_glyph.dart';

const String foolsMateFen =
    'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';
const String castlingFen = 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1';
const String enPassantFen = '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1';
const String promotionFen = '8/4P3/8/8/8/k7/8/4K3 w - - 0 1';
const String stalemateInOneFen = '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1';

const List<String> foolsMateMoves = <String>['f2f3', 'e7e5', 'g2g4', 'd8h4'];
const List<String> checkLineMoves = <String>['e2e4', 'f7f6', 'd1h5'];

GameState stateFromFen(String fen) {
  final result = GameState.fromFen(fen);
  expect(result.isOk, isTrue, reason: 'expected a valid position: $fen');
  return result.valueOrNull!;
}

Finder squareFinder(String name) => find.byKey(ValueKey('square-$name'));

Finder pieceFinder(String name) => find.byKey(ValueKey('piece-$name'));

Finder keyed(String key) => find.byKey(ValueKey(key));

String textOf(WidgetTester tester, String key) {
  return tester.widget<Text>(keyed(key)).data!;
}

Set<String> markerSquares(String prefix) {
  return find
      .byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> && key.value.startsWith(prefix);
      })
      .evaluate()
      .map(
        (element) => (element.widget.key! as ValueKey<String>).value.substring(
          prefix.length,
        ),
      )
      .toSet();
}

Piece? pieceOn(WidgetTester tester, String name) {
  final finder = pieceFinder(name);
  if (finder.evaluate().isEmpty) {
    return null;
  }
  return tester.widget<PieceGlyph>(finder).piece;
}

List<String> sanList(GameController controller) {
  return controller.gameState.moveHistory.map((record) => record.san).toList();
}

bool isWhiteAtBottom(WidgetTester tester) {
  final a1 = tester.getCenter(squareFinder('a1'));
  final h8 = tester.getCenter(squareFinder('h8'));
  return a1.dy > h8.dy && a1.dx < h8.dx;
}

bool isBlackAtBottom(WidgetTester tester) {
  final a1 = tester.getCenter(squareFinder('a1'));
  final h8 = tester.getCenter(squareFinder('h8'));
  return a1.dy < h8.dy && a1.dx > h8.dx;
}

Future<void> tapSquare(WidgetTester tester, String name) async {
  await tester.tap(squareFinder(name));
  await tester.pump();
}

Future<void> playMoves(WidgetTester tester, List<String> moves) async {
  for (final move in moves) {
    await tapSquare(tester, move.substring(0, 2));
    await tapSquare(tester, move.substring(2, 4));
  }
}

Future<void> dragPiece(WidgetTester tester, String from, String to) async {
  final gesture = await tester.startGesture(
    tester.getCenter(pieceFinder(from)),
  );
  await tester.pump();
  await gesture.moveBy(const Offset(0, -30));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(squareFinder(to)));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void useScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<GameController> pumpBoard(
  WidgetTester tester, {
  String? fen,
  double side = 400,
}) async {
  final controller = fen == null
      ? GameController()
      : GameController(initialState: stateFromFen(fen));
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: side,
            height: side,
            child: ChessBoard(controller: controller),
          ),
        ),
      ),
    ),
  );
  return controller;
}

Future<void> pumpGameScreen(
  WidgetTester tester, {
  String? fen,
  String whiteName = 'White',
  String blackName = 'Black',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(
        whiteName: whiteName,
        blackName: blackName,
        initialState: fen == null ? null : stateFromFen(fen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
