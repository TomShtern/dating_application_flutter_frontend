import 'package:flutter/material.dart';

import '../features/home/app_home_screen.dart';
import '../theme/app_theme.dart';

class DatingApp extends StatelessWidget {
  const DatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dating App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppHomeScreen(),
    );
  }
}
