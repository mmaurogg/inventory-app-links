import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../data/app_links_source.dart';
import '../domain/link_mapper.dart';

/// Recibe enlaces entrantes y los traduce en navegación.
class LinkHandler {
  LinkHandler({
    required LinkSource source,
    required void Function(String location) onNavigate,
    String domain = AppConfig.domain,
  })  : _source = source,
        _onNavigate = onNavigate,
        _domain = domain;

  final LinkSource _source;
  final void Function(String location) _onNavigate;
  final String _domain;

  StreamSubscription<Uri>? _subscription;

  /// Procesa el enlace inicial y se suscribe al flujo de enlaces.
  ///
  /// Los errores se registran y nunca detienen la App.
  Future<void> start() async {
    if (_subscription != null) return;

    try {
      final initial = await _source.getInitialLink();
      if (initial != null) handle(initial);
    } catch (error, stack) {
      _logError(error, stack);
    }

    try {
      _subscription = _source.uriLinkStream.listen(
        handle,
        onError: _logError,
      );
    } catch (error, stack) {
      _logError(error, stack);
    }
  }

  /// Resuelve [uri] e invoca `onNavigate` solo si pertenece al dominio propio.
  void handle(Uri uri) {
    final resolution = LinkMapper.resolve(uri, domain: _domain);
    if (resolution is LinkNavigate) {
      _onNavigate(resolution.location);
    }
  }

  /// Cancela la suscripción al flujo de enlaces.
  Future<void> dispose() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  void _logError(Object error, [StackTrace? stack]) {
    // Solo texto: parsear la traza con debugPrintStack puede lanzar con
    // trazas no estándar y el registro nunca debe propagar excepciones.
    debugPrint('LinkHandler: error al procesar enlace: $error');
    if (stack != null) debugPrint(stack.toString());
  }
}
