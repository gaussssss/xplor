import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/explorer/presentation/pages/explorer_page.dart';

class XplorApp extends StatelessWidget {
  const XplorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xplor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const ExplorerPage(),
    );
  }
}
