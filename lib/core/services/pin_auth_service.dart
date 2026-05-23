import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// Result of a PIN or recovery-code verification attempt.
enum PinVerifyResult {
  /// PIN matched.
  success,

  /// PIN did not match.
  invalid,

  /// Temporarily locked out after too many failed attempts.
  lockedOut,
}

/// Lockout state returned by [PinAuthService.getLockoutStatus].
class LockoutStatus {
  final bool isLocked;

  /// Remaining lock duration in seconds (0 when not locked).
  final int remainingSeconds;

  const LockoutStatus({required this.isLocked, required this.remainingSeconds});
}

/// Single-user PIN authentication service.
///
/// Stores only salted SHA-256 hashes in [FlutterSecureStorage] (never
/// plaintext).  Lockout state is kept in [SharedPreferences] because it
/// does not need to survive a secure-storage clear.
class PinAuthService {
  PinAuthService({
    FlutterSecureStorage? secureStorage,
  }) : _secure = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;

  // ── secure-storage keys ──────────────────────────────────────────────────
  static const _kPinHash = 'pin_auth_pin_hash';
  static const _kPinSalt = 'pin_auth_pin_salt';
  static const _kRecoveryHash = 'pin_auth_recovery_hash';
  static const _kRecoverySalt = 'pin_auth_recovery_salt';

  // ── shared-preferences keys ──────────────────────────────────────────────
  static const _kAttempts = 'pin_auth_attempts';
  static const _kLockUntil = 'pin_auth_lock_until';

  // ── policy constants ─────────────────────────────────────────────────────
  static const int maxAttempts = 5;
  static const int lockSeconds = 60;

  // ── public API ───────────────────────────────────────────────────────────

  /// Returns `true` when a PIN has been set.
  Future<bool> hasPin() async {
    try {
      final hash = await _secure.read(key: _kPinHash);
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      AppLogger.error('hasPin error: $e', tag: 'PinAuthService');
      return false;
    }
  }

  /// Sets up a new PIN and returns the one-time recovery code.
  ///
  /// Call [generateRecoveryCode] first if you want to show it before
  /// committing, or use the returned value directly.
  Future<String> setupPin(String pin) async {
    final recoveryCode = generateRecoveryCode();
    await _storePinAndRecovery(pin, recoveryCode);
    await _resetAttempts();
    AppLogger.info('PIN set up successfully', tag: 'PinAuthService');
    return recoveryCode;
  }

  /// Verifies [pin] and returns the result, honouring lockout policy.
  Future<PinVerifyResult> verifyPin(String pin) async {
    final lockout = await getLockoutStatus();
    if (lockout.isLocked) return PinVerifyResult.lockedOut;

    try {
      final storedHash = await _secure.read(key: _kPinHash);
      final storedSalt = await _secure.read(key: _kPinSalt);
      if (storedHash == null || storedSalt == null) {
        return PinVerifyResult.invalid;
      }
      final match = _hash(pin, storedSalt) == storedHash;
      if (match) {
        await _resetAttempts();
        return PinVerifyResult.success;
      }
      await _recordFailedAttempt();
      return PinVerifyResult.invalid;
    } catch (e) {
      AppLogger.error('verifyPin error: $e', tag: 'PinAuthService');
      return PinVerifyResult.invalid;
    }
  }

  /// Verifies [code] against the stored recovery code.
  ///
  /// On success the caller must call [resetPinWithNewPin] to complete
  /// the recovery flow.
  Future<bool> verifyRecoveryCode(String code) async {
    try {
      final storedHash = await _secure.read(key: _kRecoveryHash);
      final storedSalt = await _secure.read(key: _kRecoverySalt);
      if (storedHash == null || storedSalt == null) return false;
      return _hash(code.trim(), storedSalt) == storedHash;
    } catch (e) {
      AppLogger.error('verifyRecoveryCode error: $e', tag: 'PinAuthService');
      return false;
    }
  }

  /// Replaces the current PIN with [newPin], generating a fresh recovery code.
  ///
  /// Returns the new one-time recovery code.
  Future<String> resetPinWithNewPin(String newPin) async {
    final recoveryCode = generateRecoveryCode();
    await _storePinAndRecovery(newPin, recoveryCode);
    await _resetAttempts();
    AppLogger.info('PIN reset successfully', tag: 'PinAuthService');
    return recoveryCode;
  }

  /// Changes the PIN after verifying the current one.
  ///
  /// Returns `null` when [currentPin] is wrong or the app is locked out.
  /// Returns the new recovery code on success.
  Future<String?> changePin(String currentPin, String newPin) async {
    final result = await verifyPin(currentPin);
    if (result != PinVerifyResult.success) return null;
    return resetPinWithNewPin(newPin);
  }

  /// Returns current lockout status.
  Future<LockoutStatus> getLockoutStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilMs = prefs.getInt(_kLockUntil) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lockUntilMs > now) {
      final remaining = ((lockUntilMs - now) / 1000).ceil();
      return LockoutStatus(isLocked: true, remainingSeconds: remaining);
    }
    return const LockoutStatus(isLocked: false, remainingSeconds: 0);
  }

  /// Returns a cryptographically random 12-character alphanumeric code.
  String generateRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final segments = List.generate(3, (_) {
      return List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
    });
    return segments.join('-');
  }

  // ── private helpers ──────────────────────────────────────────────────────

  Future<void> _storePinAndRecovery(String pin, String recoveryCode) async {
    final pinSalt = _randomSalt();
    final recoverySalt = _randomSalt();
    await _secure.write(key: _kPinSalt, value: pinSalt);
    await _secure.write(key: _kPinHash, value: _hash(pin, pinSalt));
    await _secure.write(key: _kRecoverySalt, value: recoverySalt);
    await _secure.write(
        key: _kRecoveryHash, value: _hash(recoveryCode.trim(), recoverySalt));
  }

  Future<void> _recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_kAttempts) ?? 0) + 1;
    await prefs.setInt(_kAttempts, attempts);
    if (attempts >= maxAttempts) {
      final lockUntil = DateTime.now()
          .add(const Duration(seconds: lockSeconds))
          .millisecondsSinceEpoch;
      await prefs.setInt(_kLockUntil, lockUntil);
      AppLogger.info('PIN locked out for $lockSeconds seconds',
          tag: 'PinAuthService');
    }
  }

  Future<void> _resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAttempts);
    await prefs.remove(_kLockUntil);
  }

  String _randomSalt() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hash(String value, String salt) {
    final bytes = utf8.encode('$salt:$value');
    return sha256.convert(bytes).toString();
  }
}
