import 'package:app_links/app_links.dart';

/// Fuente de enlaces entrantes. Permite simular `app_links` en pruebas.
abstract interface class LinkSource {
  /// Enlace con el que se abrió la App, o `null` si no hubo.
  Future<Uri?> getInitialLink();

  /// Enlaces recibidos mientras la App está en ejecución.
  Stream<Uri> get uriLinkStream;
}

/// Implementación de [LinkSource] que envuelve [AppLinks].
class AppLinksSource implements LinkSource {
  AppLinksSource([AppLinks? appLinks]) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;
}
