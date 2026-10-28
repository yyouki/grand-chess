# Contributing to Grand Chess

**Language / Bahasa:** [English](CONTRIBUTING.md) | [Bahasa Indonesia](CONTRIBUTING.id.md)

Thanks for helping improve Grand Chess. The following steps are meant to be clear for developers who are new to Flutter.

## Before editing

1. Read the [README](README.md) and [technical decisions](Grand-Chess-ADR.md).
2. Install the Flutter stable SDK and the tools required for the platform you want to build.
3. Generate missing native runner folders from the project root if needed:

~~~sh
flutter create . --project-name grand_chess --platforms=android,ios,web,windows,linux,macos
flutter pub get
~~~

## Code guidelines

- Keep chess rules out of UI widgets.
- Use descriptive names and small functions with one responsibility.
- Add tests when you fix a bug or change behavior.
- Keep new dependencies to a minimum and explain why they are needed.
- Keep formatting consistent with Dart's formatter.
- Do not commit signing keys, passwords, API tokens, or personal data.

## Verify a change

Run these commands before opening a pull request:

~~~sh
dart format .
flutter analyze
flutter test
~~~

Build the target you changed when the required operating system is available. GitHub Actions also runs automated checks and release builds.

## Pull requests

Describe the problem, summarize the change, and list the tests you ran. Include screenshots or a short screen recording when a visual change needs review. Keep one pull request focused on one topic and respond to review feedback before merging.
