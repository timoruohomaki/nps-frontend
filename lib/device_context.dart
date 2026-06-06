import 'dart:io' show Platform;

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Device-derived fields that get attached to every feedback submission.
/// Resolved once at app startup and reused for the session.
class DeviceContext {
  const DeviceContext({
    required this.platform,
    required this.appVersion,
    required this.timezone,
  });

  /// Value sent as the `platform` field — must match an entry in the API's
  /// ALLOWED_PLATFORMS allowlist (defaults: macOS, Windows; this app needs
  /// the deployment to add iOS and Android).
  final String platform;

  /// Semver string from pubspec.yaml.
  final String appVersion;

  /// IANA timezone identifier (e.g. "Europe/Helsinki"), or null if the device
  /// reported an unparseable value.
  final String? timezone;

  static Future<DeviceContext> resolve() async {
    final info = await PackageInfo.fromPlatform();
    String? tz;
    try {
      tz = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      tz = null;
    }
    return DeviceContext(
      platform: _platformName(),
      appVersion: info.version,
      timezone: tz,
    );
  }

  static String _platformName() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    // Linux / Fuchsia / unknown — let the API reject it explicitly so we
    // surface the misconfiguration rather than silently mislabel.
    return Platform.operatingSystem;
  }
}

/// ISO 8601 timestamp in UTC, second precision, matching the schema regex
/// `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})?$`.
/// `DateTime.toIso8601String()` adds fractional seconds, so we format by hand.
String iso8601UtcNow() {
  final dt = DateTime.now().toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}-${two(dt.day)}'
      'T${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}Z';
}
