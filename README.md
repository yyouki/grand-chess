# Grand Chess

**Language / Bahasa:** [English](README.md) | [Bahasa Indonesia](README.id.md)

Grand Chess is a cross-platform Flutter chess app with a Dart rules engine, a sculpted perspective 3D board, and an offline bot. On supported phones, the chess table opens in immersive landscape mode.

[Flutter platform support](https://docs.flutter.dev/reference/supported-platforms) includes Android, iOS, Windows, macOS, Linux, and the web. This repository's GitHub Actions workflow builds these targets so support is checked by CI, not inferred from the Flutter label alone.

## Current features

- Local two-player games on one device, plus a built-in offline bot with Easy and Tactical styles. The bot uses legal moves from the same engine; it is a lightweight bot, not Stockfish.
- A perspective 3D board and sculpted chess pieces rendered with Flutter Canvas.
- Tap a piece to select it, then tap a highlighted destination. Dragging a piece never moves it.
- Drag empty board space to rotate the camera through 360 degrees and tilt the view. Use the reset button to restore the default angle.
- Flat uppercase A–H and 1–8 coordinates, animated piece movement, and selectable board and piece finishes.
- Move history, flip board, undo/redo, pawn promotion, check/checkmate/stalemate, castling, en passant, and copy/export of FEN and PGN text.
- Optional chess clocks: Unlimited, Bullet 1+0, Blitz 3+2 or 5+3, and Rapid 10+0 or 15+10. Increment is added after a move and a flag fall awards the opponent the game.
- Chess uses immersive landscape mode on supported mobile devices. Desktop targets use a full-window chess layout without forcing the operating-system window into fullscreen.
- A separate 3D Arcade with playable Cube Tic-Tac-Toe and Tower Builder.
- Automated formatting, static analysis, tests, and platform build checks in GitHub Actions.

## Platform status

The goal is one shared Dart codebase. A green workflow run is the source of truth for whether a target currently builds.

| Target | Build command | Important note |
| --- | --- | --- |
| Android | `flutter build apk --release` | APK can be installed on a compatible Android device. |
| Windows | `flutter build windows --release` | Build on Windows with Visual Studio C++ tools. |
| Linux | `flutter build linux --release` | Needs Clang, CMake, Ninja, GTK development files, and pkg-config. |
| macOS | `flutter build macos --release` | Build on macOS with Xcode. |
| iOS | `flutter build ios --release --no-codesign` | CI checks compilation; distribution requires Apple signing. |
| Web | `flutter build web --release` | Runs in a supported modern browser. |

Flutter supports these target families, but a successful CI build does not replace testing on real devices. See [Flutter's official platform list](https://docs.flutter.dev/reference/supported-platforms).

## Try the app

### Download a test build

1. Open the repository's [Actions page](https://github.com/yyouki/grand-chess/actions).
2. Select a successful run on the commit you want to test.
3. Open **Artifacts** and download the Android release artifact.
4. Extract the downloaded ZIP. Install the file named `app-release.apk`, not the outer artifact ZIP.

Artifacts are temporary CI outputs. A version tag starting with `v` triggers the release workflow after all required tests and builds pass.

### Build from source

Install the Flutter stable SDK first. Platform-specific requirements are listed in the official [Flutter setup guides](https://docs.flutter.dev/platform-integration).

This repository keeps generated native runner folders out of source control. Generate them once from the project root:

~~~sh
flutter create . --project-name grand_chess --platforms=android,ios,web,windows,linux,macos
flutter pub get
~~~

Build the target supported by your computer:

~~~sh
flutter run
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter build apk --release
flutter build web --release
~~~

Windows desktop builds must run on Windows. macOS and iOS builds must run on macOS. Linux desktop builds need the packages listed in the Linux section of the [Flutter guide](https://docs.flutter.dev/platform-integration/linux/setup).

## Project layout

~~~text
lib/
  app/             App entry point and application setup
  chess_engine/    Chess rules and move validation
  game/            Current game state and player actions
  ui/
    screens/       Home, setup, and game screens
    theme/         Board and application colors
    widgets/       Reusable controls and the 3D board renderer
test/
  chess_engine/    Tests for chess rules
  game/            Tests for the game controller
  integration/     Full-game tests
  ui/               Board, screens, and layout tests
.github/
  workflows/       CI, release, and branch-maintenance automation
~~~

Keep chess rules independent from widgets. Put reusable display logic in `ui/widgets`, screen-level flows in `ui/screens`, and add a test whenever a behavior changes.

## Known limitations before a public 1.0 release

The built-in bot is a lightweight offline opponent, not a Stockfish-strength engine. Online matchmaking, cloud accounts, persistent save/resume, sound effects, a full 3D model/PBR pipeline, and signed App Store packages are not yet included. iOS signing and store submission need credentials owned by the project maintainer.

The owner still needs to choose a source-code license before announcing a public release. CI builds pass, but visual checks on real Android/iOS devices and desktop computers are still needed.

## Project documents

- Product plan: [English](docs/PRODUCT_PLAN.md) | [Bahasa Indonesia](docs/PRODUCT_PLAN.id.md)
- Technical decisions: [English](docs/ARCHITECTURE.md) | [Bahasa Indonesia](docs/ARCHITECTURE.id.md)
- Contributing guide: [English](CONTRIBUTING.md) | [Bahasa Indonesia](CONTRIBUTING.id.md)
- Changelog: [English](docs/CHANGELOG.md) | [Bahasa Indonesia](docs/CHANGELOG.id.md)
- Security policy: [English](.github/SECURITY.md) | [Bahasa Indonesia](.github/SECURITY.id.md)

## Contributing

Start with the contributing guide before editing the code. Keep changes focused, run formatting, analysis, and tests, and open a pull request with a short explanation and test results.
