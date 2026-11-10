# inventory_app_links

MVP de comercio electrónico en Flutter (Android, iOS y Web) con catálogo y carrito en memoria, sin backend ni inicio de sesión. La navegación usa `go_router` y los enlaces entrantes se reciben con `app_links`. Los enlaces HTTPS apuntan a un dominio propio servido por Firebase Hosting.

## Aviso: Firebase Dynamic Links está deprecado

Firebase Dynamic Links fue deprecado por Google y dejó de estar disponible, por lo que **este proyecto no lo utiliza**. La solución usa:

- **`app_links`** para recibir los enlaces entrantes en la app.
- **Android App Links** e **iOS Universal Links** sobre un **dominio propio** servido por **Firebase Hosting**.
- **Versión Web** de la app como página de respaldo cuando la app no está instalada.

`firebase_core` se inicializa al arrancar la app. Si la inicialización falla, el error se registra y la app sigue funcionando.

## Rutas soportadas

| Ruta | Pantalla |
|---|---|
| `/` | Inicio |
| `/categorias` | Lista de categorías |
| `/categorias/:categoriaId` | Productos de una categoría |
| `/productos/:productoId` | Detalle de producto |
| `/carrito` | Carrito |
| `/ofertas` | Productos en oferta |

Cualquier otra ruta, o un id inexistente, muestra la pantalla "No encontrado". La barra final (`/productos/p1/`) se trata igual que sin ella, y los parámetros de consulta se ignoran. Los enlaces con un host distinto del dominio propio se descartan.

IDs de ejemplo: categorías `electronica`, `hogar`, `moda`, `deportes`; productos `p1` a `p12`.

## Pasos manuales

Estos pasos no se pueden automatizar desde el repositorio: requieren tu cuenta de Firebase, tu dominio real y tus certificados.

### 1. Crear el proyecto Firebase y ejecutar `flutterfire configure`

