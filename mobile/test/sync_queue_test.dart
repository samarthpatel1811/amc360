import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Offline Sync Queue Storage Tests', () {
    test('Starts with empty queue', () async {
      final queue = await SecureStorageService.getOfflineQueue();
      expect(queue, isEmpty);
    });

    test('Enqueues offline operations and preserves payload idempotency', () async {
      final op1 = {
        'local_operation_id': '550e8400-e29b-41d4-a716-446655440000',
        'entity_type': 'service_visit',
        'operation_type': 'complete_visit',
        'payload': {
          'visit_id': 1,
          'work_performed': 'Cleaned outdoor compressor unit, recharged R32 refrigerant.',
        },
      };

      await SecureStorageService.enqueueOfflineOperation(op1);
      final queue = await SecureStorageService.getOfflineQueue();

      expect(queue.length, 1);
      expect(queue[0]['local_operation_id'], '550e8400-e29b-41d4-a716-446655440000');
      expect(queue[0]['payload']['visit_id'], 1);
    });

    test('Removes specific operation after successful server sync', () async {
      final op1 = {
        'local_operation_id': 'op-1',
        'entity_type': 'service_visit',
        'operation_type': 'add_part',
        'payload': {'part_name': 'Capacitor 45uF'},
      };
      final op2 = {
        'local_operation_id': 'op-2',
        'entity_type': 'service_visit',
        'operation_type': 'signature',
        'payload': {'signed_by_name': 'Customer Rep'},
      };

      await SecureStorageService.enqueueOfflineOperation(op1);
      await SecureStorageService.enqueueOfflineOperation(op2);

      var queue = await SecureStorageService.getOfflineQueue();
      expect(queue.length, 2);

      await SecureStorageService.removeOfflineOperation('op-1');

      queue = await SecureStorageService.getOfflineQueue();
      expect(queue.length, 1);
      expect(queue[0]['local_operation_id'], 'op-2');
    });

    test('Clears entire offline queue', () async {
      await SecureStorageService.enqueueOfflineOperation({
        'local_operation_id': 'temp-op',
        'operation_type': 'dummy',
      });

      await SecureStorageService.clearOfflineQueue();
      final queue = await SecureStorageService.getOfflineQueue();
      expect(queue, isEmpty);
    });
  });
}
