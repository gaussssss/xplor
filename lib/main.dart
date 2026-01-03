import 'dart:io';

import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:window_manager/window_manager.dart';

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
  // Pré-initialiser window_manager sur desktop, ignorer si non supporté
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1400, 900),
        minimumSize: Size(1200, 800),
        center: true,
        titleBarStyle: TitleBarStyle.hidden,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        // verrouiller la taille mini + maximiser dès l’affichage
        await windowManager.setMinimumSize(const Size(1200, 800));
        await windowManager.show();
        await windowManager.focus();
        await windowManager.maximize();
      });
      // Fallback si la maximisation n'a pas été appliquée pendant waitUntilReadyToShow
      await windowManager.maximize();
    } catch (_) {
      // ignore si le plugin n'est pas dispo pendant le hot-reload
    }
  }

  runApp(const XplorApp());

  // Application tardive de la maximisation si la fenêtre n'était pas encore prête
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await windowManager.setMinimumSize(const Size(1200, 800));
        await windowManager.maximize();
      } catch (_) {
        // ignore
      }
    });
  }
}
