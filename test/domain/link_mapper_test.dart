import 'package:glados/glados.dart';
import 'package:inventory_app_links/domain/link_mapper.dart';

/// Dominio propio usado en todas las propiedades de este archivo.
const String kDomain = 'tienda.example.com';

/// Configuración común: mínimo 100 iteraciones por propiedad.
final ExploreConfig kExploreConfig = ExploreConfig(numRuns: 100);

/// Paths soportados sin parámetros.
const List<String> kFixedPaths = ['/', '/categorias', '/carrito', '/ofertas'];

/// Prefijos soportados que requieren un id de un solo segmento.
const List<String> kIdPrefixes = ['/categorias/', '/productos/'];

const String _letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _idChars = '$_letters'
    '0123456789-_.~';

/// Generadores reutilizables para las propiedades de `LinkMapper`.
extension LinkMapperAny on Any {
  /// Segmento no vacío, sin '/', '?' ni '#'.
  Generator<String> get idSegment => combine2(
        choose(_letters.split('')),
        list(choose(_idChars.split(''))),
        (String first, List<String> rest) => first + rest.join(),
      );

  /// Path soportado arbitrario (fijo o con id).
  Generator<String> get supportedPath => oneOf<String>([
        choose(kFixedPaths),
        combine2(
          choose(kIdPrefixes),
          idSegment,
          (String prefix, String id) => '$prefix$id',
        ),
      ]);

  /// Host igual al dominio propio con mayúsculas/minúsculas arbitrarias.
  Generator<String> get ownHost => list(this.bool).map((flags) {
        final chars = kDomain.split('');
        return [
          for (var i = 0; i < chars.length; i++)
            if (i < flags.length && flags[i])
              chars[i].toUpperCase()
            else
              chars[i],
        ].join();
      });

  /// Etiqueta de host válida (letras y dígitos, no vacía).
  Generator<String> get _hostLabel => combine2(
        choose(_letters.split('')),
        list(choose('${_letters}0123456789'.split(''))),
        (String first, List<String> rest) => first + rest.join(),
      );

  /// Host distinto de [kDomain] (comparado en minúsculas): subdominio extra,
  /// sufijo adicional, otro TLD o un host arbitrario.
  Generator<String> get foreignHost => oneOf<String>([
        _hostLabel.map((l) => '$l.$kDomain'),
        _hostLabel.map((l) => '$kDomain.$l'),
        _hostLabel.map((l) => 'tienda.example.$l'),
        _hostLabel.map((l) => '$l.example.com'),
        combine2(
          _hostLabel,
          _hostLabel,
          (String a, String b) => '$a.$b',
        ),
      ]).map(
        (h) => h.toLowerCase() == kDomain.toLowerCase() ? 'otro.$h' : h,
      );
}

/// Generadores de paths NO soportados, construidos desde categorías
/// explícitas (no por negación del predicado del mapper).
extension LinkMapperUnsupportedAny on Any {
  Generator<String> get unsupportedPath => oneOf<String>([
        // Primer segmento desconocido (empieza con 'zz', nunca coincide con
        // los segmentos soportados), con y sin segmentos extra.
        idSegment.map((s) => '/zz$s'),
        combine2(
          idSegment,
          idSegment,
          (String a, String b) => '/zz$a/$b',
        ),
        // Prefijos soportados sin id.
        choose(const ['/productos', '/productos/']),
        // Demasiados segmentos.
        combine3(
          choose(const ['categorias', 'productos']),
          idSegment,
          idSegment,
          (String p, String a, String b) => '/$p/$a/$b',
        ),
        // Paths fijos sin parámetros con segmentos extra.
        combine2(
          choose(const ['/carrito', '/ofertas']),
          idSegment,
          (String p, String a) => '$p/$a',
        ),
        // Path fijo seguido de segmento vacío intermedio.
        choose(const ['/carrito//x', '/categorias//x', '/productos//x']),
        // Prefijos casi iguales a segmentos soportados.
        combine2(
          choose(const ['/carritos', '/ofertas-', '/productosx', '/categoria']),
          idSegment,
          (String p, String a) => '$p/$a',
        ),
      ]);
}

extension LinkMapperMixedPathAny on Any {
  /// Path soportado o no soportado.
  Generator<String> get supportedOrUnsupportedPath =>
      oneOf<String>([supportedPath, unsupportedPath]);
}

Uri buildUri(String host, String path) => Uri.parse('https://$host$path');

