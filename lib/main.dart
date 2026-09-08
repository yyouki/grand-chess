import 'package:flutter/material.dart';

void main() {
  runApp(const GrandChessApp());
}

class GrandChessApp extends StatelessWidget {
  const GrandChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grand Chess',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('Grand Chess — Foundation')),
      ),
    );
  }
}
