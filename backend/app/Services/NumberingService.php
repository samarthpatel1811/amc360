<?php

namespace App\Services;

use App\Models\Company;
use App\Models\Customer;
use App\Models\Contract;
use App\Models\ServiceRequest;
use App\Models\ServiceVisit;
use App\Models\Invoice;
use App\Models\Payment;
use Illuminate\Support\Facades\DB;

class NumberingService
{
    public static function nextContractNumber(Company $company): string
    {
        $year = date('Y');
        $prefix = $company->contract_prefix ?: 'AMC-';
        $pattern = "{$prefix}{$year}-";

        $count = Contract::withoutGlobalScopes()
            ->where('company_id', $company->id)
            ->where('contract_number', 'like', "{$pattern}%")
            ->count();

        $seq = str_pad($count + 1, 6, '0', STR_PAD_LEFT);
        return "{$pattern}{$seq}";
    }

    public static function nextCustomerCode(Company $company): string
    {
        $prefix = $company->customer_prefix ?: 'CUST-';
        $count = Customer::withoutGlobalScopes()
            ->where('company_id', $company->id)
            ->count();

        $seq = str_pad($count + 1, 5, '0', STR_PAD_LEFT);
        return "{$prefix}{$seq}";
    }

    public static function nextServiceRequestNumber(Company $company): string
    {
        $year = date('Y');
        $prefix = $company->service_request_prefix ?: 'SR-';
        $pattern = "{$prefix}{$year}-";

        $count = ServiceRequest::withoutGlobalScopes()
            ->where('company_id', $company->id)
            ->where('request_number', 'like', "{$pattern}%")
            ->count();

        $seq = str_pad($count + 1, 6, '0', STR_PAD_LEFT);
        return "{$pattern}{$seq}";
    }

    public static function nextVisitNumber(Company $company): string
    {
        $year = date('Y');
        $prefix = $company->service_visit_prefix ?: 'VISIT-';
        $pattern = "{$prefix}{$year}-";

        $count = ServiceVisit::withoutGlobalScopes()
            ->where('company_id', $company->id)
            ->where('visit_number', 'like', "{$pattern}%")
            ->count();

        $seq = str_pad($count + 1, 6, '0', STR_PAD_LEFT);
        return "{$pattern}{$seq}";
    }

    public static function nextReportNumber(Company $company): string
    {
        $year = date('Y');
        $prefix = $company->service_report_prefix ?: 'SRPT-';
        $pattern = "{$prefix}{$year}-";

        $count = ServiceVisit::withoutGlobalScopes()
            ->where('company_id', $company->id)
            ->whereNotNull('report_number')
            ->where('report_number', 'like', "{$pattern}%")
            ->count();

        $seq = str_pad($count + 1, 6, '0', STR_PAD_LEFT);
        return "{$pattern}{$seq}";
    }

    public static function nextInvoiceNumber(Company $company): string
    {
        $year = date('Y');
        $prefix = $company->invoice_prefix ?: 'INV-';
        $pattern = "{$prefix}{$year}-";

        $count = Invoice::withoutGlobalScopes()
            ->where('company_id', $company->id)
            ->where('invoice_number', 'like', "{$pattern}%")
            ->count();

        $seq = str_pad($count + 1, 6, '0', STR_PAD_LEFT);
        return "{$pattern}{$seq}";
    }

    public static function nextPaymentNumber(Company $company): string
    {
        $year = date('Y');
        $prefix = $company->payment_prefix ?: 'PAY-';
        $pattern = "{$prefix}{$year}-";

        $count = Payment::withoutGlobalScopes()
            ->where('company_id', $company->id)
            ->where('payment_number', 'like', "{$pattern}%")
            ->count();

        $seq = str_pad($count + 1, 6, '0', STR_PAD_LEFT);
        return "{$pattern}{$seq}";
    }
}
