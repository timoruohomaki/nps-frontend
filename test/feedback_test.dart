import 'package:flutter_test/flutter_test.dart';
import 'package:nps_frontend/models/feedback.dart';

void main() {
  group('Feedback', () {
    Feedback build(int rating) => Feedback(
          app: 'nps-frontend-demo',
          appVersion: '0.1.0',
          platform: 'iOS',
          timestamp: '2026-06-06T12:00:00Z',
          npsRating: rating,
          timezone: 'Europe/Helsinki',
        );

    test('derives detractor for 1..6', () {
      for (final r in [1, 2, 3, 4, 5, 6]) {
        expect(build(r).npsCategory, 'detractor', reason: 'rating $r');
      }
    });

    test('derives passive for 7..8', () {
      expect(build(7).npsCategory, 'passive');
      expect(build(8).npsCategory, 'passive');
    });

    test('derives promoter for 9..10', () {
      expect(build(9).npsCategory, 'promoter');
      expect(build(10).npsCategory, 'promoter');
    });

    test('toJson omits optional empty fields', () {
      final fb = Feedback(
        app: 'demo',
        appVersion: '0.1.0',
        platform: 'iOS',
        timestamp: '2026-06-06T12:00:00Z',
        npsRating: 9,
      );
      final json = fb.toJson();
      expect(json.containsKey('timezone'), isFalse);
      expect(json.containsKey('comment'), isFalse);
      expect(json['schema_version'], '1.0');
      expect(json['nps_category'], 'promoter');
    });

    test('rejects out-of-range ratings', () {
      expect(() => build(0), throwsA(isA<AssertionError>()));
      expect(() => build(11), throwsA(isA<AssertionError>()));
    });
  });
}
