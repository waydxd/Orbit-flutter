import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'integration_validators.dart';

/// Ensures the file path used for multipart upload matches what the backend expects:
/// `.csv` unchanged; `.ical` / `.ifb` / `.icalendar` copied to a temp `.ics` file.
Future<String> prepareCalendarImportUploadPath({
  required String uploadPath,
  required String originalFileName,
}) async {
  final err = IntegrationValidators.validateImportFileName(originalFileName);
  if (err != null) throw IntegrationValidationException(err);

  if (!IntegrationValidators.importShouldUseIcsFileName(originalFileName)) {
    return uploadPath;
  }

  final ext = IntegrationValidators.normalizedExtension(originalFileName);
  if (ext == '.ics') return uploadPath;

  final dir = await getTemporaryDirectory();
  final out = File(
    '${dir.path}/orbit_import_${DateTime.now().millisecondsSinceEpoch}.ics',
  );
  await out.writeAsBytes(await File(uploadPath).readAsBytes(), flush: true);
  return out.path;
}
