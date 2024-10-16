import 'package:flutter/material.dart';
import 'package:open_street_map_example/map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Map',
      home: MapScreen(),
    );
  }
}
