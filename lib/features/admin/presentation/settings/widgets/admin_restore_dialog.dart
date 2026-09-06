import 'package:flutter/material.dart';

class AdminRestoreDialog extends StatefulWidget {
  const AdminRestoreDialog({
    super.key,
    required this.onRestore,
    this.onDryRun,
    this.onRollback,
  });

  final Future<Map<String, dynamic>> Function(
    String fileId,
    String? operationId,
    void Function(Map<String, dynamic>) onProgress,
    bool Function() shouldContinue,
  )
  onRestore;

  final Future<Map<String, dynamic>> Function(
    String fileId,
    String? operationId,
  )?
  onDryRun;

  final Future<Map<String, dynamic>> Function(
    String restoreId,
    void Function(Map<String, dynamic>) onProgress,
  )?
  onRollback;

  @override
  State<AdminRestoreDialog> createState() => _AdminRestoreDialogState();
}

class _AdminRestoreDialogState extends State<AdminRestoreDialog> {
  final _file = TextEditingController();
  final _operation = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _progress;
  Map<String, dynamic>? _dryRunResult;

  @override
  void dispose() {
    _file.dispose();
    _operation.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submitDryRun() async {
    if (_busy || _file.text.trim().isEmpty || widget.onDryRun == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _dryRunResult = null;
    });
    try {
      final operation = _operation.text.trim();
      final result = await widget.onDryRun!(
        _file.text.trim(),
        operation.isEmpty ? null : operation,
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _dryRunResult = result;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _submitRollback() async {
    final operation = _operation.text.trim();
    if (_busy || operation.isEmpty || widget.onRollback == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.onRollback!(operation, (progress) {
        if (mounted) setState(() => _progress = progress);
      });
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _submit() async {
    if (_busy || _confirmation.text != 'RESTORE') return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final operation = _operation.text.trim();
      final result = await widget.onRestore(
        _file.text.trim(),
        operation.isEmpty ? null : operation,
        (progress) {
          if (mounted) setState(() => _progress = progress);
        },
        () => mounted,
      );
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final backup = _progress?['backup'];
    return AlertDialog(
      title: const Text('Restore / Resume Content'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This replaces all learning content. Pause content editing '
                'and wipe/seeding jobs first. The original safety backup is '
                'kept. Interrupted work resumes from its saved checkpoint.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _file,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Backup file ID'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _operation,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Recovery operation ID (optional)',
                  helperText:
                      'For another device; leave blank to resume locally.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmation,
                enabled: !_busy,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Type RESTORE to confirm',
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              if (_progress != null) ...[
                const SizedBox(height: 16),
                SelectableText(
                  'Operation: ${_progress!['jobId']}\n'
                  'Phase: ${_progress!['phase']}\n'
                  'Collection checkpoint: ${_progress!['collectionIndex']}\n'
                  'Safety backup: ${backup is Map ? backup['fileId'] : 'preparing'}',
                ),
              ],
              if (_dryRunResult != null) ...[
                const SizedBox(height: 16),
                SelectableText(
                  '✅ Dry run passed!\n'
                  'Total documents: ${_dryRunResult!['totalDocuments']}\n'
                  'Digest: ${_dryRunResult!['digest']?.toString().substring(0, 16)}...\n'
                  '${_dryRunResult!['message']}',
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                SelectableText(_error!),
                const Text(
                  'Retry with the same backup to resume. Do not wipe or re-seed.',
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (widget.onDryRun != null)
          TextButton(
            onPressed: _busy || _file.text.trim().isEmpty
                ? null
                : _submitDryRun,
            child: const Text('Validate (Dry Run)'),
          ),
        if (widget.onRollback != null && _operation.text.trim().isNotEmpty)
          OutlinedButton(
            onPressed: _busy ? null : _submitRollback,
            child: const Text('Rollback to Safety'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_busy ? 'Pause and close' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _busy || _confirmation.text != 'RESTORE' ? null : _submit,
          child: const Text('Restore / Resume'),
        ),
      ],
    );
  }
}
