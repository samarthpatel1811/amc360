<?php

namespace Tests\Unit;

use App\Services\InvoiceCalculationService;
use PHPUnit\Framework\TestCase;

class InvoiceCalculationServiceTest extends TestCase
{
    private InvoiceCalculationService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new InvoiceCalculationService();
    }

    /**
     * Section 107 financial test:
     * Subtotal = ₹10,000, Discount = ₹1,000, Tax = 18%
     * Taxable = ₹9,000, Tax = ₹1,620, Total = ₹10,620
     * Payment = ₹5,000 -> Balance = ₹5,620.
     */
    public function test_section_107_financial_formula(): void
    {
        $res = $this->service->calculateTotals(
            subtotal: 10000.00,
            discountAmount: 1000.00,
            discountType: 'fixed',
            taxRate: 18.00,
            paidAmount: 5000.00
        );

        $this->assertEquals(10000.00, $res['subtotal']);
        $this->assertEquals(1000.00, $res['discount_amount']);
        $this->assertEquals(9000.00, $res['taxable_amount']);
        $this->assertEquals(1620.00, $res['tax_amount']);
        $this->assertEquals(10620.00, $res['total_amount']);
        $this->assertEquals(5000.00, $res['paid_amount']);
        $this->assertEquals(5620.00, $res['balance_due']);
        $this->assertEquals('partially_paid', $res['status']);
    }

    public function test_paid_in_full(): void
    {
        $res = $this->service->calculateTotals(
            subtotal: 5000.00,
            discountAmount: 0.00,
            discountType: 'fixed',
            taxRate: 18.00,
            paidAmount: 5900.00
        );

        $this->assertEquals(5900.00, $res['total_amount']);
        $this->assertEquals(0.00, $res['balance_due']);
        $this->assertEquals('paid', $res['status']);
    }
}
