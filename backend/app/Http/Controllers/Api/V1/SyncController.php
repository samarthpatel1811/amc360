<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\ServiceVisit;
use App\Models\ServiceVisitChecklistItem;
use App\Models\ServiceVisitPart;
use App\Models\ServiceVisitSignature;
use App\Models\SyncOperation;
use App\Services\AuditLogService;
use App\Services\NumberingService;
use App\Services\PdfReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class SyncController extends BaseApiController
{
    public function __construct(
        protected PdfReportService $pdfService
    ) {}

    /**
     * Batch process offline synchronization queue with strict idempotency.
     */
    public function syncOfflineQueue(Request $request): JsonResponse
    {
        $request->validate([
            'operations' => 'required|array',
            'operations.*.local_operation_id' => 'required|uuid',
            'operations.*.entity_type' => 'required|string',
            'operations.*.operation_type' => 'required|string',
            'operations.*.payload' => 'required|array',
        ]);

        $user = $request->user();
        $company = $user->company;
        $results = [];

        foreach ($request->operations as $op) {
            $localOpId = $op['local_operation_id'];

            // 1. Idempotency check: Has this operation already been processed?
            $existingSync = SyncOperation::where('local_operation_id', $localOpId)->first();
            if ($existingSync) {
                $results[] = [
                    'local_operation_id' => $localOpId,
                    'status' => 'already_synced',
                    'entity_id' => $existingSync->entity_id,
                    'message' => 'Operation was previously processed.',
                ];
                continue;
            }

            try {
                DB::beginTransaction();

                $entityId = null;
                $payload = $op['payload'];

                if ($op['operation_type'] === 'complete_visit') {
                    $visitId = $payload['visit_id'];
                    $visit = ServiceVisit::with(['checklistItems', 'parts'])->findOrFail($visitId);

                    if ($visit->status !== 'completed') {
                        $reportNumber = NumberingService::nextReportNumber($company);

                        $visit->update([
                            'status' => 'completed',
                            'completed_at' => $payload['completed_at'] ?? now(),
                            'work_performed' => $payload['work_performed'] ?? $visit->work_performed,
                            'findings' => $payload['findings'] ?? $visit->findings,
                            'recommendations' => $payload['recommendations'] ?? $visit->recommendations,
                            'customer_remarks' => $payload['customer_remarks'] ?? $visit->customer_remarks,
                            'completion_latitude' => $payload['latitude'] ?? null,
                            'completion_longitude' => $payload['longitude'] ?? null,
                            'report_number' => $reportNumber,
                            'client_operation_id' => $localOpId,
                        ]);

                        if ($visit->schedule) {
                            $visit->schedule->update(['status' => 'completed']);
                        }

                        // Save signature if in payload
                        if (!empty($payload['signature_image']) && !empty($payload['signed_by_name'])) {
                            $image = $payload['signature_image'];
                            if (preg_match('/^data:image\/(\w+);base64,/', $image, $type)) {
                                $image = substr($image, strpos($image, ',') + 1);
                                $ext = strtolower($type[1]);
                            } else {
                                $ext = 'png';
                            }
                            $filename = 'signatures/visit_' . $visit->id . '_' . time() . '.' . $ext;
                            Storage::disk('public')->put($filename, base64_decode($image));

                            ServiceVisitSignature::updateOrCreate(
                                ['service_visit_id' => $visit->id],
                                [
                                    'signature_image_path' => 'storage/' . $filename,
                                    'signed_by_name' => $payload['signed_by_name'],
                                    'signed_at' => now(),
                                ]
                            );
                        }

                        $this->pdfService->generateServiceReport($visit);
                    }

                    $entityId = $visit->id;
                }

                // Log sync operation
                SyncOperation::create([
                    'company_id' => $company->id,
                    'user_id' => $user->id,
                    'local_operation_id' => $localOpId,
                    'entity_type' => $op['entity_type'],
                    'entity_id' => $entityId,
                    'operation_type' => $op['operation_type'],
                    'payload' => $payload,
                    'sync_status' => 'synced',
                ]);

                DB::commit();

                $results[] = [
                    'local_operation_id' => $localOpId,
                    'status' => 'synced',
                    'entity_id' => $entityId,
                    'message' => 'Successfully synchronized.',
                ];
            } catch (\Exception $e) {
                DB::rollBack();

                $results[] = [
                    'local_operation_id' => $localOpId,
                    'status' => 'failed',
                    'error' => $e->getMessage(),
                ];
            }
        }

        return $this->successResponse([
            'processed_count' => count($results),
            'results' => $results,
        ], 'Offline synchronization completed.');
    }
}
