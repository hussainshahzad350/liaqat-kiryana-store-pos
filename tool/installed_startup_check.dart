import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/auth/login_screen.dart';

void main() {
  runZonedGuarded(() {
    app.main();
    var attempts = 0;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      var login = false;
      void visit(Element element) {
        if (element.widget is LoginScreen) login = true;
        element.visitChildren(visit);
      }
      final root = WidgetsBinding.instance.rootElement;
      if (root != null) visit(root);
      if (login || ++attempts >= 30) {
        File('startup-check.txt').writeAsStringSync(
            login ? 'PASS: LoginScreen rendered' : 'FAIL: LoginScreen timed out');
        exit(login ? 0 : 1);
      }
    });
  }, (error, stack) {
    File('startup-check.txt').writeAsStringSync('$error\n$stack');
    exit(1);
  });
}
