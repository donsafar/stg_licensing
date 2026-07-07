# 7-Day Single-Device Trial Architecture

**Cross-platform:** Windows, Android, iOS, macOS  
**Audience:** STG Flutter portfolio apps  
**Companion code:** `stg_baseapp/tool/trial_version_implement/trial_manager.dart`

This document is a comprehensive architectural breakdown and production-ready source code guide for configuring a **7-day, single-device trial** for cross-platform Flutter applications.

---

## Summary of Key Architectural Decisions

1. **Anti-clock tampering engine** — Instead of trusting local device time (which users can roll back in system settings), the architecture uses a Network Time Protocol (NTP) check via the `ntp` package to verify global time on launch. When offline, it falls back to a progressive local-time routine that tracks the furthest-seen timestamp to prevent rewinding.

2. **Platform-stable fingerprinting** — Persistent hardware identifiers via `device_info_plus`:
   - **Windows:** Immutable registry `MachineGuid` (via `windowsInfo.deviceId`)
   - **Android:** `ANDROID_ID` (`androidInfo.id`)
   - **Apple ecosystem:** `identifierForVendor` combined with persistent **App Keychain** storage (`flutter_secure_storage`) so install timestamps survive app deletion on the secure enclave

3. **App Store native alignment** — Strategies for **Microsoft Store**, **Google Play**, and **Apple App Store**, including `--obfuscate` build patterns to protect validation logic from reverse engineering.

---

## 1. Architectural Strategy & Trust Models

Implementing a trial requires balancing **user convenience** against **tamper resistance**. A client-only app can always be reverse-engineered or have local storage cleared, so a robust design combines local security with lightweight server verification where possible.

### A. Pure Local (Device-Only) Model

- **How it works:** The app writes the initial installation timestamp to secure local storage or hardware-backed keystore/keychain on first launch.
- **Pros:** No server infrastructure; works offline.
- **Cons:** Vulnerable to clock tampering and local data deletion / re-imaging.

### B. Hybrid Cloud-Assisted Model (Recommended for Production)

- **How it works:** On first launch, the app generates a **device fingerprint** and registers it with a secure network timestamp on a backend (Firebase, Supabase, or custom REST API). Subsequent launches validate against server-stored install date.
- **Pros:** Resistant to local wipe and clock manipulation.
- **Cons:** Requires internet for initial activation and periodic checks.

---

## 2. Platform-Specific Device Fingerprinting

To enforce **one device, one trial**, generate a stable hardware identifier that persists across uninstalls.

| Platform | Native identifier | Persistence |
|----------|-------------------|-------------|
| **Windows** | `MachineGuid` (Registry) / SMBIOS UUID | Survives app uninstall; changes on full OS reinstall |
| **Android** | `ANDROID_ID` | Resets on factory reset or signing-key change |
| **iOS / macOS** | `identifierForVendor` + **App Keychain** | IDFV persists while any app from same vendor is installed; Keychain survives uninstall for licensing tokens |

---

## 3. Step-by-Step Implementation

### Step 1: Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  device_info_plus: ^10.1.0
  flutter_secure_storage: ^9.0.0
  ntp: ^3.0.0
  shared_preferences: ^2.2.0
```

### Step 2: Secure Trial Engine (`trial_manager.dart`)

Create a core `TrialManager` class for initialization, fingerprinting, secure state, and lockdown logic.

```dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntp/ntp.dart';

class TrialManager {
  static const String _installDateKey = 'stg_trial_start_date';
  static const String _deviceIdKey = 'stg_trial_device_id';
  static const int trialDurationDays = 7;

