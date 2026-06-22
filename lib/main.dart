import 'package:flutter/material.dart';

import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() {
  runApp(const DominoDominicanoApp());
}

class DominoDominicanoApp extends StatelessWidget {
  const DominoDominicanoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dominó Dominicano',
      theme: DominoTheme.build(),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
