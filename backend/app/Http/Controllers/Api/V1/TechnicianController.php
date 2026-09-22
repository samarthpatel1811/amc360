<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\ServiceSchedule;
use App\Models\ServiceRequest;
use App\Models\User;
use App\Services\AuditLogService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class TechnicianController extends BaseApiController
{
    /**
     * List all technicians in the company.
     */
    public function index(Request $request): JsonResponse
    {
        $technicians = User::where('role', 'technician')
            ->withCount([
                'assignedSchedules as active_jobs_count' => function ($q) {
                    $q->whereIn('status', ['scheduled', 'in_progress']);
                },
                'assignedSchedules as today_jobs_count' => function ($q) {
                    $q->where('scheduled_date', now()->toDateString());
                },
            ])
            ->latest()
            ->get();

        return $this->successResponse($technicians);
    }

    /**
     * Add technician.
     */
    public function store(Request $request): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return $this->errorResponse('Unauthorized.', null, 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255',
            'phone' => 'required|string|max:30',
            'skills' => 'nullable|array',
            'password' => 'required|string|min:8',
        ]);

        $company = $request->user()->company;

        $exists = User::withoutGlobalScopes()
            ->where('company_id', $company->id)
            ->where('email', $validated['email'])
            ->exists();

        if ($exists) {
            return $this->errorResponse('A user with this email already exists in your company.', null, 422);
        }

        $technician = User::create([
            'company_id' => $company->id,
            'name' => $validated['name'],
            'email' => $validated['email'],
            'phone' => $validated['phone'],
            'role' => 'technician',
            'skills' => $validated['skills'] ?? [],
            'availability_status' => 'available',
            'status' => 'active',
            'password' => Hash::make($validated['password']),
        ]);

        AuditLogService::log('technician_created', $technician);

        return $this->successResponse($technician, 'Technician created successfully.', 201);
    }

    /**
     * Get technician dashboard jobs summary.
     */
    public function jobs(Request $request): JsonResponse
    {
        $technicianId = $request->user()->isTechnician() ? $request->user()->id : $request->get('technician_id');

        if (!$technicianId) {
            return $this->errorResponse('Technician ID required.', null, 400);
        }

        $today = now()->toDateString();

        $todayJobs = ServiceSchedule::where('technician_id', $technicianId)
            ->where('scheduled_date', $today)
            ->with(['customer', 'asset', 'contract', 'serviceVisit'])
            ->get();

        $upcomingJobs = ServiceSchedule::where('technician_id', $technicianId)
            ->where('scheduled_date', '>', $today)
            ->where('status', 'scheduled')
            ->with(['customer', 'asset', 'contract'])
            ->take(10)
            ->get();

        $pendingJobs = ServiceSchedule::where('technician_id', $technicianId)
            ->where('scheduled_date', '<', $today)
            ->where('status', 'scheduled')
            ->with(['customer', 'asset', 'contract'])
            ->get();

        $completedJobs = ServiceSchedule::where('technician_id', $technicianId)
            ->where('status', 'completed')
            ->with(['customer', 'asset', 'serviceVisit'])
            ->latest('updated_at')
            ->take(10)
            ->get();

        $openRequests = ServiceRequest::where('assigned_technician_id', $technicianId)
            ->whereIn('status', ['assigned', 'accepted', 'in_progress'])
            ->with(['customer', 'asset'])
            ->get();

        return $this->successResponse([
            'today_jobs' => $todayJobs,
            'upcoming_jobs' => $upcomingJobs,
            'pending_jobs' => $pendingJobs,
            'completed_jobs' => $completedJobs,
            'service_requests' => $openRequests,
            'counts' => [
                'today' => $todayJobs->count(),
                'upcoming' => $upcomingJobs->count(),
                'pending' => $pendingJobs->count(),
                'completed' => $completedJobs->count(),
            ],
        ]);
    }

    /**
     * Update technician availability.
     */
    public function updateAvailability(Request $request, int $id): JsonResponse
    {
        $technician = User::where('role', 'technician')->findOrFail($id);

        $validated = $request->validate([
            'availability_status' => 'required|string|in:available,busy,on_leave,inactive',
        ]);

        $technician->update($validated);

        return $this->successResponse($technician, 'Availability updated successfully.');
    }
}
