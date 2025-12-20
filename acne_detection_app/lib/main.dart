import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'controllers/detection_controller.dart'; 
import 'pages/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DetectionController()),
      ],
      child: MaterialApp(
        title: 'Acne Detector',
        home: const Home(),
      ),
    );
  }
}