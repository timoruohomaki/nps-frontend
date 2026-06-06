# nps-frontend

A Flutter mobile app (iOS + Android) that collects NPS feedback and submits it to the [nps-api](https://github.com/timoruohomaki/nps-api) backend.

- **Phase 1** (current): 10-point rating + optional comment, posted with an `X-API-Key` header.
- **Phase 2** (planned): tag each submission with a `public_service` reference resolved from the pygeoapi WFS layer using the device's location.

## Prerequisites

- Flutter SDK 3.22+ ([install](https://docs.flutter.dev/get-started/install))
- Xcode (for iOS) and/or Android Studio + JDK 17 (for Android)
- A running `nps-api` instance (local or `https://api.ruohomaki.fi/nps`)

## First-time setup

This repo only ships the Dart sources, `pubspec.yaml`, and lints. The platform-specific Android/iOS folders are generated locally — they're machine-generated boilerplate that doesn't belong in version control as scaffolding.

```bash
# Generate android/ and ios/ folders (non-destructive — won't touch lib/)
flutter create --platforms=android,ios --org fi.ruohomaki --project-name nps_frontend .

# Pull pub dependencies
flutter pub get
```

## Configuration

All runtime config is passed via `--dart-define`. Nothing is hardcoded; nothing lives in source.

| Var | Default | Description |
|---|---|---|
| `API_BASE_URL` | `https://api.ruohomaki.fi/nps` | Base URL of the nps-api deployment. No trailing slash. |
| `API_KEY` | _(empty)_ | Value sent in the `X-API-Key` header. Empty = header omitted. |
| `APP_ID` | `nps-frontend-demo` | Value sent as the `app` field. |

The `app_version` field is read from `pubspec.yaml` at runtime via `package_info_plus`; `platform` is derived from `dart:io` (`iOS` / `Android`); `timezone` is read from the device.

## Run

```bash
# iOS Simulator / device
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8081/nps \
  --dart-define=API_KEY=dev-key \
  --dart-define=APP_ID=nps-frontend-demo

# Android emulator — use 10.0.2.2 to reach the host loopback
flutter run -d emulator-5554 \
  --dart-define=API_BASE_URL=http://10.0.2.2:8081/nps \
  --dart-define=API_KEY=dev-key
```

## Build

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.ruohomaki.fi/nps \
  --dart-define=API_KEY=<prod-key>

flutter build ios --release \
  --dart-define=API_BASE_URL=https://api.ruohomaki.fi/nps \
  --dart-define=API_KEY=<prod-key>
```

## Backend requirements

For this frontend to submit successfully, the nps-api instance it talks to must have:

- `ALLOWED_PLATFORMS` containing `iOS` and `Android` (mobile devices).
- `API_KEYS` containing the value passed as `--dart-define=API_KEY=...` (or `API_KEYS` empty for open access).

## License

[Apache License 2.0](LICENSE)
