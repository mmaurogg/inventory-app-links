/// Resultado de interpretar un enlace entrante.
sealed class LinkResolution {
  const LinkResolution();
}

/// Navegar a [location], ya normalizada y sin query.
final class LinkNavigate extends LinkResolution {
  const LinkNavigate(this.location);

  final String location;

  @override
  bool operator ==(Object other) =>
      other is LinkNavigate && other.location == location;

  @override
  int get hashCode => location.hashCode;

  @override
  String toString() => 'LinkNavigate($location)';
}

/// Enlace ajeno al dominio propio: no se toca la navegación.
final class LinkDiscard extends LinkResolution {
  const LinkDiscard();

  @override
  bool operator ==(Object other) => other is LinkDiscard;

  @override
  int get hashCode => (LinkDiscard).hashCode;

  @override
  String toString() => 'LinkDiscard()';
}

/// Traduce un [Uri] entrante en una decisión de navegación (función pura).
abstract final class LinkMapper {
  static const String notFoundLocation = '/no-encontrado';

  static const Set<String> _fixedPaths = {
    '/',
    '/categorias',
    '/carrito',
    '/ofertas',
  };

  /// Decide qué hacer con [uri] según el [domain] propio.
  static LinkResolution resolve(Uri uri, {required String domain}) {
    if (uri.host.toLowerCase() != domain.toLowerCase()) {
      return const LinkDiscard();
    }

    final path = _normalize(uri.path);
    if (isSupportedPath(path)) {
      return LinkNavigate(path);
    }
    return const LinkNavigate(notFoundLocation);
  }

  /// Indica si [path] (ya normalizado) es una ruta soportada.
  static bool isSupportedPath(String path) {
    if (_fixedPaths.contains(path)) return true;

    for (final prefix in const ['/categorias/', '/productos/']) {
      if (path.startsWith(prefix)) {
        final id = path.substring(prefix.length);
        return id.isNotEmpty && !id.contains('/');
      }
    }
    return false;
  }

  static String _normalize(String path) {
    if (path.isEmpty) return '/';
    var result = path;
    while (result.length > 1 && result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
