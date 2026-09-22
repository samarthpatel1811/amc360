import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _queue = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    final items = await SecureStorageService.getOfflineQueue();
    setState(() {
      _queue = items;
      _isLoading = false;
    });
  }

  Future<void> _triggerSync() async {
    if (_queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline queue is currently empty.')),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });

    try {
      final res = await _api.post('/sync/offline-queue', data: {
        'operations': _queue,
      });

      if (res.statusCode == 200) {
        final results = res.data['data'] as List<dynamic>? ?? [];
        int successCount = 0;
        for (final r in results) {
          final status = r['status'];
          if (status == 'success' || status == 'already_synced') {
            successCount++;
            final opId = r['local_operation_id']?.toString();
            if (opId != null) {
              await SecureStorageService.removeOfflineOperation(opId);
            }
          }
        }

        await _loadQueue();

        setState(() {
          _syncMessage = 'Sync completed: $successCount / ${results.length} operations processed successfully.';
        });
      }
    } catch (e) {
      setState(() {
        _syncMessage = 'Sync failed: $e';
      });
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _clearQueue() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Offline Queue?'),
        content: const Text('This will discard all pending offline changes that have not yet synced to the server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SecureStorageService.clearOfflineQueue();
      await _loadQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQueue,
          ),
          if (_queue.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearQueue,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: _isSyncing ? 'Syncing...' : 'Sync Pending Operations (${_queue.length})',
            icon: Icons.cloud_upload_outlined,
            isLoading: _isSyncing,
            onPressed: _queue.isEmpty ? null : _triggerSync,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_syncMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    color: _syncMessage!.startsWith('Sync completed')
                        ? AppTheme.success.withAlpha(30)
                        : AppTheme.error.withAlpha(30),
                    child: Text(
                      _syncMessage!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _syncMessage!.startsWith('Sync completed') ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_tethering, size: 28, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Idempotent Sync Engine',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_queue.length} pending mutation${_queue.length == 1 ? '' : 's'} stored on device',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _queue.isEmpty
                      ? const EmptyState(
                          title: 'Queue is Synchronized',
                          message: 'All technician visits and actions have been synced to the central database.',
                          icon: Icons.cloud_done_outlined,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _queue.length,
                          itemBuilder: (context, index) {
                            final item = _queue[index];
                            final opType = item['operation_type'] ?? 'Mutation';
                            final entityType = item['entity_type'] ?? 'Record';
                            final opId = item['local_operation_id'] ?? '';

                            return AppCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        opType.toString().toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                      ),
                                      Text(
                                        entityType,
                                        style: TextStyle(
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Client Op ID: $opId',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
