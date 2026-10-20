import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_chess/main.dart';

void main() {
  testWidgets('GrandChessApp builds and shows the foundation shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GrandChessApp());

    expect(find.text('Grand Chess — Foundation'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
