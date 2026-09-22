<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Contract;
use App\Models\Customer;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\ServiceRequest;
use App\Models\ServiceSchedule;
use App\Models\ServiceVisit;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReportController extends BaseApiController
{
    /**
     * Role-aware Dashboard Summary.
     */
    public function dashboard(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->isCustomer()) {
            return $this->customerDashboard($user);
        }

        if ($user->isTechnician()) {
            return $this->technicianDashboard($user);
        }

        return $this->adminDashboard($request);
    }

    /**
     * Admin Dashboard.
     */
    protected function adminDashboard(Request $request): JsonResponse
    {
        $today = now()->toDateString();
        $range = $request->get('date_filter', 'all');

        $queryDateStart = null;
        if ($range === 'today') {
            $queryDateStart = now()->startOfDay();
        } elseif ($range === 'this_week') {
            $queryDateStart = now()->startOfWeek();
        } elseif ($range === 'this_month') {
            $queryDateStart = now()->startOfMonth();
        } elseif ($range === 'this_year') {
            $queryDateStart = now()->startOfYear();
        }

        // Contract metrics
        $contracts = Contract::query();
        $activeContracts = (clone $contracts)->where('status', 'active')->count();
        $expiredContracts = (clone $contracts)->where('status', 'expired')->count();
        $expiringSoon = (clone $contracts)
            ->where('status', 'active')
            ->whereBetween('end_date', [$today, now()->addDays(30)->toDateString()])
            ->count();

        // Service visit metrics
        $schedules = ServiceSchedule::query();
        $todayVisits = (clone $schedules)->where('scheduled_date', $today)->count();
        $upcomingVisits = (clone $schedules)->where('scheduled_date', '>', $today)->where('status', 'scheduled')->count();
        $overdueVisits = (clone $schedules)->where('scheduled_date', '<', $today)->where('status', 'scheduled')->count();
        $completedVisits = ServiceVisit::where('status', 'completed')->count();
        $openRequests = ServiceRequest::whereIn('status', ['new', 'assigned', 'in_progress', 'waiting_for_customer'])->count();

        // Financial metrics
        $totalContractValue = Contract::where('status', 'active')->sum('total_price');
        $totalInvoiced = Invoice::where('status', '!=', 'cancelled')->sum('total_amount');
        $amountCollected = Payment::sum('amount');
        $outstandingAmount = Invoice::whereIn('status', ['issued', 'partially_paid', 'overdue'])->sum('balance_due');
        $overdueAmount = Invoice::where('status', 'overdue')
            ->orWhere(function ($q) use ($today) {
                $q->whereIn('status', ['issued', 'partially_paid'])
                  ->where('due_date', '<', $today);
            })->sum('balance_due');

        // Technician metrics
        $totalTechnicians = User::where('role', 'technician')->count();
        $activeTechnicians = User::where('role', 'technician')->where('status', 'active')->count();

        return $this->successResponse([
            'contracts' => [
                'active' => $activeContracts,
                'expiring_soon' => $expiringSoon,
                'expired' => $expiredContracts,
                'total_value' => (float) $totalContractValue,
            ],
            'services' => [
                'today' => $todayVisits,
                'upcoming' => $upcomingVisits,
                'overdue' => $overdueVisits,
                'completed' => $completedVisits,
                'open_requests' => $openRequests,
            ],
            'financials' => [
                'total_contract_value' => (float) $totalContractValue,
                'total_invoiced' => (float) $totalInvoiced,
                'amount_collected' => (float) $amountCollected,
                'outstanding_amount' => (float) $outstandingAmount,
                'overdue_amount' => (float) $overdueAmount,
            ],
            'technicians' => [
                'total' => $totalTechnicians,
                'active' => $activeTechnicians,
                'jobs_today' => $todayVisits,
            ],
        ]);
    }

    /**
     * Technician Dashboard.
     */
    protected function technicianDashboard(User $user): JsonResponse
    {
        $today = now()->toDateString();

        $todayJobs = ServiceSchedule::where('technician_id', $user->id)
            ->where('scheduled_date', $today)
            ->with(['customer', 'asset'])
            ->get();

        $pendingJobs = ServiceSchedule::where('technician_id', $user->id)
            ->where('scheduled_date', '<', $today)
            ->where('status', 'scheduled')
            ->count();

        $completedJobs = ServiceSchedule::where('technician_id', $user->id)
            ->where('status', 'completed')
            ->count();

        return $this->successResponse([
            'technician_name' => $user->name,
            'today_jobs_count' => $todayJobs->count(),
            'pending_jobs_count' => $pendingJobs,
            'completed_jobs_count' => $completedJobs,
            'today_jobs' => $todayJobs,
        ]);
    }

    /**
     * Customer Dashboard.
     */
    protected function customerDashboard(User $user): JsonResponse
    {
        $customerId = $user->customer_id;
        $customer = Customer::find($customerId);

        $activeAmcCount = Contract::where('customer_id', $customerId)->where('status', 'active')->count();
        $equipmentCount = $customer ? $customer->assets()->count() : 0;
        $openRequestsCount = ServiceRequest::where('customer_id', $customerId)->whereIn('status', ['new', 'assigned', 'in_progress'])->count();

        $nextVisit = ServiceSchedule::where('customer_id', $customerId)
            ->where('scheduled_date', '>=', now()->toDateString())
            ->where('status', 'scheduled')
            ->orderBy('scheduled_date')
            ->with('asset')
            ->first();

        $pendingAmount = Invoice::where('customer_id', $customerId)
            ->whereIn('status', ['issued', 'partially_paid', 'overdue'])
            ->sum('balance_due');

        $primaryContract = Contract::where('customer_id', $customerId)
            ->whereIn('status', ['payment_requested', 'active', 'payment_declined', 'expired'])
            ->with(['assets'])
            ->orderByRaw("CASE 
                WHEN status = 'payment_requested' THEN 1 
                WHEN status = 'active' THEN 2 
                WHEN status = 'payment_declined' THEN 3 
                ELSE 4 
            END")
            ->latest('created_at')
            ->first();

        return $this->successResponse([
            'customer_name' => $customer?->name ?? $user->name,
            'company_name' => $customer?->company_name,
            'active_amc' => $activeAmcCount,
            'equipment_count' => $equipmentCount,
            'open_requests' => $openRequestsCount,
            'next_visit' => $nextVisit,
            'pending_amount' => (float) $pendingAmount,
            'primary_contract' => $primaryContract,
        ]);
    }
}
