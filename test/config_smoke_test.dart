import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_links/core/app_config.dart';

String _read(String path) => File(path).readAsStringSync();

Object? _json(String path) => jsonDecode(_read(path));

void main() {
  group('AndroidManifest.xml (Req. 6.1, 6.2)', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');

    test('declara el intent-filter de App Links', () {
      expect(manifest, contains('android:autoVerify="true"'));
      expect(manifest, contains('android.intent.action.VIEW'));
      expect(manifest, contains('android.intent.category.DEFAULT'));
      expect(manifest, contains('android.intent.category.BROWSABLE'));
      expect(manifest, contains('android:scheme="https"'));
      expect(manifest, contains('android:host="${AppConfig.domain}"'));
    });

    test('restringe a los prefijos de path soportados', () {
      for (final prefix in [
        '/categorias',
        '/productos',
        '/carrito',
        '/ofertas',
      ]) {
        expect(manifest, contains('android:pathPrefix="$prefix"'));
      }
      expect(manifest, contains('android:path="/"'));
    });
  });

  group('Runner.entitlements (Req. 7.1, 7.2)', () {
    test('declara applinks con el dominio propio', () {
      expect(
        _read('ios/Runner/Runner.entitlements'),
        contains('applinks:${AppConfig.domain}'),
      );
    });

    test('el proyecto iOS referencia el archivo de entitlements', () {
      expect(
        _read('ios/Runner.xcodeproj/project.pbxproj'),
        contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements'),
      );
    });
  });

  group('assetlinks.json (Req. 6.3)', () {
    test('es JSON válido con package_name y marcador sha256', () {
      final raw = _read('web/.well-known/assetlinks.json');
      final data = _json('web/.well-known/assetlinks.json')! as List<dynamic>;
      expect(data, isNotEmpty);
      final target =
          (data.first as Map<String, dynamic>)['target'] as Map<String, dynamic>;
      expect(target['package_name'], 'com.example.inventory_app_links');
      expect(target['sha256_cert_fingerprints'], isNotEmpty);
      expect(raw, contains('REEMPLAZAR_SHA256_DEL_CERTIFICADO'));
    });
  });

  group('apple-app-site-association (Req. 7.3, 7.4)', () {
    test('existe sin extensión, es JSON válido con appIDs y paths', () {
      expect(
        File('web/.well-known/apple-app-site-association').existsSync(),
        isTrue,
      );
      final data = _json('web/.well-known/apple-app-site-association')!
          as Map<String, dynamic>;
      final details = ((data['applinks'] as Map<String, dynamic>)['details']
              as List<dynamic>)
          .first as Map<String, dynamic>;
      final appIds = details['appIDs'] as List<dynamic>;
      expect(appIds, isNotEmpty);
      expect(appIds.first as String, contains('TEAM_ID'));
      expect(appIds.first as String, contains('com.example.inventoryAppLinks'));

      final paths = (details['components'] as List<dynamic>)
          .map((c) => (c as Map<String, dynamic>)['/'])
          .toList();
      expect(
        paths,
        containsAll(<String>[
          '/',
          '/categorias/*',
          '/productos/*',
          '/carrito',
          '/ofertas',
        ]),
      );
    });
  });

  group('firebase.json (Req. 6.4, 7.3, 8.2, 8.5)', () {
    final config = _json('firebase.json')! as Map<String, dynamic>;
    final hosting = config['hosting'] as Map<String, dynamic>;

    test('publica build/web', () {
      expect(hosting['public'], 'build/web');
    });

    test('define Content-Type application/json para .well-known', () {
      final headers = hosting['headers'] as List<dynamic>;
      for (final source in [
        '/.well-known/assetlinks.json',
        '/.well-known/apple-app-site-association',
      ]) {
        final entry = headers
            .cast<Map<String, dynamic>>()
            .firstWhere((h) => h['source'] == source);
        final values = (entry['headers'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        expect(
          values.any(
            (h) =>
                (h['key'] as String).toLowerCase() == 'content-type' &&
                h['value'] == 'application/json',
          ),
          isTrue,
          reason: source,
        );
      }
    });

    test('reescribe ** a /index.html', () {
      final rewrites = (hosting['rewrites'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        rewrites.any(
          (r) => r['source'] == '**' && r['destination'] == '/index.html',
        ),
        isTrue,
      );
    });

    test('ignore no excluye .well-known', () {
      final ignore = (hosting['ignore'] as List<dynamic>? ?? <dynamic>[])
          .cast<String>();
      for (final pattern in ignore) {
        expect(pattern, isNot(contains('well-known')));
      }
      // Patrones de archivos ocultos genéricos excluirían .well-known.
      expect(ignore, isNot(contains('**/.*')));
      expect(ignore, isNot(contains('.*')));
    });
  });

  group('README.md (Req. 9.2 a 9.6)', () {
    final readme = _read('README.md');

    test('menciona los pasos y comandos requeridos', () {
      expect(readme, contains('flutterfire configure'));
      expect(readme, contains('flutter build web'));
      expect(readme, contains('firebase deploy --only hosting'));
      expect(readme, contains('adb shell am start'));
      expect(readme, contains('xcrun simctl openurl'));
    });

    test('indica que Dynamic Links está deprecado y se usa app_links', () {
      expect(readme.toLowerCase(), contains('deprecado'));
      expect(readme, contains('app_links'));
    });

    test('describe el reemplazo de marcadores', () {
      expect(readme, contains('SHA-256'));
      expect(readme, contains('Team ID'));
      expect(readme, contains('Bundle ID'));
    });
  });

  group('AppConfig (Req. 9.1)', () {
    test('el dominio es único y coincide con el de la guía', () {
      expect(AppConfig.domain, isNotEmpty);
      expect(_read('README.md'), contains(AppConfig.domain));
    });
  });
}
