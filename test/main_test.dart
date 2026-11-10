import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_links/app.dart';
import 'package:inventory_app_links/data/app_links_source.dart';
import 'package:inventory_app_links/main.dart';

class _FakeLinkSource implements LinkSource {
  final StreamController<Uri> controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> getInitialLink() async => null;

  @override
  Stream<Uri> get uriLinkStream => controller.stream;
}

void main() {
  group('initFirebaseSafely', () {
    test('no propaga la excepción y llama a log cuando init lanza', () async {
      Object? loggedError;
      StackTrace? loggedStack;
      var logCalls = 0;

      await initFirebaseSafely(
        init: () async => throw StateError('boom'),
        log: (e, s) {
          logCalls++;
          loggedError = e;
          loggedStack = s;
        },
      );

      expect(logCalls, 1);
      expect(loggedError, isA<StateError>());
      expect(loggedStack, isNotNull);
    });

    test('no llama a log cuando init es exitoso', () async {
      var initCalls = 0;
      var logCalls = 0;

      await initFirebaseSafely(
        init: () async => initCalls++,
        log: (_, _) => logCalls++,
      );

      expect(initCalls, 1);
      expect(logCalls, 0);
    });
  });

  group('pubspec.yaml', () {
    test('declara go_router, app_links y firebase_core', () {
      final content = File('pubspec.yaml').readAsStringSync();
      expect(content, matches(RegExp(r'^\s+go_router:', multiLine: true)));
      expect(content, matches(RegExp(r'^\s+app_links:', multiLine: true)));
      expect(content, matches(RegExp(r'^\s+firebase_core:', multiLine: true)));
    });
  });

  group('EcommerceApp con LinkSource falso', () {
    late _FakeLinkSource source;

    setUp(() => source = _FakeLinkSource());
    tearDown(() async => source.controller.close());

    testWidgets('navega al detalle al recibir un enlace del host válido',
        (tester) async {
      await tester.pumpWidget(
        EcommerceApp(linkSource: source, initialLocation: '/ofertas'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Agregar al carrito'), findsNothing);

      source.controller.add(Uri.parse('https://tienda.example.com/productos/p1'));
      await tester.pumpAndSettle();

      expect(find.text('Audífonos inalámbricos'), findsWidgets);
      expect(find.text('Agregar al carrito'), findsOneWidget);
    });

    testWidgets('ignora enlaces de un host ajeno', (tester) async {
      await tester.pumpWidget(
        EcommerceApp(linkSource: source, initialLocation: '/ofertas'),
      );
      await tester.pumpAndSettle();

      source.controller.add(Uri.parse('https://otro.example.org/productos/p1'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar al carrito'), findsNothing);
    });
  });
}
