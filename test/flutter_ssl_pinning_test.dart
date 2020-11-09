import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ssl_pinning/flutter_ssl_pinning.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_ssl_pinning');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return 1;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('validating', () async {
    expect(await flutterSslPinning.validating(), true);
  });
}
