# Grand Chess

**Language / Bahasa:** [English](README.md) | [Bahasa Indonesia](README.id.md)

Grand Chess is a Flutter chess app for two people sharing one device. It uses a chess engine written in Dart and a perspective 3D board that can be rotated by dragging.

[Flutter platform support](https://docs.flutter.dev/reference/supported-platforms) includes Android, iOS, Windows, macOS, Linux, and the web. This repository's GitHub Actions workflow builds these targets so support is checked by CI, not inferred from the Flutter label alone.

## Current features

- Local two-player games on one device.
- 3D board and sculpted 3D-style pieces rendered with Flutter Canvas; no separate 3D engine is required.
- Drag an empty part of the board to rotate the view through 360 degrees. Use the reset icon to return to the default angle.
- Select a piece to see legal destinations. Tapping and dragging pieces are supported.
- Move history, board flip, promotion choice, check, checkmate, stalemate, castling, and en passant.
- Responsive layouts for narrow screens and wide desktop windows.
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

Grand Chess currently focuses on local play. It does not yet provide a computer opponent, online matchmaking, cloud accounts, saved game files, sound effects, or signed App Store packages. iOS signing and store submission need credentials owned by the project maintainer.

The repository description and source-code license must be confirmed by the owner before announcing a public release. Real-device visual checks are also needed for Android, Windows, macOS, Linux, and web browsers.

## Project documents

- Product plan: [English](Grand-Chess-PRD.md) | [Bahasa Indonesia](Grand-Chess-PRD.id.md)
- Technical decisions: [English](Grand-Chess-ADR.md) | [Bahasa Indonesia](Grand-Chess-ADR.id.md)
- Contributing guide: [English](CONTRIBUTING.md) | [Bahasa Indonesia](CONTRIBUTING.id.md)
- Changelog: [English](CHANGELOG.md) | [Bahasa Indonesia](CHANGELOG.id.md)
- Security policy: [English](.github/SECURITY.md) | [Bahasa Indonesia](.github/SECURITY.id.md)

## Contributing

Start with the contributing guide before editing the code. Keep changes focused, run formatting, analysis, and tests, and open a pull request with a short explanation and test results.
