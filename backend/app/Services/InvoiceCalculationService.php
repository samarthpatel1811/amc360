<?php

namespace App\Services;

class InvoiceCalculationService
{
    /**
     * Calculate invoice financial values:
     * Taxable = Subtotal - Discount (non-negative)
     * Tax = Taxable * (TaxRate / 100)
     * Total = Taxable + Tax
     * Balance = Total - Paid
     */
    public function calculateTotals(
        float $subtotal,
        float $discountAmount,
        string $discountType = 'fixed',
        float $taxRate = 18.00,
        float $paidAmount = 0.00
    ): array {
        $subtotal = max(0.00, round($subtotal, 2));

        // Calculate discount value
        $calculatedDiscount = match ($discountType) {
            'percentage' => round($subtotal * (min(100.0, max(0.0, $discountAmount)) / 100.0), 2),
            default => min($subtotal, max(0.00, round($discountAmount, 2))),
        };

        $taxableAmount = max(0.00, round($subtotal - $calculatedDiscount, 2));
        $taxAmount = round($taxableAmount * (max(0.00, $taxRate) / 100.0), 2);
        $totalAmount = round($taxableAmount + $taxAmount, 2);
        $paidAmount = max(0.00, round($paidAmount, 2));
        $balanceDue = max(0.00, round($totalAmount - $paidAmount, 2));

        $status = 'draft';
        if ($paidAmount >= $totalAmount && $totalAmount > 0) {
            $status = 'paid';
        } elseif ($paidAmount > 0 && $balanceDue > 0) {
            $status = 'partially_paid';
        } else {
            $status = 'issued';
        }

        return [
            'subtotal' => $subtotal,
            'discount_amount' => $calculatedDiscount,
            'taxable_amount' => $taxableAmount,
            'tax_rate' => $taxRate,
            'tax_amount' => $taxAmount,
            'total_amount' => $totalAmount,
            'paid_amount' => $paidAmount,
            'balance_due' => $balanceDue,
            'status' => $status,
        ];
    }
}
