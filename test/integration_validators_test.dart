import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_calendar/data/integration/integration_validators.dart';

void main() {
  group('IntegrationValidators', () {
    test('validateImportFileName accepts ics and csv', () {
      expect(IntegrationValidators.validateImportFileName('a.ics'), isNull);
      expect(IntegrationValidators.validateImportFileName('a.csv'), isNull);
    });

    test('validateImportFileName rejects unknown extension', () {
      expect(
        IntegrationValidators.validateImportFileName('x.pdf'),
        isNotNull,
      );
    });

    test('validateExportFormat', () {
      expect(IntegrationValidators.validateExportFormat('ics'), isNull);
      expect(IntegrationValidators.validateExportFormat('ICS'), isNull);
      expect(IntegrationValidators.validateExportFormat('pdf'), isNotNull);
    });

    test('validateExportRfc3339Optional', () {
      expect(
        IntegrationValidators.validateExportRfc3339Optional(null, 'start_time'),
        isNull,
      );
      expect(
        IntegrationValidators.validateExportRfc3339Optional(
          '2024-01-15T10:00:00Z',
          'start_time',
        ),
        isNull,
      );
      expect(
        IntegrationValidators.validateExportRfc3339Optional(
          'not-a-date',
          'start_time',
        ),
        isNotNull,
      );
    });

    test('validateSyncRequest', () {
      expect(
        IntegrationValidators.validateSyncRequest(
          source: 'a',
          target: 'b',
        ),
        isNull,
      );
      expect(
        IntegrationValidators.validateSyncRequest(source: '', target: 'b'),
        isNotNull,
      );
    });

    test('validateGoogleSyncDirection', () {
      expect(
        IntegrationValidators.validateGoogleSyncDirection('bidirectional'),
        isNull,
      );
      expect(
        IntegrationValidators.validateGoogleSyncDirection('invalid'),
        isNotNull,
      );
    });
  });
}
