<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Contract;
use App\Models\Customer;
use App\Models\Invoice;
use App\Models\Notification;
use App\Models\Payment;
use App\Models\ServiceSchedule;
use App\Models\User;
use App\Services\AuditLogService;
use App\Services\ContractCalculationService;
use App\Services\NumberingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ContractController extends BaseApiController
{
    public function __construct(
        protected ContractCalculationService $calculationService
    ) {}

    /**
     * Preview calculated end date and schedule dates without persisting.
     */
    public function previewDates(Request $request): JsonResponse
    {
        $request->validate([
            'start_date' => 'required|date',
            'duration_type' => 'required|string',
            'custom_end_date' => 'nullable|date',
            'service_frequency' => 'required|string',
            'frequency_interval_value' => 'nullable|integer|min:1',
            'first_visit_rule' => 'nullable|string',
            'custom_first_visit_date' => 'nullable|date',
            'visit_count_type' => 'nullable|string',
            'included_visit_count' => 'nullable|integer|min:1',
        ]);

        try {
            $endDate = $this->calculationService->calculateEndDate(
                $request->start_date,
                $request->duration_type,
                $request->custom_end_date
            );

            $visits = $this->calculationService->generateScheduledDates(
                $request->start_date,
                $endDate,
                $request->service_frequency,
                $request->frequency_interval_value,
                $request->first_visit_rule ?? 'start_date',
                $request->custom_first_visit_date,
                $request->visit_count_type ?? 'automatic',
                $request->included_visit_count
            );

            return $this->successResponse([
                'start_date' => $request->start_date,
                'end_date' => $endDate,
                'total_scheduled_visits' => count($visits),
                'scheduled_dates' => $visits,
            ]);
        } catch (\Exception $e) {
            return $this->errorResponse($e->getMessage(), null, 422);
        }
    }

    /**
     * List contracts with search and filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Contract::query();

        if ($request->user()->isCustomer()) {
            $query->where('customer_id', $request->user()->customer_id);
        } elseif ($customerId = $request->get('customer_id')) {
            $query->where('customer_id', $customerId);
        }

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        // Expiring cohort filter (0-7, 8-30, 31-60, 61-90 days)
        if ($cohort = $request->get('expiry_cohort')) {
            $today = now()->startOfDay();
            [$minDays, $maxDays] = match ($cohort) {
                '0-7' => [0, 7],
                '8-30' => [8, 30],
                '31-60' => [31, 60],
                '61-90' => [61, 90],
                default => [0, 30],
            };
            $query->where('status', 'active')
                ->whereBetween('end_date', [
                    $today->copy()->addDays($minDays)->format('Y-m-d'),
                    $today->copy()->addDays($maxDays)->format('Y-m-d'),
                ]);
        }

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('contract_number', 'like', "%{$search}%")
                    ->orWhere('title', 'like', "%{$search}%")
                    ->orWhereHas('customer', function ($cq) use ($search) {
                        $cq->where('name', 'like', "%{$search}%")
                           ->orWhere('company_name', 'like', "%{$search}%");
                    });
            });
        }

        $perPage = (int) $request->get('per_page', 15);
        $contracts = $query->with(['customer', 'assets'])
            ->withCount(['serviceSchedules', 'serviceVisits'])
            ->latest()
            ->paginate($perPage);

        return $this->successResponse($contracts);
    }

    /**
     * Create new AMC contract and generate schedule.
     */
    public function store(Request $request): JsonResponse
    {
        if ($request->user()->isCustomer()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $validated = $request->validate([
            'customer_id' => 'required|exists:customers,id',
            'asset_ids' => 'nullable|array',
            'asset_ids.*' => 'exists:assets,id',
            'title' => 'nullable|string|max:255',
            'start_date' => 'required|date',
            'duration_type' => 'required|string|in:1_month,3_months,6_months,12_months,24_months,custom',
            'custom_end_date' => 'nullable|date',
            'service_frequency' => 'required|string|in:weekly,biweekly,monthly,bimonthly,quarterly,four_monthly,half_yearly,yearly,custom_days,custom_months',
            'frequency_interval_value' => 'nullable|integer|min:1',
            'first_visit_rule' => 'nullable|string|in:start_date,after_interval,custom_date',
            'custom_first_visit_date' => 'nullable|date',
            'visit_count_type' => 'nullable|string|in:automatic,fixed,custom',
            'included_visit_count' => 'nullable|integer|min:1',
            'total_price' => 'required|numeric|min:0',
            'billing_type' => 'nullable|string|in:fixed,recurring,installments',
            'coverage_parts' => 'nullable|string|in:included,excluded,partial',
            'coverage_emergency_visits' => 'nullable|string|in:included,chargeable',
            'coverage_breakdown_visits' => 'nullable|string|in:included,chargeable',
            'coverage_labour' => 'nullable|string|in:included,chargeable',
            'custom_coverage_terms' => 'nullable|string',
            'exclusions' => 'nullable|string',
            'sla_response_time' => 'nullable|string',
            'sla_response_hours' => 'nullable|integer',
            'payment_terms' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $company = $request->user()->company;

        // Calculate end date
        $endDate = $this->calculationService->calculateEndDate(
            $validated['start_date'],
            $validated['duration_type'],
            $validated['custom_end_date'] ?? null
        );

        $contractNumber = NumberingService::nextContractNumber($company);

        return DB::transaction(function () use ($company, $validated, $contractNumber, $endDate) {
            $contractData = array_merge($validated, [
                'company_id' => $company->id,
                'contract_number' => $contractNumber,
                'end_date' => $endDate,
                'status' => 'payment_requested',
            ]);
            unset($contractData['asset_ids'], $contractData['custom_end_date']);

            $contract = Contract::create($contractData);

            // Attach covered assets if provided
            if (!empty($validated['asset_ids'])) {
                $contract->assets()->sync($validated['asset_ids']);
            }

            // Create issued invoice for the AMC contract payment request
            $invNum = NumberingService::nextInvoiceNumber($company);
            $taxRate = $company->tax_enabled ? ($company->default_tax_rate ?? 18.0) : 0.0;
            $totalPrice = (float) $contract->total_price;
            $subtotal = round($totalPrice / (1 + ($taxRate / 100)), 2);
            $taxAmount = round($totalPrice - $subtotal, 2);

            Invoice::create([
                'company_id' => $company->id,
                'customer_id' => $contract->customer_id,
                'contract_id' => $contract->id,
                'invoice_number' => $invNum,
                'issue_date' => now()->format('Y-m-d'),
                'due_date' => now()->addDays(7)->format('Y-m-d'),
                'subtotal' => $subtotal,
                'taxable_amount' => $subtotal,
                'tax_rate' => $taxRate,
                'tax_amount' => $taxAmount,
                'total_amount' => $totalPrice,
                'paid_amount' => 0.00,
                'balance_due' => $totalPrice,
                'status' => 'issued',
                'notes' => "Payment Request for AMC Contract {$contractNumber}",
            ]);

            // Notify Customer User(s)
            $customerUsers = User::where('customer_id', $contract->customer_id)->get();
            foreach ($customerUsers as $cUser) {
                Notification::create([
                    'company_id' => $company->id,
                    'user_id' => $cUser->id,
                    'related_entity_type' => 'Contract',
                    'related_entity_id' => $contract->id,
                    'type' => 'payment_request',
                    'title' => "New AMC Contract: Payment Requested",
                    'message' => "A new AMC contract ({$contractNumber}) for ₹" . number_format($totalPrice, 2) . " has been issued. Please review and complete payment to activate.",
                ]);
            }

            AuditLogService::log('contract_created_payment_requested', $contract);

            return $this->successResponse(
                $contract->load(['customer', 'assets', 'invoices']),
                'AMC Contract created. Payment request sent to client.',
                201
            );
        });
    }

    /**
     * Show contract.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $contract = Contract::with([
            'customer',
            'assets',
            'serviceSchedules.technician',
            'serviceVisits',
            'invoices.payments',
            'renewedFromContract',
        ])->findOrFail($id);

        if ($request->user()->isCustomer() && $request->user()->customer_id !== $contract->customer_id) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        return $this->successResponse($contract);
    }

    /**
     * Renew contract (preserves historical contract, creates clean new contract).
     */
    public function renew(Request $request, int $id): JsonResponse
    {
        if ($request->user()->isCustomer()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $oldContract = Contract::with('assets')->findOrFail($id);
        $company = $request->user()->company;

        $validated = $request->validate([
            'start_date' => 'required|date',
            'duration_type' => 'required|string|in:1_month,3_months,6_months,12_months,24_months,custom',
            'custom_end_date' => 'nullable|date',
            'service_frequency' => 'required|string',
            'frequency_interval_value' => 'nullable|integer',
            'first_visit_rule' => 'nullable|string',
            'custom_first_visit_date' => 'nullable|date',
            'visit_count_type' => 'nullable|string',
            'included_visit_count' => 'nullable|integer',
            'total_price' => 'required|numeric|min:0',
            'asset_ids' => 'required|array|min:1',
            'asset_ids.*' => 'exists:assets,id',
            'title' => 'nullable|string|max:255',
        ]);

        $newEndDate = $this->calculationService->calculateEndDate(
            $validated['start_date'],
            $validated['duration_type'],
            $validated['custom_end_date'] ?? null
        );

        $newContractNumber = NumberingService::nextContractNumber($company);

        return DB::transaction(function () use ($oldContract, $company, $validated, $newContractNumber, $newEndDate) {
            // Mark old contract as renewed
            $oldContract->status = 'renewed';
            $oldContract->save();

            $newContractData = array_merge($oldContract->only([
                'billing_type', 'recurring_period', 'coverage_parts', 'coverage_emergency_visits',
                'coverage_breakdown_visits', 'coverage_labour', 'custom_coverage_terms', 'exclusions',
                'sla_response_time', 'sla_response_hours', 'payment_terms', 'notes',
            ]), [
                'company_id' => $company->id,
                'customer_id' => $oldContract->customer_id,
                'contract_number' => $newContractNumber,
                'title' => $validated['title'] ?: ($oldContract->title . ' (Renewed)'),
                'start_date' => $validated['start_date'],
                'end_date' => $newEndDate,
                'duration_type' => $validated['duration_type'],
                'service_frequency' => $validated['service_frequency'],
                'frequency_interval_value' => $validated['frequency_interval_value'] ?? null,
                'first_visit_rule' => $validated['first_visit_rule'] ?? 'start_date',
                'custom_first_visit_date' => $validated['custom_first_visit_date'] ?? null,
                'visit_count_type' => $validated['visit_count_type'] ?? 'automatic',
                'included_visit_count' => $validated['included_visit_count'] ?? null,
                'total_price' => $validated['total_price'],
                'status' => 'active',
                'renewed_from_contract_id' => $oldContract->id,
            ]);

            $newContract = Contract::create($newContractData);
            $newContract->assets()->sync($validated['asset_ids']);

            // Generate new schedule
            $dates = $this->calculationService->generateScheduledDates(
                $newContract->start_date->format('Y-m-d'),
                $newContract->end_date->format('Y-m-d'),
                $newContract->service_frequency,
                $newContract->frequency_interval_value,
                $newContract->first_visit_rule,
                $newContract->custom_first_visit_date?->format('Y-m-d'),
                $newContract->visit_count_type,
                $newContract->included_visit_count
            );

            foreach ($dates as $visitDate) {
                ServiceSchedule::create([
                    'company_id' => $company->id,
                    'contract_id' => $newContract->id,
                    'customer_id' => $newContract->customer_id,
                    'asset_id' => $validated['asset_ids'][0] ?? null,
                    'scheduled_date' => $visitDate,
                    'scheduled_time_start' => '10:00:00',
                    'scheduled_time_end' => '12:00:00',
                    'visit_type' => 'amc_preventive',
                    'status' => 'scheduled',
                    'priority' => 'normal',
                ]);
            }

            AuditLogService::log('contract_renewed', $newContract, ['previous_contract_id' => $oldContract->id]);

            return $this->successResponse(
                $newContract->load(['customer', 'assets', 'serviceSchedules']),
                'Contract successfully renewed into a new AMC contract. Previous contract preserved in history.'
            );
        });
    }

    /**
     * Customer requests contract renewal with duration and notes.
     */
    public function requestRenewal(Request $request, int $id): JsonResponse
    {
        $contract = Contract::with(['customer', 'assets'])->findOrFail($id);

        if ($request->user()->isCustomer()) {
            if ($contract->customer_id !== $request->user()->customer_id) {
                return $this->errorResponse('Unauthorized.', null, 403);
            }
        }

        $validated = $request->validate([
            'duration_type' => 'nullable|string|in:1_month,3_months,6_months,12_months,24_months,custom',
            'preferred_start_date' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        $contract->renewal_status = 'requested';
        $contract->renewal_duration_type = $validated['duration_type'] ?? '12_months';
        $contract->renewal_preferred_start_date = $validated['preferred_start_date'] ?? $contract->end_date->addDay()->format('Y-m-d');
        $contract->renewal_notes = $validated['notes'] ?? null;
        $contract->renewal_requested_at = now();
        $contract->save();

        AuditLogService::log('contract_renewal_requested', $contract, null, null, [
            'duration_type' => $contract->renewal_duration_type,
            'notes' => $contract->renewal_notes,
        ]);

        return $this->successResponse(
            $contract->fresh(['customer', 'assets']),
            'Renewal request submitted successfully. The administrator will review and provide your renewal quote.'
        );
    }

    /**
     * Admin sets the price quote for a requested renewal.
     */
    public function quoteRenewal(Request $request, int $id): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return $this->errorResponse('Only administrators can set contract renewal quotes.', null, 403);
        }

        $contract = Contract::with(['customer', 'assets'])->findOrFail($id);

        $validated = $request->validate([
            'quoted_price' => 'required|numeric|min:0',
            'quoted_notes' => 'nullable|string|max:1000',
        ]);

        $contract->renewal_status = 'quoted';
        $contract->renewal_quoted_price = $validated['quoted_price'];
        $contract->renewal_quoted_notes = $validated['quoted_notes'] ?? null;
        $contract->renewal_quoted_at = now();
        $contract->save();

        AuditLogService::log('contract_renewal_quoted', $contract, null, null, [
            'quoted_price' => $contract->renewal_quoted_price,
            'notes' => $contract->renewal_quoted_notes,
        ]);

        return $this->successResponse(
            $contract->fresh(['customer', 'assets']),
            'Renewal price quote submitted successfully. Customer can now view and pay directly.'
        );
    }

    /**
     * Customer views final price and directly pays to activate the renewed contract.
     */
    public function acceptRenewal(Request $request, int $id): JsonResponse
    {
        $oldContract = Contract::with(['assets', 'customer'])->findOrFail($id);

        if ($request->user()->isCustomer()) {
            if ($oldContract->customer_id !== $request->user()->customer_id) {
                return $this->errorResponse('Unauthorized.', null, 403);
            }
        }

        if ($oldContract->renewal_status !== 'quoted') {
            return $this->errorResponse('This contract does not have a pending renewal quote ready for payment.', null, 422);
        }

        $company = $request->user()->company;
        $startDate = $oldContract->renewal_preferred_start_date 
            ? $oldContract->renewal_preferred_start_date->format('Y-m-d')
            : $oldContract->end_date->addDay()->format('Y-m-d');
        $durationType = $oldContract->renewal_duration_type ?: '12_months';
        $totalPrice = $oldContract->renewal_quoted_price ?? $oldContract->total_price;

        $newEndDate = $this->calculationService->calculateEndDate(
            $startDate,
            $durationType,
            null
        );

        $newContractNumber = NumberingService::nextContractNumber($company);

        return DB::transaction(function () use ($oldContract, $company, $newContractNumber, $startDate, $newEndDate, $durationType, $totalPrice) {
            // 1. Mark old contract as renewed
            $oldContract->status = 'renewed';
            $oldContract->renewal_status = 'renewed';
            $oldContract->save();

            // 2. Create the new contract
            $newContractData = array_merge($oldContract->only([
                'billing_type', 'recurring_period', 'coverage_parts', 'coverage_emergency_visits',
                'coverage_breakdown_visits', 'coverage_labour', 'custom_coverage_terms', 'exclusions',
                'sla_response_time', 'sla_response_hours', 'payment_terms',
            ]), [
                'company_id' => $company->id,
                'customer_id' => $oldContract->customer_id,
                'contract_number' => $newContractNumber,
                'title' => $oldContract->title . ' (Renewed)',
                'start_date' => $startDate,
                'end_date' => $newEndDate,
                'duration_type' => $durationType,
                'service_frequency' => $oldContract->service_frequency,
                'frequency_interval_value' => $oldContract->frequency_interval_value,
                'first_visit_rule' => $oldContract->first_visit_rule ?: 'start_date',
                'visit_count_type' => $oldContract->visit_count_type ?: 'automatic',
                'included_visit_count' => $oldContract->included_visit_count,
                'total_price' => $totalPrice,
                'status' => 'active',
                'renewal_status' => 'none',
                'renewed_from_contract_id' => $oldContract->id,
                'notes' => $oldContract->renewal_notes ?: 'Renewed AMC contract.',
            ]);

            $newContract = Contract::create($newContractData);
            $assetIds = $oldContract->assets->pluck('id')->toArray();
            $newContract->assets()->sync($assetIds);

            // 3. Generate new maintenance schedule dates
            $dates = $this->calculationService->generateScheduledDates(
                $newContract->start_date->format('Y-m-d'),
                $newContract->end_date->format('Y-m-d'),
                $newContract->service_frequency,
                $newContract->frequency_interval_value,
                $newContract->first_visit_rule,
                null,
                $newContract->visit_count_type,
                $newContract->included_visit_count
            );

            foreach ($dates as $visitDate) {
                ServiceSchedule::create([
                    'company_id' => $company->id,
                    'contract_id' => $newContract->id,
                    'customer_id' => $newContract->customer_id,
                    'asset_id' => $assetIds[0] ?? null,
                    'scheduled_date' => $visitDate,
                    'scheduled_time_start' => '10:00:00',
                    'scheduled_time_end' => '12:00:00',
                    'visit_type' => 'amc_preventive',
                    'status' => 'scheduled',
                    'priority' => 'normal',
                ]);
            }

            // 4. Create paid invoice & payment record for this renewal
            $invNum = NumberingService::nextInvoiceNumber($company);
            $taxRate = $company->tax_enabled ? ($company->default_tax_rate ?? 18.0) : 0.0;
            $subtotal = round($totalPrice / (1 + ($taxRate / 100)), 2);
            $taxAmount = round($totalPrice - $subtotal, 2);

            $invoice = Invoice::create([
                'company_id' => $company->id,
                'customer_id' => $newContract->customer_id,
                'contract_id' => $newContract->id,
                'invoice_number' => $invNum,
                'issue_date' => now()->format('Y-m-d'),
                'due_date' => now()->format('Y-m-d'),
                'subtotal' => $subtotal,
                'taxable_amount' => $subtotal,
                'tax_rate' => $taxRate,
                'tax_amount' => $taxAmount,
                'total_amount' => $totalPrice,
                'paid_amount' => $totalPrice,
                'balance_due' => 0.00,
                'status' => 'paid',
                'notes' => "AMC Contract Renewal Payment for {$newContractNumber}",
            ]);

            Payment::create([
                'company_id' => $company->id,
                'customer_id' => $newContract->customer_id,
                'invoice_id' => $invoice->id,
                'payment_number' => NumberingService::nextPaymentNumber($company),
                'amount' => $totalPrice,
                'payment_date' => now()->format('Y-m-d'),
                'payment_method' => 'online',
                'reference_number' => 'RENEW-' . strtoupper(substr(uniqid(), -6)),
                'status' => 'completed',
                'notes' => 'Instant AMC Contract renewal payment',
            ]);

            AuditLogService::log('contract_renewal_paid_and_activated', $newContract, [
                'previous_contract_id' => $oldContract->id,
                'invoice_id' => $invoice->id,
                'amount_paid' => $totalPrice,
            ]);

            return $this->successResponse(
                $newContract->load(['customer', 'assets', 'serviceSchedules']),
                'Contract successfully renewed and activated! Payment receipt and scheduled service dates are ready.'
            );
        });
    }

    /**
     * Customer pays & activates contract.
     */
    public function payContract(Request $request, int $id): JsonResponse
    {
        $contract = Contract::with(['customer', 'assets'])->findOrFail($id);

        if ($request->user()->isCustomer() && $request->user()->customer_id !== $contract->customer_id) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $validated = $request->validate([
            'payment_method' => 'nullable|string|in:upi,net_banking,card,cheque,cash,online',
            'notes' => 'nullable|string',
        ]);

        $paymentMethod = $validated['payment_method'] ?? 'upi';
        $company = $contract->company;

        return DB::transaction(function () use ($contract, $company, $paymentMethod) {
            $contract->status = 'active';
            $contract->save();

            // Generate schedule dates and service schedules if none exist
            if ($contract->serviceSchedules()->count() === 0) {
                $dates = $this->calculationService->generateScheduledDates(
                    $contract->start_date->format('Y-m-d'),
                    $contract->end_date->format('Y-m-d'),
                    $contract->service_frequency,
                    $contract->frequency_interval_value,
                    $contract->first_visit_rule,
                    $contract->custom_first_visit_date?->format('Y-m-d'),
                    $contract->visit_count_type,
                    $contract->included_visit_count
                );

                $firstAssetId = $contract->assets->first()?->id;

                foreach ($dates as $visitDate) {
                    ServiceSchedule::create([
                        'company_id' => $contract->company_id,
                        'contract_id' => $contract->id,
                        'customer_id' => $contract->customer_id,
                        'asset_id' => $firstAssetId,
                        'scheduled_date' => $visitDate,
                        'scheduled_time_start' => '10:00:00',
                        'scheduled_time_end' => '12:00:00',
                        'visit_type' => 'amc_preventive',
                        'status' => 'scheduled',
                        'priority' => 'normal',
                    ]);
                }
            }

            // Find or create invoice & mark paid
            $invoice = $contract->invoices()->latest()->first();
            if (!$invoice) {
                $taxRate = $company->tax_enabled ? ($company->default_tax_rate ?? 18.0) : 0.0;
                $totalPrice = (float) $contract->total_price;
                $subtotal = round($totalPrice / (1 + ($taxRate / 100)), 2);
                $taxAmount = round($totalPrice - $subtotal, 2);

                $invoice = Invoice::create([
                    'company_id' => $contract->company_id,
                    'customer_id' => $contract->customer_id,
                    'contract_id' => $contract->id,
                    'invoice_number' => NumberingService::nextInvoiceNumber($company),
                    'issue_date' => now()->format('Y-m-d'),
                    'due_date' => now()->format('Y-m-d'),
                    'subtotal' => $subtotal,
                    'taxable_amount' => $subtotal,
                    'tax_rate' => $taxRate,
                    'tax_amount' => $taxAmount,
                    'total_amount' => $totalPrice,
                    'paid_amount' => $totalPrice,
                    'balance_due' => 0.00,
                    'status' => 'paid',
                    'notes' => "AMC Contract Payment for {$contract->contract_number}",
                ]);
            } else {
                $invoice->update([
                    'status' => 'paid',
                    'paid_amount' => $invoice->total_amount,
                    'balance_due' => 0.00,
                ]);
            }

            // Create Payment record
            Payment::create([
                'company_id' => $contract->company_id,
                'customer_id' => $contract->customer_id,
                'invoice_id' => $invoice->id,
                'payment_number' => NumberingService::nextPaymentNumber($company),
                'amount' => $invoice->total_amount,
                'payment_date' => now()->format('Y-m-d'),
                'payment_method' => $paymentMethod,
                'reference_number' => 'PAY-' . strtoupper(substr(uniqid(), -6)),
                'status' => 'completed',
                'notes' => 'AMC Contract payment via ' . strtoupper($paymentMethod),
            ]);

            // Notify Admin
            $admins = User::where('company_id', $contract->company_id)->where('role', 'admin')->get();
            foreach ($admins as $admin) {
                Notification::create([
                    'company_id' => $contract->company_id,
                    'user_id' => $admin->id,
                    'related_entity_type' => 'Contract',
                    'related_entity_id' => $contract->id,
                    'type' => 'contract_paid',
                    'title' => "Contract Payment Received: {$contract->contract_number}",
                    'message' => "Client {$contract->customer->name} paid ₹" . number_format($contract->total_price, 2) . " via " . strtoupper($paymentMethod) . ". AMC is now active.",
                ]);
            }

            AuditLogService::log('contract_payment_completed', $contract, [
                'payment_method' => $paymentMethod,
                'amount' => $contract->total_price,
            ]);

            return $this->successResponse(
                $contract->load(['customer', 'assets', 'serviceSchedules', 'invoices.payments']),
                'Payment successful! AMC Contract is now active.'
            );
        });
    }

    /**
     * Customer declines payment request for contract.
     */
    public function declinePayment(Request $request, int $id): JsonResponse
    {
        $contract = Contract::with(['customer'])->findOrFail($id);

        if ($request->user()->isCustomer() && $request->user()->customer_id !== $contract->customer_id) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $reason = $request->input('reason', 'Payment declined by client');

        $contract->status = 'payment_declined';
        $contract->save();

        // Update invoice if any
        $contract->invoices()->update(['status' => 'cancelled']);

        // Notify Admin
        $admins = User::where('company_id', $contract->company_id)->where('role', 'admin')->get();
        foreach ($admins as $admin) {
            Notification::create([
                'company_id' => $contract->company_id,
                'user_id' => $admin->id,
                'related_entity_type' => 'Contract',
                'related_entity_id' => $contract->id,
                'type' => 'payment_declined',
                'title' => "Payment Declined: {$contract->contract_number}",
                'message' => "Client {$contract->customer->name} declined the AMC payment request. Reason: {$reason}",
            ]);
        }

        AuditLogService::log('contract_payment_declined', $contract, ['reason' => $reason]);

        return $this->successResponse(
            $contract,
            'Payment request declined.'
        );
    }
}
