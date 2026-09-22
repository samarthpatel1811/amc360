<?php

namespace App\Console\Commands;

use App\Models\Contract;
use App\Models\Invoice;
use App\Models\Notification;
use App\Models\ServiceSchedule;
use App\Models\User;
use Illuminate\Console\Command;

class ProcessContractExpiries extends Command
{
    protected $signature = 'amc360:process-maintenance-schedules';
    protected $description = 'Process contract expiries, identify contracts expiring soon, and flag overdue visits.';

    public function handle(): int
    {
        $today = now()->toDateString();

        // 1. Mark expired contracts
        $expiredCount = Contract::where('status', 'active')
            ->where('end_date', '<', $today)
            ->update(['status' => 'expired']);

        $this->info("Marked {$expiredCount} contracts as expired.");

        // 2. Identify contracts expiring within 7 days and notify company admin
        $expiringContracts = Contract::where('status', 'active')
            ->whereBetween('end_date', [$today, now()->addDays(7)->toDateString()])
            ->with(['company', 'customer'])
            ->get();

        foreach ($expiringContracts as $contract) {
            $admins = User::where('company_id', $contract->company_id)
                ->where('role', 'admin')
                ->get();

            foreach ($admins as $admin) {
                Notification::firstOrCreate([
                    'company_id' => $contract->company_id,
                    'user_id' => $admin->id,
                    'related_entity_type' => 'Contract',
                    'related_entity_id' => $contract->id,
                    'type' => 'contract_expiry',
                ], [
                    'title' => "Contract Expiring Soon: {$contract->contract_number}",
                    'message' => "Contract for {$contract->customer->name} expires on {$contract->end_date->format('d M Y')}. Please review for renewal.",
                ]);
            }
        }

        // 3. Mark overdue unpaid invoices
        $overdueInvoices = Invoice::whereIn('status', ['issued', 'partially_paid'])
            ->where('due_date', '<', $today)
            ->update(['status' => 'overdue']);

        $this->info("Updated {$overdueInvoices} invoices to overdue.");

        return Command::SUCCESS;
    }
}
