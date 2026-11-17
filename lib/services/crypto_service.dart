import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class CryptoService {
  static const int saltLength = 16;
  static const int iterations = 100000;
  static const int keyLength = 32;

  final Random _random = Random.secure();

  String generateSalt() {
    final bytes = List<int>.generate(saltLength, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String hash(String input, String salt) {
    final passwordBytes = utf8.encode(input);
    final saltBytes = base64Url.decode(salt);
    final hmac = Hmac(sha256, passwordBytes);

    var u = _hmacDigest(hmac, saltBytes + _intToBytes(1));
    var t = List<int>.from(u);

    for (var iter = 1; iter < iterations; iter++) {
      u = _hmacDigest(hmac, u);
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }

    return base64Url.encode(t);
  }

  bool verify(String input, String salt, String expectedHash) {
    if (salt.isEmpty || expectedHash.isEmpty) return false;
    final actualHash = hash(input, salt);
    return _constantTimeEquals(actualHash, expectedHash);
  }

  String hashPassword(String password, String salt) => hash(password, salt);
  bool verifyPassword(String password, String salt, String hash) => verify(password, salt, hash);

  String hashPin(String pin, String salt) => hash(pin, salt);
  bool verifyPin(String pin, String salt, String hash) => verify(pin, salt, hash);

  String hashPattern(String pattern, String salt) => hash(pattern, salt);
  bool verifyPattern(String pattern, String salt, String hash) => verify(pattern, salt, hash);

  String hashAnswer(String answer, String salt) {
    final normalized = answer.trim().toLowerCase();
    return hash(normalized, salt);
  }
  bool verifyAnswer(String answer, String salt, String hash) => verify(answer.trim().toLowerCase(), salt, hash);

  Future<String> hashAsync(String input, String salt) async {
    return await compute(_hashIsolate, {'input': input, 'salt': salt});
  }

  static String _hashIsolate(Map<String, String> params) {
    return CryptoService().hash(params['input']!, params['salt']!);
  }

  Future<bool> verifyAsync(String input, String salt, String expectedHash) async {
    return await compute(_verifyIsolate, {'input': input, 'salt': salt, 'expectedHash': expectedHash});
  }

  static bool _verifyIsolate(Map<String, dynamic> params) {
    return CryptoService().verify(params['input']!, params['salt']!, params['expectedHash']!);
  }

  List<int> _hmacDigest(Hmac hmac, List<int> data) {
    final digest = hmac.convert(data);
    return List<int>.from(digest.bytes);
  }

  List<int> _intToBytes(int value) {
    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
