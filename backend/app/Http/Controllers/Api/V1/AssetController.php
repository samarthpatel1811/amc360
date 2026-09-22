<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Asset;
use App\Models\Customer;
use App\Services\AuditLogService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AssetController extends BaseApiController
{
    /**
     * List assets with search and filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Asset::query();

        // Customer sees only their own assets
        if ($request->user()->isCustomer()) {
            $query->where('customer_id', $request->user()->customer_id);
        } elseif ($customerId = $request->get('customer_id')) {
            $query->where('customer_id', $customerId);
        }

        if ($categoryId = $request->get('category_id')) {
            $query->where('category_id', $categoryId);
        }

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('asset_code', 'like', "%{$search}%")
                    ->orWhere('serial_number', 'like', "%{$search}%")
                    ->orWhere('brand', 'like', "%{$search}%")
                    ->orWhere('model', 'like', "%{$search}%")
                    ->orWhere('location', 'like', "%{$search}%");
            });
        }

        $perPage = (int) $request->get('per_page', 20);
        $assets = $query->with(['customer', 'category'])
            ->latest()
            ->paginate($perPage);

        return $this->successResponse($assets);
    }

    /**
     * Store new asset.
     */
    public function store(Request $request): JsonResponse
    {
        if ($request->user()->isCustomer()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $validated = $request->validate([
            'customer_id' => 'required|exists:customers,id',
            'category_id' => 'nullable|exists:asset_categories,id',
            'asset_code' => 'required|string|max:50',
            'asset_type' => 'required|string|max:100',
            'brand' => 'required|string|max:100',
            'model' => 'nullable|string|max:100',
            'serial_number' => 'required|string|max:100',
            'capacity' => 'nullable|string|max:50',
            'installation_date' => 'nullable|date',
            'purchase_date' => 'nullable|date',
            'warranty_start' => 'nullable|date',
            'warranty_end' => 'nullable|date',
            'location' => 'nullable|string|max:255',
            'status' => 'nullable|string|in:active,under_maintenance,under_repair,inactive,retired',
            'notes' => 'nullable|string',
        ]);

        $company = $request->user()->company;
        $validated['company_id'] = $company->id;
        $validated['qr_token'] = (string) Str::uuid();
        $validated['status'] = $validated['status'] ?? 'active';

        // Ensure customer belongs to current company
        Customer::where('company_id', $company->id)->findOrFail($validated['customer_id']);

        $asset = Asset::create($validated);

        AuditLogService::log('asset_created', $asset);

        return $this->successResponse($asset->load(['customer', 'category']), 'Asset created successfully.', 201);
    }

    /**
     * Show asset.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $asset = Asset::with(['customer', 'category', 'contracts'])->findOrFail($id);

        if ($request->user()->isCustomer() && $request->user()->customer_id !== $asset->customer_id) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        return $this->successResponse($asset);
    }

    /**
     * Update asset.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        if ($request->user()->isCustomer()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $asset = Asset::findOrFail($id);
        $old = $asset->toArray();

        $validated = $request->validate([
            'category_id' => 'nullable|exists:asset_categories,id',
            'asset_code' => 'sometimes|required|string|max:50',
            'asset_type' => 'sometimes|required|string|max:100',
            'brand' => 'sometimes|required|string|max:100',
            'model' => 'nullable|string|max:100',
            'serial_number' => 'sometimes|required|string|max:100',
            'capacity' => 'nullable|string|max:50',
            'installation_date' => 'nullable|date',
            'purchase_date' => 'nullable|date',
            'warranty_start' => 'nullable|date',
            'warranty_end' => 'nullable|date',
            'location' => 'nullable|string|max:255',
            'status' => 'nullable|string|in:active,under_maintenance,under_repair,inactive,retired',
            'notes' => 'nullable|string',
        ]);

        $asset->update($validated);

        AuditLogService::log('asset_updated', $asset, $old, $asset->fresh()->toArray());

        return $this->successResponse($asset->fresh()->load(['customer', 'category']), 'Asset updated successfully.');
    }

    /**
     * Delete asset.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $asset = Asset::findOrFail($id);
        $asset->delete();

        AuditLogService::log('asset_deleted', $asset);

        return $this->successResponse(null, 'Asset archived successfully.');
    }

    /**
     * Scan asset by QR token.
     */
    public function scanQr(Request $request, string $qrToken): JsonResponse
    {
        $asset = Asset::where('qr_token', $qrToken)
            ->with(['customer', 'category', 'contracts'])
            ->first();

        if (!$asset) {
            return $this->errorResponse('Asset not found or unauthorized QR code.', null, 404);
        }

        // Customer can only scan their own equipment
        if ($request->user()->isCustomer() && $request->user()->customer_id !== $asset->customer_id) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        return $this->successResponse($asset, 'Asset identified via QR code.');
    }

    /**
     * Comprehensive asset history.
     */
    public function history(Request $request, int $id): JsonResponse
    {
        $asset = Asset::with([
            'customer',
            'contracts',
            'serviceVisits.technician',
            'serviceVisits.parts',
            'serviceVisits.checklistItems',
            'serviceRequests.assignedTechnician',
        ])->findOrFail($id);

        if ($request->user()->isCustomer() && $request->user()->customer_id !== $asset->customer_id) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        return $this->successResponse([
            'asset' => $asset,
            'active_amc' => $asset->contracts->where('status', 'active')->first(),
            'past_amcs' => $asset->contracts->where('status', '!=', 'active')->values(),
            'visits_history' => $asset->serviceVisits->sortByDesc('completed_at')->values(),
            'complaints_history' => $asset->serviceRequests->sortByDesc('created_at')->values(),
        ]);
    }
}
