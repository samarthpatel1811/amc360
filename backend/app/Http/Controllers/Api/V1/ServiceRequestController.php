<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Asset;
use App\Models\Contract;
use App\Models\ServiceRequest;
use App\Models\User;
use App\Services\AuditLogService;
use App\Services\NumberingService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ServiceRequestController extends BaseApiController
{
    /**
     * List service requests / complaints.
     */
    public function index(Request $request): JsonResponse
    {
        $query = ServiceRequest::query();

        if ($request->user()->isCustomer()) {
            $query->where('customer_id', $request->user()->customer_id);
        } elseif ($request->user()->isTechnician()) {
            $query->where('assigned_technician_id', $request->user()->id);
        }

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        if ($priority = $request->get('priority')) {
            $query->where('priority', $priority);
        }

        $requests = $query->with(['customer', 'asset', 'contract', 'assignedTechnician'])
            ->latest()
            ->paginate((int) $request->get('per_page', 20));

        return $this->successResponse($requests);
    }

    /**
     * Create service request.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'asset_id' => 'required|exists:assets,id',
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'issue_type' => 'required|string|max:100',
            'priority' => 'nullable|string|in:low,normal,high,urgent',
            'preferred_date' => 'nullable|date',
            'preferred_time' => 'nullable|string|max:50',
            'photo' => 'nullable|image|max:10240',
        ]);

        $user = $request->user();
        $company = $user->company;
        $asset = Asset::with('customer')->findOrFail($validated['asset_id']);

        // Determine customer ID
        $customerId = $user->isCustomer() ? $user->customer_id : $asset->customer_id;

        // Check if covered under active contract
        $activeContract = Contract::where('customer_id', $customerId)
            ->where('status', 'active')
            ->whereHas('assets', function ($q) use ($asset) {
                $q->where('assets.id', $asset->id);
            })->first();

        // Calculate SLA due time
        $slaHours = 24; // Default 24h
        if ($activeContract && $activeContract->sla_response_hours) {
            $slaHours = $activeContract->sla_response_hours;
        } elseif ($validated['priority'] === 'urgent') {
            $slaHours = 4;
        } elseif ($validated['priority'] === 'high') {
            $slaHours = 8;
        }

        $slaDueAt = now()->addHours($slaHours);

        $photoPath = null;
        if ($request->hasFile('photo')) {
            $stored = $request->file('photo')->store('request_photos', 'public');
            $photoPath = 'storage/' . $stored;
        }

        $requestNumber = NumberingService::nextServiceRequestNumber($company);

        $serviceRequest = ServiceRequest::create([
            'company_id' => $company->id,
            'customer_id' => $customerId,
            'asset_id' => $asset->id,
            'contract_id' => $activeContract?->id,
            'request_number' => $requestNumber,
            'title' => $validated['title'],
            'description' => $validated['description'],
            'issue_type' => $validated['issue_type'],
            'priority' => $validated['priority'] ?? 'normal',
            'preferred_date' => $validated['preferred_date'] ?? null,
            'preferred_time' => $validated['preferred_time'] ?? null,
            'photo_path' => $photoPath,
            'status' => 'new',
            'is_covered_under_amc' => (bool) $activeContract,
            'sla_due_at' => $slaDueAt,
        ]);

        AuditLogService::log('service_request_created', $serviceRequest);

        return $this->successResponse(
            $serviceRequest->load(['customer', 'asset', 'contract']),
            'Service request registered successfully.',
            201
        );
    }

    /**
     * Show request.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $serviceRequest = ServiceRequest::with(['customer', 'asset', 'contract', 'assignedTechnician'])->findOrFail($id);

        if ($request->user()->isCustomer() && $request->user()->customer_id !== $serviceRequest->customer_id) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        return $this->successResponse($serviceRequest);
    }

    /**
     * Assign technician to service request.
     */
    public function assignTechnician(Request $request, int $id): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $serviceRequest = ServiceRequest::findOrFail($id);

        $validated = $request->validate([
            'technician_id' => 'required|exists:users,id',
        ]);

        $technician = User::where('role', 'technician')->findOrFail($validated['technician_id']);

        $serviceRequest->update([
            'assigned_technician_id' => $technician->id,
            'status' => 'assigned',
        ]);

        AuditLogService::log('service_request_assigned', $serviceRequest, ['technician_id' => $technician->id]);

        return $this->successResponse($serviceRequest->fresh()->load('assignedTechnician'), 'Technician assigned to service request.');
    }

    /**
     * Update status (e.g. accepted, on_the_way, in_progress, completed).
     */
    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $serviceRequest = ServiceRequest::findOrFail($id);

        $validated = $request->validate([
            'status' => 'required|string|in:accepted,on_the_way,in_progress,waiting_for_customer,waiting_for_part,completed,cancelled',
            'cancellation_reason' => 'nullable|string',
        ]);

        $updates = ['status' => $validated['status']];

        if ($validated['status'] === 'accepted' && !$serviceRequest->first_responded_at) {
            $updates['first_responded_at'] = now();
        }

        if ($validated['status'] === 'completed') {
            $updates['completed_at'] = now();
        }

        if ($validated['status'] === 'cancelled') {
            $updates['cancellation_reason'] = $validated['cancellation_reason'] ?? null;
        }

        $serviceRequest->update($updates);

        AuditLogService::log('service_request_status_updated', $serviceRequest, ['new_status' => $validated['status']]);

        return $this->successResponse($serviceRequest->fresh(), 'Status updated successfully.');
    }
}
