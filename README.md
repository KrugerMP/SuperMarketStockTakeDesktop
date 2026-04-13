# SuperMarketStockTakeDesktop

Read-only desktop application for stock take and product tracking. It consumes live game data from **Supermarket Together** through the local HTTP API exposed by the companion mod project **SuperMarketStockTakeAPI** (GET JSON on `http://localhost:8080` by default).

## Repository layout

| Path | Purpose |
|------|---------|
| **`src/`** | Flutter app root (`pubspec.yaml`, `lib/`, desktop platform folders). |
| **`plan/`** | Project planning notes (markdown). |

## Flutter app (`src/`)

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) with **Linux** and/or **Windows** desktop support (`flutter doctor`).

### Run (development)

```bash
cd src
flutter pub get
flutter run -d linux
```

### Build (release)

```bash
cd src
flutter build linux
flutter build windows
```

(`windows` builds are usually done on Windows or with your chosen cross-compile setup.)

### API this app uses

The mod serves **GET-only** JSON on localhost (default port **8080**). Typical routes: `/ping`, `/stats`, `/products`, `/spawnedProducts`. Run the game with the plugin loaded so the desktop app can reach the server.

## New to Flutter?

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Learning resources](https://docs.flutter.dev/reference/learning-resources)
- [Documentation hub](https://docs.flutter.dev/)