  final _secureStorage = const FlutterSecureStorage();

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  IOSOptions _getIOSOptions() => const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      );

  /// Returns true if trial is valid, false if expired or locked.
  Future<bool> checkTrialStatus() async {
    try {
      final deviceId = await _getDeviceFingerprint();
      final currentNetworkTime = await _getSafeCurrentTime();

      String? storedDateStr = await _secureStorage.read(
        key: _installDateKey,
        aOptions: _getAndroidOptions(),
        iOptions: _getIOSOptions(),
      );

      late final DateTime installDate;

      if (storedDateStr == null) {
        installDate = currentNetworkTime;
        await _secureStorage.write(
          key: _installDateKey,
          value: installDate.toIso8601String(),
          aOptions: _getAndroidOptions(),
          iOptions: _getIOSOptions(),
        );
        await _secureStorage.write(
          key: _deviceIdKey,
          value: deviceId,
          aOptions: _getAndroidOptions(),
          iOptions: _getIOSOptions(),
        );
      } else {
        installDate = DateTime.parse(storedDateStr);
      }

      final difference = currentNetworkTime.difference(installDate).inDays;

      if (currentNetworkTime.isBefore(installDate)) {
        return false;
      }

      return difference < trialDurationDays;
    } catch (e) {
      return await _fallbackLocalValidation();
    }
  }

  Future<int> getRemainingDays() async {
    try {
      final storedDateStr = await _secureStorage.read(
        key: _installDateKey,
        aOptions: _getAndroidOptions(),
        iOptions: _getIOSOptions(),
      );
      if (storedDateStr == null) return trialDurationDays;

      final installDate = DateTime.parse(storedDateStr);
      final now = await _getSafeCurrentTime();
      final remaining = trialDurationDays - now.difference(installDate).inDays;
      return remaining < 0 ? 0 : remaining;
    } catch (_) {
      return 0;
    }
  }

  Future<String> _getDeviceFingerprint() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.deviceId;
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_id';
    } else if (Platform.isMacOS) {
      final macosInfo = await deviceInfo.macOsInfo;
      return macosInfo.systemGUID ?? 'unknown_macos_id';
    }
    throw UnsupportedError('Platform not supported by TrialManager.');
  }

  Future<DateTime> _getSafeCurrentTime() async {
    try {
      return await NTP.now().timeout(const Duration(seconds: 4));
    } catch (_) {
      return await _getValidatedLocalTime();
    }
  }

  Future<DateTime> _getValidatedLocalTime() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceNow = DateTime.now();

    final lastSeenStr = prefs.getString('stg_last_seen_time');
    if (lastSeenStr != null) {
      final lastSeen = DateTime.parse(lastSeenStr);
      if (deviceNow.isBefore(lastSeen)) {
        return lastSeen.add(const Duration(hours: 1));
      }
    }

    await prefs.setString('stg_last_seen_time', deviceNow.toIso8601String());
    return deviceNow;
  }

  Future<bool> _fallbackLocalValidation() async {
    final storedDateStr = await _secureStorage.read(
      key: _installDateKey,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );

    if (storedDateStr == null) return true;

    final installDate = DateTime.parse(storedDateStr);
    final validatedNow = await _getValidatedLocalTime();
    return validatedNow.difference(installDate).inDays < trialDurationDays;
  }
}
```

### Step 3: Wire into Application Root

```dart
import 'package:flutter/material.dart';
import 'trial_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final trialManager = TrialManager();
  final isTrialValid = await trialManager.checkTrialStatus();
  final daysRemaining = await trialManager.getRemainingDays();

  runApp(MyApp(
    isTrialValid: isTrialValid,
    daysRemaining: daysRemaining,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.isTrialValid,
    required this.daysRemaining,
  });

  final bool isTrialValid;
  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enterprise Solution',
      home: isTrialValid
          ? DashboardScreen(daysLeft: daysRemaining)
          : const TrialExpiredLockdownScreen(),
    );
  }
}
```

### Step 4: UI Enforcement Patterns

Show remaining trial time in-app; block usage when expired.

```dart
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.daysLeft});

  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Dashboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            color: Colors.amber.shade700,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Evaluation: $daysLeft days remaining in your trial.',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: const Center(child: Text('Application content')),
    );
  }
}

class TrialExpiredLockdownScreen extends StatelessWidget {
  const TrialExpiredLockdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Evaluation Period Expired',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your 7-day single-device evaluation has ended. '
                    'Purchase a license to continue.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      // Store API or external checkout URL
                    },
                    child: const Text('Purchase Full License'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 4. App Store Native Integration

Align trial enforcement with each marketplace’s built-in licensing where possible.

### A. Microsoft Store (Windows)

- **Store-managed trials:** Partner Center supports time-bound trials without custom code.
- **API verification:** Use `StoreContext` (via `win32` or platform channels) to verify package license state against the signed-in Microsoft account.

### B. Google Play (Android)

- **In-app purchases:** Configure a subscription with a **7-day free trial** in Play Console.
- **Implementation:** Use `in_app_purchase`; Google handles conversion or lockout after trial ends.

### C. Apple App Store (iOS & macOS)

- **Compliance:** `identifierForVendor` and Keychain-backed install tokens for **licensing** are acceptable; avoid fingerprinting for marketing/tracking.
- **Subscriptions:** Use StoreKit 2 / `in_app_purchase` with a 7-day introductory free trial.

---

## 5. Distribution Security Checklist

- [ ] **Obfuscate production builds** to harden against reverse engineering:

```bash
flutter build windows --release --obfuscate --split-debug-info=build/symbols
flutter build apk --release --obfuscate --split-debug-info=build/symbols
flutter build ios --release --obfuscate --split-debug-info=build/symbols
flutter build macos --release --obfuscate --split-debug-info=build/symbols
```

- [ ] **Clock anomalies:** Use NTP on launch and track `stg_last_seen_time` in SharedPreferences when offline.
- [ ] **Server backup (recommended):** Register install timestamp + device fingerprint on your backend for mission-critical licensing.
- [ ] **Do not store license keys in plaintext** in the binary; verify hashed or signed tokens server-side or via obfuscated digests.

---

## 6. Relationship to Current STG Codebase

| Component | Location | Status |
|-----------|----------|--------|
| Reference `TrialManager` | `stg_baseapp/tool/trial_version_implement/trial_manager.dart` | Reference implementation |
| Shared licensing package | `packages/licensing` (`stg_licensing`) | Trial UI, pricing, license keys (desktop QA) |
| Gap analysis | `stg_health/docs/stg_health_trial_implementation_gap_analysis.md` | NTP / fingerprinting not yet in production apps |
| Store strategy | `stg_baseapp/docs/2026-06-04_STG_app_store_trial_and_licensing.md` | Store + server entitlement model |

**Next step for production:** Port NTP + secure-storage + fingerprinting from `TrialManager` into `packages/licensing`, then consume from each portfolio app via `stgLicensingProvider`.

---

*Regenerated from `CompleteTrialImplementPlan.txt` and `trial_manager.dart` — STG portfolio licensing documentation.*
