import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/app/grand_chess_app.dart';
import 'package:grand_chess/ui/screens/game_screen.dart';
import 'package:grand_chess/ui/screens/home_screen.dart';
import 'package:grand_chess/ui/screens/local_game_setup_screen.dart';

import 'test_helpers.dart';

Future<void> openSetup(WidgetTester tester) async {
  await tester.pumpWidget(const GrandChessApp());
  await tester.tap(keyed('new-local-game'));
  await tester.pumpAndSettle();
}

Future<void> startGame(WidgetTester tester) async {
  await tester.tap(keyed('start-game'));
  await tester.pumpAndSettle();
}

void main() {
  group('home screen', () {
    testWidgets('shows the title, the tagline and the start button', (
      tester,
    ) async {
      await tester.pumpWidget(const GrandChessApp());

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(textOf(tester, 'home-title'), 'Grand Chess');
      expect(keyed('home-tagline'), findsOneWidget);
      expect(keyed('new-local-game'), findsOneWidget);
      expect(find.text('New Local Game'), findsOneWidget);
    });

    testWidgets('does not show the foundation placeholder', (tester) async {
      await tester.pumpWidget(const GrandChessApp());

      expect(find.textContaining('Foundation'), findsNothing);
    });

    testWidgets('opens the setup screen from New Local Game', (tester) async {
      await openSetup(tester);

      expect(find.byType(LocalGameSetupScreen), findsOneWidget);
      expect(keyed('white-name-field'), findsOneWidget);
      expect(keyed('black-name-field'), findsOneWidget);
      expect(keyed('start-game'), findsOneWidget);
    });
  });

  group('setup screen', () {
    testWidgets('starts a game with the default names', (tester) async {
      await openSetup(tester);

      await startGame(tester);

      expect(find.byType(GameScreen), findsOneWidget);
      expect(textOf(tester, 'turn-indicator'), 'White to move');
      expect(markerSquares('piece-'), hasLength(32));
    });

    testWidgets('lets players choose a clock preset before starting', (
      tester,
    ) async {
      await openSetup(tester);
      expect(keyed('time-control-choice'), findsOneWidget);

      await tester.tap(keyed('time-control-choice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 + 2 · Blitz').last);
      await tester.pumpAndSettle();

      await tester.tap(keyed('start-game'));
      await tester.pump();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(keyed('clock-white-time'), findsOneWidget);
      expect(keyed('clock-black-time'), findsOneWidget);
      expect(find.text('03:00'), findsNWidgets(2));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('starts a game against the built-in offline bot', (
      tester,
    ) async {
      await openSetup(tester);
      await tester.tap(keyed('game-mode-choice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play against a bot').last);
      await tester.pumpAndSettle();

      expect(keyed('bot-level-choice'), findsOneWidget);
      expect(keyed('black-name-field'), findsNothing);
      await startGame(tester);
      expect(find.byType(GameScreen), findsOneWidget);

      await playMoves(tester, ['e2e4']);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'turn-indicator'), 'White to move');
    });

    testWidgets('uses the names that were entered', (tester) async {
      await openSetup(tester);
      await tester.enterText(keyed('white-name-field'), 'Alice');
      await tester.enterText(keyed('black-name-field'), 'Bob');

      await startGame(tester);

      expect(textOf(tester, 'turn-indicator'), 'Alice (White) to move');
      await playMoves(tester, ['e2e4']);
      expect(textOf(tester, 'turn-indicator'), 'Bob (Black) to move');
    });

    testWidgets('trims names and falls back to the defaults for blank ones', (
      tester,
    ) async {
      await openSetup(tester);
      await tester.enterText(keyed('white-name-field'), '   ');
      await tester.enterText(keyed('black-name-field'), '  Bob  ');

      await startGame(tester);

      expect(textOf(tester, 'turn-indicator'), 'White to move');
      await playMoves(tester, ['e2e4']);
      expect(textOf(tester, 'turn-indicator'), 'Bob (Black) to move');
    });

    testWidgets('starts the game from the keyboard action of the last field', (
      tester,
    ) async {
      await openSetup(tester);
      await tester.enterText(keyed('black-name-field'), 'Bob');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      await playMoves(tester, ['e2e4']);
      expect(textOf(tester, 'turn-indicator'), 'Bob (Black) to move');
    });

    testWidgets('goes back from the game to the setup and to the home screen', (
      tester,
    ) async {
      await openSetup(tester);
      await startGame(tester);

      await tester.tap(keyed('exit-game-button'));
      await tester.pumpAndSettle();
      expect(find.byType(LocalGameSetupScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
