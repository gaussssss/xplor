import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XplorApp());

  doWhenWindowReady(() {
    appWindow.maximize();
    appWindow.show();
  });
}
