import 'dart:async';

import 'package:glados/glados.dart';
import 'package:inventory_app_links/data/app_links_source.dart';
import 'package:inventory_app_links/presentation/link_handler.dart';

const String kDomain = 'tienda.example.com';

final ExploreConfig kExploreConfig = ExploreConfig(numRuns: 100);

/// [LinkSource] falso controlable desde las pruebas.
class FakeLinkSource implements LinkSource {
  FakeLinkSource({this.initial, this.initialError, this.streamGetterError});

  final Uri? initial;
  final Object? initialError;
  final Object? streamGetterError;

  final StreamController<Uri> controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> getInitialLink() async {
    if (initialError != null) throw initialError!;
    return initial;
  }

  @override
  Stream<Uri> get uriLinkStream {
    if (streamGetterError != null) throw streamGetterError!;
    return controller.stream;
  }
}

/// Deja correr la cola de eventos para que el stream entregue sus datos.
Future<void> pump() => Future<void>.delayed(Duration.zero);

extension LinkHandlerAny on Any {
  /// Host ajeno: etiqueta minúscula + TLD, nunca igual al dominio propio.
  Generator<String> get foreignHost => combine2(
        list(choose('abcdefghijklmnopqrstuvwxyz'.split(''))),
        choose(['com', 'org', 'net', 'co']),
        (List<String> label, String tld) => '${label.join()}x.$tld',
      ).map((h) => h.toLowerCase() == kDomain ? 'otro.example.org' : h);

  /// Path arbitrario (soportado o no) con segmentos simples.
  Generator<String> get anyPath => list(
        list(choose('abcdefghijklmnopqrstuvwxyz0123456789'.split(''))),
      ).map((segments) => '/${segments.map((s) => s.join()).join('/')}');
}

void main() {
  group('LinkHandler', () {
    test('entrega el enlace inicial al arrancar (5.1)', () async {
      final source = FakeLinkSource(
        initial: Uri.parse('https://$kDomain/productos/p1'),
      );
      final navigated = <String>[];
      final handler = LinkHandler(
        source: source,
        onNavigate: navigated.add,
        domain: kDomain,
      );

      await handler.start();

      expect(navigated, ['/productos/p1']);
      await handler.dispose();
      await source.controller.close();
    });

    test('no navega si no hay enlace inicial', () async {
      final source = FakeLinkSource();
      final navigated = <String>[];
      final handler = LinkHandler(
        source: source,
        onNavigate: navigated.add,
        domain: kDomain,
      );

      await handler.start();

      expect(navigated, isEmpty);
      await handler.dispose();
      await source.controller.close();
    });

    test('entrega los enlaces del stream mientras está activo (5.2)',
        () async {
      final source = FakeLinkSource();
      final navigated = <String>[];
      final handler = LinkHandler(
        source: source,
        onNavigate: navigated.add,
        domain: kDomain,
      );

      await handler.start();
      source.controller
        ..add(Uri.parse('https://$kDomain/ofertas'))
        ..add(Uri.parse('https://$kDomain/categorias/c1/'));
      await pump();

      expect(navigated, ['/ofertas', '/categorias/c1']);
      await handler.dispose();
      await source.controller.close();
    });

    test('tras dispose el stream falso no tiene oyentes (5.9)', () async {
      final source = FakeLinkSource();
      final navigated = <String>[];
      final handler = LinkHandler(
        source: source,
        onNavigate: navigated.add,
        domain: kDomain,
      );

      await handler.start();
      expect(source.controller.hasListener, isTrue);

      await handler.dispose();

      expect(source.controller.hasListener, isFalse);
      await source.controller.close();
    });

    test('un error en getInitialLink no propaga y el stream sigue activo',
        () async {
      final source = FakeLinkSource(initialError: StateError('fallo inicial'));
      final navigated = <String>[];
      final handler = LinkHandler(
        source: source,
        onNavigate: navigated.add,
        domain: kDomain,
      );

      await handler.start();
      source.controller.add(Uri.parse('https://$kDomain/carrito'));
      await pump();

      expect(navigated, ['/carrito']);
      await handler.dispose();
      await source.controller.close();
    });

    test('un error emitido por el stream no propaga ni lo detiene', () async {
      final source = FakeLinkSource();
      final navigated = <String>[];
      final handler = LinkHandler(
        source: source,
        onNavigate: navigated.add,
        domain: kDomain,
      );

      await handler.start();
      source.controller.addError(StateError('fallo de stream'));
      source.controller.add(Uri.parse('https://$kDomain/carrito'));
      await pump();

      expect(navigated, ['/carrito']);
      await handler.dispose();
      await source.controller.close();
    });

    test('un error al obtener el stream no propaga', () async {
      final source = FakeLinkSource(streamGetterError: StateError('sin stream'));
      final handler = LinkHandler(
        source: source,
        onNavigate: (_) {},
        domain: kDomain,
      );

      await handler.start();
      await handler.dispose();
      await source.controller.close();
    });

    // Feature: ecommerce-dynamic-links, Property 3: Para cualquier URI cuyo
    // host sea distinto del Dominio_Propio, sin importar su path o query,
    // LinkHandler.handle no invoca onNavigate.
    // Validates: Requirements 5.6
    Glados2<String, String>(any.foreignHost, any.anyPath, kExploreConfig).test(
      'Property 3: un host ajeno no invoca onNavigate',
      (host, path) {
        final navigated = <String>[];
        final handler = LinkHandler(
          source: FakeLinkSource(),
          onNavigate: navigated.add,
          domain: kDomain,
        );

        handler.handle(Uri.parse('https://$host$path?x=1'));

        expect(navigated, isEmpty);
      },
    );
  });
}