1. Crea un proyecto en la [consola de Firebase](https://console.firebase.google.com/).
2. Instala las herramientas:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   ```
3. Desde la raíz del proyecto:
   ```bash
   flutterfire configure
   ```
   Selecciona el proyecto y las plataformas Android, iOS y Web. Esto genera `lib/firebase_options.dart` y deja los archivos de configuración nativos.
4. (Opcional) Para usar las opciones generadas, importa `firebase_options.dart` en `lib/main.dart` y pasa `DefaultFirebaseOptions.currentPlatform` a `Firebase.initializeApp`:
   ```dart
   import 'firebase_options.dart';

   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```
   La app funciona sin este paso: `initFirebaseSafely` captura el error de inicialización, lo registra y continúa con la navegación operativa.
5. Asocia el sitio de Hosting a tu proyecto con `firebase init hosting` o `firebase use <id-del-proyecto>`. El `firebase.json` del repositorio ya está configurado (`public: build/web`).

### 2. Reemplazar SHA-256, Team ID, Bundle ID y dominio

Los valores actuales son marcadores de posición. Reemplázalos en estos archivos:

| Valor | Marcador actual | Archivo |
|---|---|---|
| Dominio | `tienda.example.com` | `lib/core/app_config.dart` (`AppConfig.domain`) |
| Dominio | `tienda.example.com` (en cada `<data android:host=...>`) | `android/app/src/main/AndroidManifest.xml` |
| Dominio | `applinks:tienda.example.com` | `ios/Runner/Runner.entitlements` |
| Huella SHA-256 | `REEMPLAZAR_SHA256_DEL_CERTIFICADO` | `web/.well-known/assetlinks.json` |
| Team ID | `TEAM_ID` | `web/.well-known/apple-app-site-association` |
| Bundle ID | `com.example.inventoryAppLinks` | `web/.well-known/apple-app-site-association` (y proyecto iOS) |
| Package name | `com.example.inventory_app_links` | `web/.well-known/assetlinks.json` (y `android/app/build.gradle.kts`) |

Identificadores actuales del proyecto:

- `applicationId` de Android: `com.example.inventory_app_links`
- Bundle ID de iOS: `com.example.inventoryAppLinks`

Si cambias el `applicationId` o el Bundle ID, actualiza también `android/app/build.gradle.kts` y `ios/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`), además de los archivos `.well-known`.

El dominio de `AppConfig.domain` **debe coincidir** con el del `AndroidManifest.xml` y con el de `Runner.entitlements`.

**Obtener la huella SHA-256 (Android):**

```bash
# Certificado de debug
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore \
  -storepass android -keypass android | grep SHA256

# Certificado de release (tu keystore)
keytool -list -v -alias <alias> -keystore <ruta-al-keystore> | grep SHA256
```

Si publicas con Play App Signing, usa la huella de la clave de firma de la app que aparece en Play Console (Integridad de la app). `sha256_cert_fingerprints` admite varias huellas (por ejemplo, debug y release).

**Obtener el Team ID (iOS):** en [developer.apple.com](https://developer.apple.com/account) → Membership details, o en Xcode → Signing & Capabilities. El `appIDs` queda con el formato `ABCDE12345.com.example.inventoryAppLinks`.

En Xcode, verifica que el target Runner tenga la capability **Associated Domains** y use `Runner/Runner.entitlements`.

### 3. Compilar y desplegar en Firebase Hosting

```bash
flutter build web
firebase deploy --only hosting
```

Antes de desplegar, verifica que los archivos `.well-known` quedaron dentro de `build/web`:

```bash
ls -la build/web/.well-known
# Debe listar: assetlinks.json  apple-app-site-association
```

Si falta alguno, confirma que existen en `web/.well-known/` y vuelve a ejecutar `flutter build web`. Si el build no copia las carpetas que empiezan por punto, copia los archivos a mano antes de desplegar:

```bash
mkdir -p build/web/.well-known
cp web/.well-known/* build/web/.well-known/
```

Después del despliegue, comprueba que se sirven con `Content-Type: application/json`:

```bash
curl -i https://<dominio>/.well-known/assetlinks.json
curl -i https://<dominio>/.well-known/apple-app-site-association
```

La respuesta debe ser `200` y contener `content-type: application/json`, sin redirecciones y con el JSON (no el `index.html`). `firebase.json` define estos encabezados y reescribe el resto de rutas a `/index.html`.

Opcionalmente, valida Android con la [Digital Asset Links API](https://developers.google.com/digital-asset-links/tools/generator) o con:

```bash
adb shell pm get-app-links com.example.inventory_app_links
```

### 4. Probar los enlaces

Con la app instalada en un emulador o simulador, reemplaza `<dominio>` por tu dominio:

**Android:**

```bash
adb shell am start -a android.intent.action.VIEW -d "https://<dominio>/productos/p1"
```

**iOS (simulador):**

```bash
xcrun simctl openurl booted "https://<dominio>/productos/p1"
```

Otros ejemplos: `/ofertas`, `/carrito`, `/categorias/electronica`, `/productos/p1/` (barra final) y `/productos/inexistente` (debe mostrar "No encontrado").

Notas:

- En iOS, los Universal Links son más fiables en un dispositivo real; el dominio debe servir el archivo AASA por HTTPS sin redirecciones.
- En Android, la verificación de dominio puede tardar. Mientras tanto, el comando `adb` puede abrir un selector de aplicaciones.
- En Web no interviene `app_links`: el navegador entrega la URL (sin `#`) directamente al router.

## Arquitectura y estructura

Capas dentro de `lib/`:

- `core/`: configuración global (`app_config.dart` con el dominio propio).
- `domain/`: modelos (`Product`, `Category`, `CartLine`), contrato `CatalogRepository`, `CartController` (`ChangeNotifier`) y `LinkMapper`, función pura que traduce un `Uri` a una ubicación del router o lo descarta.
- `data/`: `InMemoryCatalogRepository` (catálogo de ejemplo) y `AppLinksSource` (envoltura de `app_links`, sustituible en pruebas).
- `presentation/`: `LinkHandler` (entrega al router el enlace inicial y el flujo de enlaces; cancela la suscripción al liberarse), router con `go_router`, pantallas y widgets.

Flujo de un enlace: `app_links` → `LinkHandler` → `LinkMapper.resolve` → `GoRouter.go(ubicación)`. Los precios se guardan en centavos (`int`) para evitar errores de coma flotante.

Otros archivos relevantes:

```
android/app/src/main/AndroidManifest.xml   # intent-filter de App Links
ios/Runner/Runner.entitlements             # associated-domains
web/.well-known/                           # assetlinks.json y apple-app-site-association
firebase.json                              # Hosting: headers y reescrituras
test/                                      # pruebas unitarias y de widget
```

## Pruebas

```bash
flutter pub get
flutter analyze
flutter test
```

Las pruebas cubren el mapeo y descarte de enlaces, el catálogo, el carrito y la pantalla "No encontrado". La verificación real de App Links/Universal Links, el despliegue y el dominio real son pasos manuales descritos arriba.
# inventory-app-links
# inventory-app-links
