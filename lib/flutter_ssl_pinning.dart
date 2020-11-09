import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Algorithm { sha1, sha256 }

final FlutterSslPinning flutterSslPinning = FlutterSslPinning._();

class FlutterSslPinning {
  static const MethodChannel _channel =
      const MethodChannel('flutter_ssl_pinning');

  FlutterSslPinning._() {
    _channel.setMethodCallHandler(_platformCallHandler);
  }

  Future<bool> validating({
    @required String serverURL,
    Map<String, String> headerHttp = const {},
    Algorithm algorithm = Algorithm.sha256,
    @required List<String> allowedSHAFingerprints,
    int timeout = 60,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      "url": serverURL,
      "headers": headerHttp,
      "type": algorithm.toString().split(".").last,
      "fingerprints":
          allowedSHAFingerprints.map((a) => a.replaceAll(":", "")).toList(),
      "timeout": timeout,
    };

    try {
      final valid = await _channel.invokeMethod('validating', params);
      if (valid == 1) {
        return true;
      }
    } on PlatformException catch (e) {
      print(e);
      throw FlutterSslPinningException(e.code, e.message);
    }

    throw FlutterSslPinningException();
  }

  Future _platformCallHandler(MethodCall call) async {
    print("_platformCallHandler call ${call.method} ${call.arguments}");
  }
}

class FlutterSslPinningException implements Exception {
  @pragma("vm:entry-point")
  const FlutterSslPinningException([this.code, String message])
      : this.message = message ?? code == 'INVALID_ARGUMENTS'
            ? 'Invalid arguments request'
            : code == 'INVALID_PARAMS'
                ? 'Invalid parameter request'
                : code == 'INVALID_URL'
                    ? 'Invalid url request'
                    : code == 'INVALID_CERTIFICATE'
                        ? 'Invalid certificate fingerprint'
                        : "SHA Fingerprint doesn't match";

  final String code;
  final String message;

  String toString() => message;
}
