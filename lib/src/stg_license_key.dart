import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:stg_licensing/src/stg_portfolio_app_id.dart';

/// Result of validating a license key.
class StgLicenseKeyActivation {
  const StgLicenseKeyActivation({required this.tier});

  final StgPlanTier tier;
}

const _digestMask = <int>[
  0xA7, 0x3C, 0x91, 0x5E, 0x2B, 0xF4, 0x68, 0xD1, 0x0E, 0x83, 0x47, 0xBA,
  0x29, 0x6C, 0x95, 0xFE, 0x13, 0x56, 0xC9, 0x8A, 0x3D, 0x70, 0xE5, 0x18,
  0xAB, 0x4E, 0x81, 0xF6, 0x39, 0x6A, 0xBD, 0x20,
];

const _premiumKeyDigestObfuscated = <int>[
  0xF6, 0x39, 0x46, 0xCD, 0x10, 0x12, 0xBA, 0x1D, 0x9D, 0x36, 0xBC, 0x5C,
  0x07, 0x98, 0x64, 0x02, 0x5C, 0x5B, 0x61, 0x78, 0x96, 0x80, 0x8B, 0x83,
  0x84, 0xC8, 0x55, 0x25, 0x7C, 0xBC, 0x3E, 0xEB,
];

Uint8List _decodeDigest(List<int> obfuscated) {
  final out = Uint8List(_digestMask.length);
  for (var i = 0; i < _digestMask.length; i++) {
    out[i] = obfuscated[i] ^ _digestMask[i];
  }
  return out;
}

final Uint8List _expectedPremiumKeyDigest = _decodeDigest(_premiumKeyDigestObfuscated);

bool _constantTimeBytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

bool _matchesDigest(String candidate, Uint8List expected) {
  final normalized = candidate.trim();
  if (normalized.isEmpty) return false;
  final digest = sha256.convert(utf8.encode(normalized)).bytes;
  return _constantTimeBytesEqual(Uint8List.fromList(digest), expected);
}

/// Maps a license key to a subscription tier. Plaintext keys are never stored.
StgLicenseKeyActivation? resolveLicenseKeyActivation(String candidate) {
  if (_matchesDigest(candidate, _expectedPremiumKeyDigest)) {
    return const StgLicenseKeyActivation(tier: StgPlanTier.premium);
  }
  return null;
}
