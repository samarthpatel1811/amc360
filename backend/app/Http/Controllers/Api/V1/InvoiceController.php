<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Customer;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Services\AuditLogService;
use App\Services\InvoiceCalculationService;
use App\Services\NumberingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InvoiceController extends BaseApiController
{
    public function __construct(
        protected InvoiceCalculationService $calculationService
    ) {}

    /**
     * List invoices.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Invoice::query();

        if ($request->user()->isCustomer()) {
            $query->where('customer_id', $request->user()->customer_id);
        } elseif ($customerId = $request->get('customer_id')) {
            $query->where('customer_id', $customerId);
        }

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('invoice_number', 'like', "%{$search}%")
                    ->orWhereHas('customer', function ($cq) use ($search) {
                        $cq->where('name', 'like', "%{$search}%")
                           ->orWhere('company_name', 'like', "%{$search}%");
                    });
            });
        }

        $invoices = $query->with(['customer', 'contract', 'payments'])
            ->latest('issue_date')
            ->paginate((int) $request->get('per_page', 20));

        return $this->successResponse($invoices);
    }

    /**
     * Store new manual or AMC invoice.
     */
    public function store(Request $request): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $validated = $request->validate([
            'customer_id' => 'required|exists:customers,id',
            'contract_id' => 'nullable|exists:contracts,id',
            'invoice_type' => 'nullable|string|in:amc,service,parts,extra_visit,combined',
            'issue_date' => 'required|date',
            'due_date' => 'required|date',
            'discount_amount' => 'nullable|numeric|min:0',
            'discount_type' => 'nullable|string|in:fixed,percentage',
            'tax_rate' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.description' => 'required|string|max:255',
            'items.*.item_type' => 'nullable|string',
            'items.*.quantity' => 'required|numeric|min:0.01',
            'items.*.unit_price' => 'required|numeric|min:0',
        ]);

        $company = $request->user()->company;
        $subtotal = 0;

        foreach ($validated['items'] as $item) {
            $subtotal += round($item['quantity'] * $item['unit_price'], 2);
        }

        $taxRate = $validated['tax_rate'] ?? $company->default_tax_rate;
        $totals = $this->calculationService->calculateTotals(
            subtotal: $subtotal,
            discountAmount: (float) ($validated['discount_amount'] ?? 0.0),
            discountType: $validated['discount_type'] ?? 'fixed',
            taxRate: (float) $taxRate,
            paidAmount: 0.0
        );

        $invoiceNumber = NumberingService::nextInvoiceNumber($company);

        return DB::transaction(function () use ($company, $validated, $totals, $invoiceNumber) {
            $invoice = Invoice::create([
                'company_id' => $company->id,
                'customer_id' => $validated['customer_id'],
                'contract_id' => $validated['contract_id'] ?? null,
                'invoice_number' => $invoiceNumber,
                'invoice_type' => $validated['invoice_type'] ?? 'service',
                'issue_date' => $validated['issue_date'],
                'due_date' => $validated['due_date'],
                'subtotal' => $totals['subtotal'],
                'discount_amount' => $totals['discount_amount'],
                'discount_type' => $validated['discount_type'] ?? 'fixed',
                'taxable_amount' => $totals['taxable_amount'],
                'tax_rate' => $totals['tax_rate'],
                'tax_amount' => $totals['tax_amount'],
                'total_amount' => $totals['total_amount'],
                'paid_amount' => 0.00,
                'balance_due' => $totals['total_amount'],
                'status' => 'issued',
                'notes' => $validated['notes'] ?? null,
            ]);

            foreach ($validated['items'] as $item) {
                InvoiceItem::create([
                    'invoice_id' => $invoice->id,
                    'description' => $item['description'],
                    'item_type' => $item['item_type'] ?? 'custom',
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['unit_price'],
                    'total_price' => round($item['quantity'] * $item['unit_price'], 2),
                ]);
            }

            AuditLogService::log('invoice_created', $invoice);

            return $this->successResponse($invoice->load(['customer', 'items']), 'Invoice created successfully.', 201);
        });
    }

    /**
     * Show invoice.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $invoice = Invoice::with(['customer', 'contract', 'items', 'payments.recordedBy'])->findOrFail($id);

        if ($request->user()->isCustomer() && $request->user()->customer_id !== $invoice->customer_id) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        return $this->successResponse($invoice);
    }
}
