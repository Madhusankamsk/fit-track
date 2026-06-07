import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/di.dart';

class SaveActivityScreen extends ConsumerStatefulWidget {
  const SaveActivityScreen({super.key});

  @override
  ConsumerState<SaveActivityScreen> createState() => _SaveActivityScreenState();
}

class _SaveActivityScreenState extends ConsumerState<SaveActivityScreen> {
  final _titleController = TextEditingController(text: 'Morning Run');
  String _activityType = 'run';
  bool _syncing = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final startTime = extra?['startTime'] as DateTime? ?? DateTime.now();
    final durationSeconds = extra?['durationSeconds'] as int? ?? 0;

    setState(() { _syncing = true; _error = null; });

    final result = await ref.read(syncServiceProvider).syncActivity(
      title: _titleController.text.trim(),
      activityType: _activityType,
      startTime: startTime,
      durationSeconds: durationSeconds,
    );

    if (!mounted) return;

    if (result.success) {
      context.go('/feed');
    } else {
      setState(() {
        _error = result.error;
        _syncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save Activity')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _activityType,
              decoration: const InputDecoration(labelText: 'Activity Type', border: OutlineInputBorder()),
              items: AppConstants.activityTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _activityType = v ?? 'run'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _syncing ? null : _save,
              child: _syncing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save & Sync'),
            ),
          ],
        ),
      ),
    );
  }
}
