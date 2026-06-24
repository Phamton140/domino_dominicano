import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Oculta las barras del sistema (status y navigation) y usa
  // pantalla completa edge-to-edge. La app aprovecha todo el
  // espacio de la pantalla del dispositivo, evitando que los
  // botones del sistema interrumpan la interacción.
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const DominoDominicanoApp());
}

class DominoDominicanoApp extends StatelessWidget {
  const DominoDominicanoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
        title: 'Dominó Dominicano',
        theme: DominoTheme.build(),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
