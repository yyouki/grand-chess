import 'package:flutter/material.dart';

import '../ui/screens/home_screen.dart';
import '../ui/theme/app_theme.dart';

class GrandChessApp extends StatelessWidget {
  const GrandChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grand Chess',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
