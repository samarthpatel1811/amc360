<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Company;
use App\Services\AuditLogService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CompanyController extends BaseApiController
{
    /**
     * Get company profile.
     */
    public function show(Request $request): JsonResponse
    {
        $company = $request->user()->company;
        return $this->successResponse($company);
    }

    /**
     * Update company details.
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->isAdmin()) {
            return $this->errorResponse('Unauthorized. Only company admin can modify settings.', null, 403);
        }

        $company = $user->company;
        $old = $company->toArray();

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'business_type' => 'nullable|string|max:100',
            'custom_business_type' => 'nullable|string|max:100',
            'email' => 'nullable|email|max:255',
            'phone' => 'nullable|string|max:50',
            'website' => 'nullable|string|max:255',
            'address_line_1' => 'nullable|string|max:255',
            'address_line_2' => 'nullable|string|max:255',
            'city' => 'nullable|string|max:100',
            'state' => 'nullable|string|max:100',
            'country' => 'nullable|string|max:100',
            'postal_code' => 'nullable|string|max:20',
            'tax_number' => 'nullable|string|max:50',
            'currency' => 'nullable|string|max:10',
            'currency_symbol' => 'nullable|string|max:10',
            'timezone' => 'nullable|string|max:50',
            'primary_color' => 'nullable|string|max:20',
            'secondary_color' => 'nullable|string|max:20',
            'logo_url' => 'nullable|string',
            'invoice_logo_url' => 'nullable|string',
            'report_logo_url' => 'nullable|string',
            'customer_prefix' => 'nullable|string|max:20',
            'contract_prefix' => 'nullable|string|max:20',
            'service_request_prefix' => 'nullable|string|max:20',
            'service_visit_prefix' => 'nullable|string|max:20',
            'service_report_prefix' => 'nullable|string|max:20',
            'invoice_prefix' => 'nullable|string|max:20',
            'payment_prefix' => 'nullable|string|max:20',
            'default_tax_rate' => 'nullable|numeric|min:0|max:100',
            'tax_enabled' => 'nullable|boolean',
            'require_customer_signature' => 'nullable|boolean',
            'require_gps' => 'nullable|boolean',
            'require_service_photos' => 'nullable|boolean',
        ]);

        $company->update($validated);

        // Keep admin user credentials synchronized with official company contact details
        if (!empty($validated['email'])) {
            $user->update(['email' => $validated['email']]);
        }
        if (!empty($validated['phone'])) {
            $user->update(['phone' => $validated['phone']]);
        }

        AuditLogService::log('company_settings_updated', $company, $old, $company->fresh()->toArray());

        return $this->successResponse($company->fresh(), 'Company settings updated successfully.');
    }
}
