import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const VideoHubApp());
}

class VideoHubApp extends StatelessWidget {
  const VideoHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '影视台',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
