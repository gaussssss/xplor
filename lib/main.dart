import 'dart:io';

import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos_window_utils.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de la fenêtre sans barre de titre (macOS uniquement)
  if (Platform.isMacOS) {
    await WindowManipulator.initialize(enableWindowDelegate: true);

    // Masquer la barre de titre et rendre le fond transparent
    WindowManipulator.makeTitlebarTransparent();
    WindowManipulator.hideTitle();
    WindowManipulator.enableFullSizeContentView();
  }

  runApp(const XplorApp());
}
