import 'package:flutter_test/flutter_test.dart';
import 'package:fitmonster/core/config/openrouter_user_key.dart';

void main() {
  group('OpenRouter config', () {
    test('kOpenRouterUserApiKey is a string (вставь ключ в lib/core/config/openrouter_user_key.dart)', () {
      expect(kOpenRouterUserApiKey, isA<String>());
    });
  });
}
