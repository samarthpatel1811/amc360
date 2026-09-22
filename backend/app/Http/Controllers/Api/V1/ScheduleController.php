<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\ServiceSchedule;
use App\Models\User;
use App\Services\AuditLogService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ScheduleController extends BaseApiController
{
    /**
     * List schedules with filters for Day, Week, and List views.
     */
    public function index(Request $request): JsonResponse
    {
        $query = ServiceSchedule::query();

        if ($request->user()->isCustomer()) {
            $query->where('customer_id', $request->user()->customer_id);
        } elseif ($request->user()->isTechnician()) {
            $query->where('technician_id', $request->user()->id);
        } elseif ($technicianId = $request->get('technician_id')) {
            $query->where('technician_id', $technicianId);
        }

        if ($customerId = $request->get('customer_id')) {
            $query->where('customer_id', $customerId);
        }

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        if ($startDate = $request->get('start_date')) {
            $query->where('scheduled_date', '>=', $startDate);
        }

        if ($endDate = $request->get('end_date')) {
            $query->where('scheduled_date', '<=', $endDate);
        }

        // Quick filter for 'today' or 'upcoming'
        if ($filter = $request->get('quick_filter')) {
            $today = now()->toDateString();
            if ($filter === 'today') {
                $query->where('scheduled_date', $today);
            } elseif ($filter === 'upcoming') {
                $query->where('scheduled_date', '>=', $today)
                      ->where('status', 'scheduled');
            } elseif ($filter === 'overdue') {
                $query->where('scheduled_date', '<', $today)
                      ->where('status', 'scheduled');
            }
        }

        $schedules = $query->with(['customer', 'asset', 'technician', 'contract', 'serviceVisit'])
            ->orderBy('scheduled_date')
            ->orderBy('scheduled_time_start')
            ->paginate((int) $request->get('per_page', 25));

        return $this->successResponse($schedules);
    }

    /**
     * Reschedule future visit with reason and audit trail.
     */
    public function reschedule(Request $request, int $id): JsonResponse
    {
        if ($request->user()->isCustomer()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $schedule = ServiceSchedule::findOrFail($id);

        if ($schedule->status === 'completed') {
            return $this->errorResponse('Completed visits cannot be rescheduled.', null, 422);
        }

        $validated = $request->validate([
            'new_date' => 'required|date',
            'scheduled_time_start' => 'nullable|string',
            'scheduled_time_end' => 'nullable|string',
            'reschedule_reason' => 'required|string|max:500',
        ]);

        $oldDate = $schedule->scheduled_date->format('Y-m-d');

        $schedule->update([
            'rescheduled_from_date' => $oldDate,
            'scheduled_date' => $validated['new_date'],
            'scheduled_time_start' => $validated['scheduled_time_start'] ?? $schedule->scheduled_time_start,
            'scheduled_time_end' => $validated['scheduled_time_end'] ?? $schedule->scheduled_time_end,
            'reschedule_reason' => $validated['reschedule_reason'],
            'status' => 'rescheduled',
        ]);

        AuditLogService::log('visit_rescheduled', $schedule, [
            'old_date' => $oldDate,
            'new_date' => $validated['new_date'],
            'reason' => $validated['reschedule_reason'],
        ]);

        return $this->successResponse($schedule->fresh()->load(['customer', 'asset', 'technician']), 'Visit rescheduled successfully.');
    }

    /**
     * Cancel a future visit.
     */
    public function cancel(Request $request, int $id): JsonResponse
    {
        if ($request->user()->isCustomer()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $schedule = ServiceSchedule::findOrFail($id);

        if ($schedule->status === 'completed') {
            return $this->errorResponse('Completed visits cannot be cancelled.', null, 422);
        }

        $validated = $request->validate([
            'cancellation_reason' => 'required|string|max:500',
        ]);

        $schedule->update([
            'status' => 'cancelled',
            'cancellation_reason' => $validated['cancellation_reason'],
        ]);

        AuditLogService::log('visit_cancelled', $schedule, ['reason' => $validated['cancellation_reason']]);

        return $this->successResponse($schedule->fresh(), 'Visit cancelled successfully.');
    }

    /**
     * Assign technician.
     */
    public function assignTechnician(Request $request, int $id): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $schedule = ServiceSchedule::findOrFail($id);

        $validated = $request->validate([
            'technician_id' => 'required|exists:users,id',
        ]);

        $technician = User::where('company_id', $schedule->company_id)
            ->where('role', 'technician')
            ->findOrFail($validated['technician_id']);

        $schedule->update([
            'technician_id' => $technician->id,
        ]);

        AuditLogService::log('technician_assigned', $schedule, ['technician_id' => $technician->id]);

        return $this->successResponse($schedule->fresh()->load(['technician', 'customer', 'asset']), 'Technician assigned successfully.');
    }
}
