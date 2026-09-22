<?php

namespace App\Services;

use Carbon\Carbon;

class ContractCalculationService
{
    /**
     * Calculate contract end date from start date and duration type.
     * Preset rule:
     * - 1 Month: Start date + 1 month minus 1 day (e.g., 2026-09-17 -> 2026-10-16).
     * - 3 Months: Start date + 3 months minus 1 day (e.g., 2026-09-17 -> 2026-12-16).
     * - Month-end rule: If starting Jan 31 + 1 month -> Feb 28 (or Feb 29 in leap year).
     */
    public function calculateEndDate(string $startDateStr, string $durationType, ?string $customEndDateStr = null): string
    {
        if ($durationType === 'custom') {
            if (empty($customEndDateStr)) {
                throw new \InvalidArgumentException('Custom end date must be specified for custom duration.');
            }
            $startDate = Carbon::parse($startDateStr)->startOfDay();
            $endDate = Carbon::parse($customEndDateStr)->startOfDay();
            if ($endDate->lessThanOrEqualTo($startDate)) {
                throw new \InvalidArgumentException('Contract end date must be strictly after start date.');
            }
            return $endDate->format('Y-m-d');
        }

        $start = Carbon::parse($startDateStr)->startOfDay();
        $months = match ($durationType) {
            '1_month' => 1,
            '3_months' => 3,
            '6_months' => 6,
            '12_months' => 12,
            '24_months' => 24,
            default => throw new \InvalidArgumentException("Unsupported duration type: {$durationType}"),
        };

        // Standard date arithmetic: add months with overflow prevention, then subtract 1 day
        // Carbon's addMonthsNoOverflow handles month-end correctly:
        // Jan 31 + 1 month NoOverflow = Feb 28.
        $target = $start->copy()->addMonthsNoOverflow($months);
        $end = $target->subDay();

        return $end->format('Y-m-d');
    }

    /**
     * Calculate scheduled visit dates for a contract.
     */
    public function generateScheduledDates(
        string $startDateStr,
        string $endDateStr,
        string $frequency,
        ?int $customIntervalValue = null,
        string $firstVisitRule = 'start_date',
        ?string $customFirstVisitDateStr = null,
        string $visitCountType = 'automatic',
        ?int $includedVisitCount = null
    ): array {
        $startDate = Carbon::parse($startDateStr)->startOfDay();
        $endDate = Carbon::parse($endDateStr)->startOfDay();

        if ($endDate->lessThan($startDate)) {
            return [];
        }

        $dates = [];

        // 1. Determine first visit date
        $current = match ($firstVisitRule) {
            'start_date' => $startDate->copy(),
            'after_interval' => $this->addInterval($startDate->copy(), $frequency, $customIntervalValue),
            'custom_date' => !empty($customFirstVisitDateStr)
                ? Carbon::parse($customFirstVisitDateStr)->startOfDay()
                : $startDate->copy(),
            default => $startDate->copy(),
        };

        $maxVisits = ($visitCountType === 'fixed' && $includedVisitCount !== null && $includedVisitCount > 0)
            ? $includedVisitCount
            : PHP_INT_MAX;

        // 2. Loop until past end date or reaching max visit limit
        while ($current->lessThanOrEqualTo($endDate) && count($dates) < $maxVisits) {
            if ($current->greaterThanOrEqualTo($startDate)) {
                $dates[] = $current->format('Y-m-d');
            }

            $next = $this->addInterval($current->copy(), $frequency, $customIntervalValue);

            // Guard against infinite loop if interval is 0 or doesn't advance
            if ($next->lessThanOrEqualTo($current)) {
                break;
            }

            $current = $next;
        }

        return $dates;
    }

    /**
     * Add frequency interval to given date.
     */
    protected function addInterval(Carbon $date, string $frequency, ?int $customValue = null): Carbon
    {
        return match ($frequency) {
            'weekly' => $date->addWeeks(1),
            'biweekly' => $date->addWeeks(2),
            'monthly' => $date->addMonthsNoOverflow(1),
            'bimonthly' => $date->addMonthsNoOverflow(2),
            'quarterly' => $date->addMonthsNoOverflow(3),
            'four_monthly' => $date->addMonthsNoOverflow(4),
            'half_yearly' => $date->addMonthsNoOverflow(6),
            'yearly' => $date->addYearsNoOverflow(1),
            'custom_days' => $date->addDays(max(1, $customValue ?? 30)),
            'custom_months' => $date->addMonthsNoOverflow(max(1, $customValue ?? 1)),
            default => $date->addMonthsNoOverflow(3),
        };
    }
}
