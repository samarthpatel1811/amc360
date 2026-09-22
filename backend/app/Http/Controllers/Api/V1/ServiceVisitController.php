<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\ChecklistTemplate;
use App\Models\Company;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Models\ServiceSchedule;
use App\Models\ServiceVisit;
use App\Models\ServiceVisitChecklistItem;
use App\Models\ServiceVisitPart;
use App\Models\ServiceVisitPhoto;
use App\Models\ServiceVisitSignature;
use App\Services\AuditLogService;
use App\Services\NumberingService;
use App\Services\PdfReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class ServiceVisitController extends BaseApiController
{
    public function __construct(
        protected PdfReportService $pdfService
    ) {}

    /**
     * List visits.
     */
    public function index(Request $request): JsonResponse
    {
        $query = ServiceVisit::query();

        if ($request->user()->isCustomer()) {
            $query->where('customer_id', $request->user()->customer_id);
        } elseif ($request->user()->isTechnician()) {
            $query->where('technician_id', $request->user()->id);
        }

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        $visits = $query->with(['customer', 'asset', 'technician', 'contract'])
            ->latest('started_at')
            ->paginate((int) $request->get('per_page', 20));

        return $this->successResponse($visits);
    }

    /**
     * Start a service visit.
     */
    public function startVisit(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'schedule_id' => 'required|exists:service_schedules,id',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'client_operation_id' => 'nullable|uuid',
        ]);

        $user = $request->user();
        $schedule = ServiceSchedule::with(['contract.assets', 'customer', 'asset'])->findOrFail($validated['schedule_id']);

        // Technician validation
        if ($user->isTechnician() && $schedule->technician_id && $schedule->technician_id !== $user->id) {
            return $this->errorResponse('Unauthorized. This job is assigned to another technician.', null, 403);
        }

        // Idempotency check for offline sync
        if (!empty($validated['client_operation_id'])) {
            $existing = ServiceVisit::where('client_operation_id', $validated['client_operation_id'])->first();
            if ($existing) {
                return $this->successResponse($existing->load(['checklistItems', 'parts', 'photos', 'signature']), 'Visit already initiated.');
            }
        }

        return DB::transaction(function () use ($schedule, $user, $validated) {
            $company = $schedule->company;
            $visitNumber = NumberingService::nextVisitNumber($company);

            $visit = ServiceVisit::create([
                'company_id' => $company->id,
                'schedule_id' => $schedule->id,
                'contract_id' => $schedule->contract_id,
                'customer_id' => $schedule->customer_id,
                'asset_id' => $schedule->asset_id ?: ($schedule->contract?->assets->first()?->id ?? null),
                'technician_id' => $user->id,
                'service_category_id' => $schedule->service_category_id,
                'visit_number' => $visitNumber,
                'status' => 'in_progress',
                'started_at' => now(),
                'start_latitude' => $validated['latitude'] ?? null,
                'start_longitude' => $validated['longitude'] ?? null,
                'client_operation_id' => $validated['client_operation_id'] ?? null,
            ]);

            $schedule->update(['status' => 'in_progress']);

            // Clone template checklist items
            $template = ChecklistTemplate::where('company_id', $company->id)
                ->where('active', true)
                ->with('items')
                ->first();

            if ($template && $template->items->isNotEmpty()) {
                foreach ($template->items as $item) {
                    ServiceVisitChecklistItem::create([
                        'service_visit_id' => $visit->id,
                        'checklist_item_id' => $item->id,
                        'title' => $item->title,
                        'response_type' => $item->response_type,
                        'required' => $item->required,
                        'value' => null,
                        'is_passed' => null,
                    ]);
                }
            }

            AuditLogService::log('visit_started', $visit);

            return $this->successResponse(
                $visit->load(['checklistItems', 'customer', 'asset', 'contract']),
                'Service visit started successfully.',
                201
            );
        });
    }

    /**
     * Show visit details.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $visit = ServiceVisit::with([
            'customer',
            'asset',
            'technician',
            'contract',
            'checklistItems',
            'photos',
            'parts',
            'signature',
        ])->findOrFail($id);

        if ($request->user()->isCustomer() && $request->user()->customer_id !== $visit->customer_id) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        return $this->successResponse($visit);
    }

    /**
     * Update checklist items.
     */
    public function updateChecklist(Request $request, int $id): JsonResponse
    {
        $visit = ServiceVisit::findOrFail($id);

        if ($visit->status === 'completed') {
            return $this->errorResponse('Completed visit cannot be modified.', null, 422);
        }

        $validated = $request->validate([
            'items' => 'required|array',
            'items.*.id' => 'required|exists:service_visit_checklist_items,id',
            'items.*.value' => 'nullable|string',
            'items.*.is_passed' => 'nullable|boolean',
        ]);

        foreach ($validated['items'] as $itemData) {
            ServiceVisitChecklistItem::where('id', $itemData['id'])
                ->where('service_visit_id', $visit->id)
                ->update([
                    'value' => $itemData['value'] ?? null,
                    'is_passed' => $itemData['is_passed'] ?? null,
                ]);
        }

        return $this->successResponse($visit->checklistItems()->get(), 'Checklist updated.');
    }

    /**
     * Add photo to service visit.
     */
    public function addPhoto(Request $request, int $id): JsonResponse
    {
        $visit = ServiceVisit::findOrFail($id);

        $request->validate([
            'photo' => 'required|image|max:10240', // Max 10MB
            'photo_type' => 'nullable|string|in:before,after,equipment,damage,other',
            'caption' => 'nullable|string|max:255',
        ]);

        $path = $request->file('photo')->store('visit_photos/' . $visit->id, 'public');

        $photo = ServiceVisitPhoto::create([
            'service_visit_id' => $visit->id,
            'photo_type' => $request->photo_type ?? 'equipment',
            'file_path' => 'storage/' . $path,
            'caption' => $request->caption,
        ]);

        return $this->successResponse($photo, 'Photo uploaded successfully.', 201);
    }

    /**
     * Add part to service visit.
     */
    public function addPart(Request $request, int $id): JsonResponse
    {
        $visit = ServiceVisit::findOrFail($id);

        if ($visit->status === 'completed') {
            return $this->errorResponse('Completed visit cannot be modified.', null, 422);
        }

        $validated = $request->validate([
            'part_id' => 'nullable|exists:parts,id',
            'part_name' => 'required|string|max:255',
            'quantity' => 'required|numeric|min:0.01',
            'unit_price' => 'required|numeric|min:0',
            'coverage_type' => 'required|string|in:included,chargeable,warranty',
            'notes' => 'nullable|string',
        ]);

        $totalPrice = round($validated['quantity'] * $validated['unit_price'], 2);

        $part = ServiceVisitPart::create([
            'service_visit_id' => $visit->id,
            'part_id' => $validated['part_id'] ?? null,
            'part_name' => $validated['part_name'],
            'quantity' => $validated['quantity'],
            'unit_price' => $validated['unit_price'],
            'total_price' => $totalPrice,
            'coverage_type' => $validated['coverage_type'],
            'notes' => $validated['notes'] ?? null,
        ]);

        return $this->successResponse($part, 'Part recorded successfully.', 201);
    }

    /**
     * Capture customer signature.
     */
    public function captureSignature(Request $request, int $id): JsonResponse
    {
        $visit = ServiceVisit::findOrFail($id);

        $request->validate([
            'signature_image' => 'required|string', // Base64 encoded or image upload
            'signed_by_name' => 'required|string|max:255',
        ]);

        // Decode base64 image
        $image = $request->signature_image;
        if (preg_match('/^data:image\/(\w+);base64,/', $image, $type)) {
            $image = substr($image, strpos($image, ',') + 1);
            $type = strtolower($type[1]);
        } else {
            $type = 'png';
        }
        $data = base64_decode($image);

        $filename = 'signatures/visit_' . $visit->id . '_' . time() . '.' . $type;
        Storage::disk('public')->put($filename, $data);

        $sig = ServiceVisitSignature::updateOrCreate(
            ['service_visit_id' => $visit->id],
            [
                'signature_image_path' => 'storage/' . $filename,
                'signed_by_name' => $request->signed_by_name,
                'signed_at' => now(),
            ]
        );

        return $this->successResponse($sig, 'Signature captured successfully.');
    }

    /**
     * Complete service visit.
     */
    public function completeVisit(Request $request, int $id): JsonResponse
    {
        $visit = ServiceVisit::with(['checklistItems', 'parts', 'signature', 'company', 'customer'])->findOrFail($id);

        if ($visit->status === 'completed') {
            return $this->successResponse($visit, 'Visit is already completed.');
        }

        $user = $request->user();
        if ($user->isTechnician() && $visit->technician_id !== $user->id) {
            return $this->errorResponse('Technician cannot complete another technician\'s visit.', null, 403);
        }

        // Validate mandatory checklist items
        $unansweredMandatory = $visit->checklistItems
            ->where('required', true)
            ->filter(function ($item) {
                return $item->value === null && $item->is_passed === null;
            });

        if ($unansweredMandatory->isNotEmpty()) {
            return $this->errorResponse(
                'Mandatory checklist items must be completed before finishing visit: ' .
                $unansweredMandatory->pluck('title')->implode(', '),
                null,
                422
            );
        }

        $validated = $request->validate([
            'work_performed' => 'nullable|string',
            'findings' => 'nullable|string',
            'recommendations' => 'nullable|string',
            'customer_remarks' => 'nullable|string',
            'completion_latitude' => 'nullable|numeric',
            'completion_longitude' => 'nullable|numeric',
            'is_chargeable' => 'nullable|boolean',
            'visit_charge' => 'nullable|numeric|min:0',
        ]);

        return DB::transaction(function () use ($visit, $validated) {
            $company = $visit->company;
            $reportNumber = NumberingService::nextReportNumber($company);

            $visit->update(array_merge($validated, [
                'status' => 'completed',
                'completed_at' => now(),
                'report_number' => $reportNumber,
            ]));

            if ($visit->schedule) {
                $visit->schedule->update(['status' => 'completed']);
            }

            // Generate official PDF report
            $this->pdfService->generateServiceReport($visit);

            // Check if chargeable invoice should be generated
            $chargeableParts = $visit->parts->where('coverage_type', 'chargeable');
            $hasChargeableParts = $chargeableParts->isNotEmpty();
            $isChargeableVisit = !empty($validated['is_chargeable']) && ($validated['visit_charge'] ?? 0) > 0;

            if ($hasChargeableParts || $isChargeableVisit) {
                $subtotal = 0;
                $invoiceItemsData = [];

                if ($isChargeableVisit) {
                    $subtotal += $validated['visit_charge'];
                    $invoiceItemsData[] = [
                        'description' => 'Chargeable Service Visit (' . $visit->visit_number . ')',
                        'item_type' => 'service_visit',
                        'quantity' => 1,
                        'unit_price' => $validated['visit_charge'],
                        'total_price' => $validated['visit_charge'],
                    ];
                }

                foreach ($chargeableParts as $part) {
                    $subtotal += $part->total_price;
                    $invoiceItemsData[] = [
                        'description' => $part->part_name . ' (' . $part->quantity . ' qty)',
                        'item_type' => 'part',
                        'quantity' => $part->quantity,
                        'unit_price' => $part->unit_price,
                        'total_price' => $part->total_price,
                    ];
                }

                $taxRate = $company->default_tax_rate;
                $taxAmount = round($subtotal * ($taxRate / 100), 2);
                $total = round($subtotal + $taxAmount, 2);
                $invNumber = NumberingService::nextInvoiceNumber($company);

                $invoice = Invoice::create([
                    'company_id' => $company->id,
                    'customer_id' => $visit->customer_id,
                    'contract_id' => $visit->contract_id,
                    'service_visit_id' => $visit->id,
                    'invoice_number' => $invNumber,
                    'invoice_type' => $isChargeableVisit ? 'service' : 'parts',
                    'issue_date' => now()->toDateString(),
                    'due_date' => now()->addDays(15)->toDateString(),
                    'subtotal' => $subtotal,
                    'discount_amount' => 0,
                    'taxable_amount' => $subtotal,
                    'tax_rate' => $taxRate,
                    'tax_amount' => $taxAmount,
                    'total_amount' => $total,
                    'paid_amount' => 0,
                    'balance_due' => $total,
                    'status' => 'issued',
                    'notes' => 'Generated automatically from completed service visit ' . $visit->visit_number,
                ]);

                foreach ($invoiceItemsData as $item) {
                    InvoiceItem::create(array_merge($item, ['invoice_id' => $invoice->id]));
                }
            }

            AuditLogService::log('visit_completed', $visit, null, ['report_number' => $reportNumber]);

            return $this->successResponse(
                $visit->fresh()->load(['checklistItems', 'parts', 'signature', 'photos']),
                'Service visit completed and official PDF report generated.'
            );
        });
    }

    /**
     * Download or view PDF service report.
     */
    public function downloadPdf(Request $request, int $id)
    {
        $visit = ServiceVisit::findOrFail($id);

        if (!$visit->report_pdf_path || !Storage::disk('public')->exists(str_replace('storage/', '', $visit->report_pdf_path))) {
            $this->pdfService->generateServiceReport($visit);
        }

        $relativePath = str_replace('storage/', '', $visit->report_pdf_path);
        $fullPath = storage_path('app/public/' . $relativePath);

        return response()->download($fullPath, 'Service_Report_' . $visit->report_number . '.pdf');
    }
}
