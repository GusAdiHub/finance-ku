import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/auth_token_model.dart';

void main() {
  group('AuthTokenModel Tests', () {
    test('fromJson parses token response correctly', () {
      final json = {
        'access_token': 'jwt-sample-token-xyz',
        'token_type': 'bearer',
        'expires_in': 86400,
        'user': {
          'id': 'user-123',
          'name': 'Budi Santoso',
          'email': 'budi@example.com',
          'is_active': true,
          'created_at': '2026-11-06T12:00:00Z',
          'updated_at': '2026-11-06T12:00:00Z',
        },
      };

      final model = AuthTokenModel.fromJson(json);

      expect(model.accessToken, 'jwt-sample-token-xyz');
      expect(model.tokenType, 'bearer');
      expect(model.expiresIn, 86400);
      expect(model.user.name, 'Budi Santoso');
    });

    test('toJson serializes token model properly', () {
      final json = {
        'access_token': 'jwt-sample-token-xyz',
        'token_type': 'bearer',
        'expires_in': 86400,
        'user': {
          'id': 'user-123',
          'name': 'Budi Santoso',
          'email': 'budi@example.com',
          'is_active': true,
          'created_at': '2026-11-06T12:00:00.000Z',
          'updated_at': '2026-11-06T12:00:00.000Z',
        },
      };

      final model = AuthTokenModel.fromJson(json);
      final serialized = model.toJson();

      expect(serialized['access_token'], 'jwt-sample-token-xyz');
      expect(serialized['expires_in'], 86400);
    });
  });
}
