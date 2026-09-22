<?php

namespace Tests\Unit;

use App\Services\ContractCalculationService;
use PHPUnit\Framework\TestCase;

class ContractCalculationServiceTest extends TestCase
{
    private ContractCalculationService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new ContractCalculationService();
    }

    /**
     * Case 1: Start 17/09/2026, 1 month -> Expected end 16/10/2026.
     */
    public function test_case_1_one_month_contract_duration(): void
    {
        $endDate = $this->service->calculateEndDate('2026-09-17', '1_month');
        $this->assertEquals('2026-10-16', $endDate);
    }

    /**
     * Case 2: Start 17/09/2026, 3 months -> Expected end 16/12/2026.
     */
    public function test_case_2_three_month_contract_duration(): void
    {
        $endDate = $this->service->calculateEndDate('2026-09-17', '3_months');
        $this->assertEquals('2026-12-16', $endDate);
    }

    /**
     * Case 3: Start 31/01/2027, 1 month -> Valid month-end handling (February).
     */
    public function test_case_3_month_end_date_handling(): void
    {
        $endDate = $this->service->calculateEndDate('2027-01-31', '1_month');
        // Jan 31 + 1 month (no overflow) = Feb 28, sub 1 day = Feb 27
        $this->assertMatchesRegularExpression('/^2027-02-(27|28)$/', $endDate);
    }

    /**
     * Case 4: Custom duration 17/09/2026 -> 16/02/2027.
     */
    public function test_case_4_custom_duration(): void
    {
        $endDate = $this->service->calculateEndDate('2026-09-17', 'custom', '2027-02-16');
        $this->assertEquals('2027-02-16', $endDate);
    }

    /**
     * Case 5: 12-month contract + quarterly frequency -> exactly valid visits within bounds.
     */
    public function test_case_5_twelve_month_quarterly_visits(): void
    {
        $startDate = '2026-09-17';
        $endDate = $this->service->calculateEndDate($startDate, '12_months'); // 2027-09-16

        $visits = $this->service->generateScheduledDates(
            $startDate,
            $endDate,
            'quarterly',
            null,
            'start_date'
        );

        // For 12-month contract with visits starting on day 1 and every 3 months:
        // Month 0 (2026-09-17), Month 3 (2026-12-17), Month 6 (2027-03-17), Month 9 (2027-06-17).
        // Month 12 (2027-09-17) is outside contract (which ends 2027-09-16).
        $this->assertCount(4, $visits);
        $this->assertEquals('2026-09-17', $visits[0]);
        $this->assertEquals('2026-12-17', $visits[1]);
        $this->assertEquals('2027-03-17', $visits[2]);
        $this->assertEquals('2027-06-17', $visits[3]);

        foreach ($visits as $visitDate) {
            $this->assertTrue(strtotime($visitDate) >= strtotime($startDate));
            $this->assertTrue(strtotime($visitDate) <= strtotime($endDate));
        }
    }

    /**
     * Case 6: Fixed visit count of 7 -> no more than 7 visits created.
     */
    public function test_case_6_fixed_visit_count_cap(): void
    {
        $startDate = '2026-01-01';
        $endDate = '2027-12-31'; // 24 months

        // Monthly frequency would naturally generate 24 visits, but fixed cap is 7
        $visits = $this->service->generateScheduledDates(
            $startDate,
            $endDate,
            'monthly',
            null,
            'start_date',
            null,
            'fixed',
            7
        );

        $this->assertCount(7, $visits);
    }
}
