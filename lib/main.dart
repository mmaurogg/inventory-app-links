import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();
  await initFirebaseSafely();
  runApp(const EcommerceApp());
}

/// Inicializa Firebase sin propagar errores: los registra y continúa.
Future<void> initFirebaseSafely({
  Future<void> Function() init = _defaultInit,
  void Function(Object error, StackTrace stack) log = _defaultLog,
}) async {
  try {
    await init();
  } catch (e, s) {
    log(e, s);
  }
}

Future<void> _defaultInit() => Firebase.initializeApp();

void _defaultLog(Object error, StackTrace stack) {
  debugPrint('Firebase initialization failed: $error');
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'main',
      context: ErrorDescription('while initializing Firebase'),
    ),
  );
}
