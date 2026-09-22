<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Invoice;
use App\Models\Payment;
use App\Services\AuditLogService;
use App\Services\NumberingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PaymentController extends BaseApiController
{
    /**
     * List payments.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Payment::query();

        if ($request->user()->isCustomer()) {
            $query->where('customer_id', $request->user()->customer_id);
        } elseif ($customerId = $request->get('customer_id')) {
            $query->where('customer_id', $customerId);
        }

        if ($invoiceId = $request->get('invoice_id')) {
            $query->where('invoice_id', $invoiceId);
        }

        $payments = $query->with(['customer', 'invoice', 'recordedBy'])
            ->latest('payment_date')
            ->paginate((int) $request->get('per_page', 20));

        return $this->successResponse($payments);
    }

    /**
     * Record payment against an invoice.
     */
    public function store(Request $request): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return $this->errorResponse('Unauthorized. Only admin can record payments.', null, 403);
        }

        $validated = $request->validate([
            'invoice_id' => 'required|exists:invoices,id',
            'amount' => 'required|numeric|min:0.01',
            'payment_date' => 'required|date',
            'payment_method' => 'required|string|in:cash,upi,bank_transfer,card,cheque,other',
            'transaction_reference' => 'nullable|string|max:100',
            'notes' => 'nullable|string',
        ]);

        $company = $request->user()->company;
        $invoice = Invoice::findOrFail($validated['invoice_id']);

        // Check overpayment validation
        if ($validated['amount'] > $invoice->balance_due) {
            return $this->errorResponse(
                "Payment amount ({$validated['amount']}) exceeds outstanding invoice balance ({$invoice->balance_due}).",
                null,
                422
            );
        }

        return DB::transaction(function () use ($company, $invoice, $validated, $request) {
            $paymentNumber = NumberingService::nextPaymentNumber($company);

            $payment = Payment::create([
                'company_id' => $company->id,
                'invoice_id' => $invoice->id,
                'customer_id' => $invoice->customer_id,
                'payment_number' => $paymentNumber,
                'amount' => $validated['amount'],
                'payment_date' => $validated['payment_date'],
                'payment_method' => $validated['payment_method'],
                'transaction_reference' => $validated['transaction_reference'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'recorded_by_user_id' => $request->user()->id,
            ]);

            // Model booted listener automatically calls $invoice->recalculateBalance()

            AuditLogService::log('payment_recorded', $payment);

            return $this->successResponse([
                'payment' => $payment->load(['customer', 'invoice']),
                'invoice' => $invoice->fresh(),
            ], 'Payment recorded successfully.', 201);
        });
    }
}
