<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Customer;
use App\Models\User;
use App\Services\AuditLogService;
use App\Services\NumberingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class CustomerController extends BaseApiController
{
    /**
     * List customers with search, filter, and pagination.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Customer::query();

        // Customer role can only see their own customer profile
        if ($request->user()->isCustomer()) {
            $query->where('id', $request->user()->customer_id);
        }

        // Search by name, phone, code, company_name
        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('customer_code', 'like', "%{$search}%")
                    ->orWhere('company_name', 'like', "%{$search}%");
            });
        }

        // Filter by status
        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        $perPage = (int) $request->get('per_page', 15);
        $customers = $query->withCount(['assets', 'contracts', 'serviceRequests'])
            ->latest()
            ->paginate($perPage);

        return $this->successResponse($customers);
    }

    /**
     * Create new customer.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->isAdmin()) {
            return $this->errorResponse('Unauthorized. Only company admin can create customers.', null, 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'company_name' => 'nullable|string|max:255',
            'customer_type' => 'nullable|string|in:commercial,residential,industrial',
            'phone' => 'required|string|max:30',
            'alternate_phone' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:255',
            'gst_number' => 'nullable|string|max:50',
            'address_line_1' => 'required|string|max:255',
            'address_line_2' => 'nullable|string|max:255',
            'city' => 'required|string|max:100',
            'state' => 'required|string|max:100',
            'country' => 'nullable|string|max:100',
            'postal_code' => 'nullable|string|max:20',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'notes' => 'nullable|string',
            'create_user_account' => 'nullable|boolean',
            'user_password' => 'nullable|string|min:8',
        ]);

        $company = $user->company;
        $validated['customer_code'] = NumberingService::nextCustomerCode($company);
        $validated['company_id'] = $company->id;
        $validated['status'] = 'active';

        $customer = Customer::create($validated);

        // Optionally create client login account
        if (!empty($validated['create_user_account']) && !empty($validated['email'])) {
            User::create([
                'company_id' => $company->id,
                'customer_id' => $customer->id,
                'name' => $customer->name,
                'email' => $customer->email,
                'phone' => $customer->phone,
                'role' => 'customer',
                'password' => Hash::make($validated['user_password'] ?: 'Customer@123'),
                'status' => 'active',
            ]);
        }

        AuditLogService::log('customer_created', $customer);

        return $this->successResponse($customer->fresh(), 'Customer created successfully.', 201);
    }

    /**
     * Get customer details with relation summaries.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $customer = Customer::withCount(['assets', 'contracts', 'serviceRequests', 'invoices'])
            ->findOrFail($id);

        if ($request->user()->isCustomer() && $request->user()->customer_id !== $customer->id) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        return $this->successResponse($customer);
    }

    /**
     * Update customer details.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        if ($request->user()->isCustomer()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $customer = Customer::findOrFail($id);
        $old = $customer->toArray();

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'company_name' => 'nullable|string|max:255',
            'customer_type' => 'nullable|string|in:commercial,residential,industrial',
            'phone' => 'sometimes|required|string|max:30',
            'alternate_phone' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:255',
            'gst_number' => 'nullable|string|max:50',
            'address_line_1' => 'sometimes|required|string|max:255',
            'address_line_2' => 'nullable|string|max:255',
            'city' => 'sometimes|required|string|max:100',
            'state' => 'sometimes|required|string|max:100',
            'country' => 'nullable|string|max:100',
            'postal_code' => 'nullable|string|max:20',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'notes' => 'nullable|string',
            'status' => 'nullable|string|in:active,inactive,archived',
        ]);

        $customer->update($validated);

        AuditLogService::log('customer_updated', $customer, $old, $customer->fresh()->toArray());

        return $this->successResponse($customer->fresh(), 'Customer updated successfully.');
    }

    /**
     * Soft delete customer (preserves history).
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $customer = Customer::findOrFail($id);

        if ($customer->contracts()->where('status', 'active')->exists()) {
            return $this->errorResponse('Cannot delete customer with active contracts. Deactivate or cancel contracts first.', null, 422);
        }

        $customer->delete();

        AuditLogService::log('customer_archived', $customer);

        return $this->successResponse(null, 'Customer archived successfully.');
    }

    /**
     * Get customer assets.
     */
    public function assets(int $id): JsonResponse
    {
        $customer = Customer::findOrFail($id);
        $assets = $customer->assets()->with('category')->latest()->get();
        return $this->successResponse($assets);
    }

    /**
     * Get customer contracts.
     */
    public function contracts(int $id): JsonResponse
    {
        $customer = Customer::findOrFail($id);
        $contracts = $customer->contracts()->with('assets')->latest()->get();
        return $this->successResponse($contracts);
    }

    /**
     * Get customer service history.
     */
    public function visits(int $id): JsonResponse
    {
        $customer = Customer::findOrFail($id);
        $visits = $customer->serviceVisits()->with(['asset', 'technician', 'serviceCategory'])->latest()->get();
        return $this->successResponse($visits);
    }

    /**
     * Get customer invoices.
     */
    public function invoices(int $id): JsonResponse
    {
        $customer = Customer::findOrFail($id);
        $invoices = $customer->invoices()->with('payments')->latest()->get();
        return $this->successResponse($invoices);
    }
}