void main() {
  group('LinkMapper', () {
    // Feature: ecommerce-dynamic-links, Property 1: Para cualquier path
    // soportado y cualquier URI con host igual al Dominio_Propio,
    // LinkMapper.resolve devuelve LinkNavigate con exactamente ese path.
    // Validates: Requirements 5.3, 5.4, 10.1
    Glados2<String, String>(any.ownHost, any.supportedPath, kExploreConfig).test(
      'Property 1: Mapeo de paths soportados',
      (host, path) {
        final result = LinkMapper.resolve(buildUri(host, path), domain: kDomain);

        expect(result, LinkNavigate(path));
      },
    );

    // Feature: ecommerce-dynamic-links, Property 2: Para cualquier path
    // soportado distinto de '/', resolve con una o más barras finales
    // devuelve lo mismo que sin barra final.
    // Validates: Requirements 5.5
    Glados3<String, String, int>(
      any.ownHost,
      any.supportedPath,
      any.intInRange(1, 4),
      kExploreConfig,
    ).test(
      'Property 2: Equivalencia con barra final',
      (host, path, slashes) {
        if (path == '/') return;
        final without =
            LinkMapper.resolve(buildUri(host, path), domain: kDomain);
        final withSlashes = LinkMapper.resolve(
          buildUri(host, '$path${'/' * slashes}'),
          domain: kDomain,
        );

        expect(withSlashes, without);
      },
    );

    // Feature: ecommerce-dynamic-links, Property 3: Para cualquier URI cuyo
    // host (sin distinguir mayúsculas) sea distinto del Dominio_Propio, sin
    // importar path o query, resolve devuelve LinkDiscard.
    // Validates: Requirements 5.6, 10.2
    Glados3<String, String, String>(
      any.foreignHost,
      any.supportedPath,
      any.idSegment,
      kExploreConfig,
    ).test(
      'Property 3: Descarte de hosts ajenos',
      (host, path, queryValue) {
        // Garantía del generador: el host difiere del dominio propio.
        expect(host.toLowerCase(), isNot(kDomain.toLowerCase()));

        final withoutQuery = buildUri(host, path);
        final withQuery = buildUri(host, '$path?q=$queryValue');

        expect(
          LinkMapper.resolve(withoutQuery, domain: kDomain),
          const LinkDiscard(),
        );
        expect(
          LinkMapper.resolve(withQuery, domain: kDomain),
          const LinkDiscard(),
        );
      },
    );

    // Feature: ecommerce-dynamic-links, Property 4: Para cualquier URI con
    // host igual al Dominio_Propio y un path que no pertenece al conjunto
    // soportado, resolve devuelve LinkNavigate('/no-encontrado').
    // Validates: Requirements 3.6, 5.7
    Glados2<String, String>(
      any.ownHost,
      any.unsupportedPath,
      kExploreConfig,
    ).test(
      'Property 4: Paths no soportados llevan a No_Encontrado',
      (host, path) {
        // Salvaguarda del generador: el path realmente no es soportado.
        expect(LinkMapper.isSupportedPath(path), isFalse);

        final result = LinkMapper.resolve(buildUri(host, path), domain: kDomain);

        expect(result, const LinkNavigate('/no-encontrado'));
      },
    );

    // Feature: ecommerce-dynamic-links, Property 5: Para cualquier URI con
    // host igual al Dominio_Propio y cualquier mapa de parámetros de consulta
    // o fragmento, resolve devuelve el mismo resultado que para la misma URI
    // sin consulta ni fragmento.
    // Validates: Requirements 5.8
    Glados3<String, String, List<String>>(
      any.ownHost,
      any.supportedOrUnsupportedPath,
      any.list(any.idSegment),
      kExploreConfig,
    ).test(
      'Property 5: Los parámetros de consulta se ignoran',
      (host, path, tokens) {
        // Se derivan del mismo arreglo: pares clave/valor para la consulta y,
        // si sobra un elemento, un fragmento opcional.
        final query = <String, String>{
          for (var i = 0; i + 1 < tokens.length; i += 2)
            'k$i${tokens[i]}': tokens[i + 1],
        };
        final fragment = tokens.length.isOdd ? tokens.last : null;

        final plain = Uri(scheme: 'https', host: host, path: path);
        final decorated = Uri(
          scheme: 'https',
          host: host,
          path: path,
          queryParameters: query.isEmpty ? null : query,
          fragment: fragment,
        );

        expect(
          LinkMapper.resolve(decorated, domain: kDomain),
          LinkMapper.resolve(plain, domain: kDomain),
        );
      },
    );
  });
}
