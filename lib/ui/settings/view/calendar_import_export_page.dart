import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../auth/view_model/auth_view_model.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../../data/integration/integration_api_service.dart';
import '../../../data/integration/integration_import_upload.dart';
import '../../../data/integration/integration_validators.dart';
import '../../../data/services/api_client.dart';

class CalendarImportExportPage extends StatefulWidget {
  const CalendarImportExportPage({super.key});

  @override
  State<CalendarImportExportPage> createState() =>
      _CalendarImportExportPageState();
}

class _CalendarImportExportPageState extends State<CalendarImportExportPage> {
  bool _busy = false;

  String _originalFileNameForImport(PlatformFile file, String? selectedPath) {
    final n = file.name.trim();
    if (n.isNotEmpty) return n;
    if (selectedPath != null && selectedPath.isNotEmpty) {
      final segments = Uri.file(selectedPath).pathSegments;
      if (segments.isNotEmpty) return segments.last;
    }
    return 'import.ics';
  }

  Future<void> _importIcs() async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthViewModel>();
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sign in to import events'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'ics',
        'ical',
        'ifb',
        'icalendar',
        'csv',
      ],
      withData: true,
    );
    if (!context.mounted) return;
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final selectedPath = file.path;
    final bytes = file.bytes;
    if (selectedPath == null && bytes == null) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not read the selected file'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final originalName = _originalFileNameForImport(file, selectedPath);
    final nameErr = IntegrationValidators.validateImportFileName(originalName);
    if (nameErr != null) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(nameErr),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // Backend: POST /api/v1/integration/import (multipart/form-data: file)
      final api = ApiClient();
      String uploadPath = selectedPath ?? '';
      if (uploadPath.isEmpty) {
        final dir = await getTemporaryDirectory();
        final safeName =
            (file.name.trim().isEmpty) ? 'import.ics' : file.name.trim();
        final p = '${dir.path}/$safeName';
        final tempFile = File(p);
        await tempFile.writeAsBytes(bytes!, flush: true);
        uploadPath = p;
      }

      final pathForUpload = await prepareCalendarImportUploadPath(
        uploadPath: uploadPath,
        originalFileName: originalName,
      );

      final resp = await api.uploadFile<Map<String, dynamic>>(
        '/integration/import',
        pathForUpload,
        options: Options(
          headers: const {'Accept': 'application/json'},
          contentType: 'multipart/form-data',
          validateStatus: (_) => true,
        ),
      );

      if ((resp.statusCode ?? 0) < 200 || (resp.statusCode ?? 0) >= 300) {
        final msg = resp.data?['message']?.toString() ??
            resp.data?['error']?.toString() ??
            'Import failed (HTTP ${resp.statusCode})';
        throw DioException(
          requestOptions: resp.requestOptions,
          response: resp,
          type: DioExceptionType.badResponse,
          error: msg,
        );
      }

      final data = resp.data ?? const <String, dynamic>{};
      final eventsImported = data['events_imported'];
      final tasksImported = data['tasks_imported'];

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Import complete: ${eventsImported ?? 0} events, ${tasksImported ?? 0} tasks',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // Best-effort refresh so UI reflects imported data.
      if (!mounted) return;
      await context.read<AuthViewModel>().loadProfile();
      if (!mounted) return;
      await context.read<CalendarViewModel>().fetchAll(
            userId: userId,
            eventRangeAnchor: DateTime.now(),
            showLoading: false,
          );
    } on IntegrationValidationException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Import failed: ${e.message ?? e.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportIcs() async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthViewModel>();
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sign in to export events'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final integration = IntegrationApiService();
      final resp = await integration.getExport<List<int>>(
        format: 'ics',
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'Accept': 'text/calendar'},
          validateStatus: (_) => true,
        ),
      );
      final status = resp.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw DioException(
          requestOptions: resp.requestOptions,
          response: resp,
          type: DioExceptionType.badResponse,
          error: 'Export failed (HTTP $status)',
        );
      }
      final bytes = resp.data;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Export returned an empty file')),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/orbit_calendar_export_${DateTime.now().millisecondsSinceEpoch}.ics';
      final f = File(path);
      await f.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(path, mimeType: 'text/calendar')],
        subject: 'Orbit calendar export',
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E0FF),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFECF9FB), Color(0xFFE2E0FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                IconButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 22,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Import / Export',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use iCalendar (.ics) or CSV (.csv) to move events between Orbit and other calendar apps (Google Calendar, Apple Calendar, Outlook, etc.). Import/export is handled by the Orbit backend.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Import',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose an .ics or .csv file. Each row or event in the file will be added to your Orbit calendar.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : _importIcs,
                          icon: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_file_rounded),
                          label: Text(_busy ? 'Working…' : 'Import file'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Export',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exports events from roughly one year ago through two years ahead. Share or save the generated .ics file.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _exportIcs,
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Export to .ics'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(
                              color: AppColors.grey300.withValues(alpha: 0.9),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
