<?php

use App\Http\Controllers\Api\V1\AssetController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CategoryAndChecklistController;
use App\Http\Controllers\Api\V1\CompanyController;
use App\Http\Controllers\Api\V1\ContractController;
use App\Http\Controllers\Api\V1\CustomerController;
use App\Http\Controllers\Api\V1\InvoiceController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\ScheduleController;
use App\Http\Controllers\Api\V1\ServiceRequestController;
use App\Http\Controllers\Api\V1\ServiceVisitController;
use App\Http\Controllers\Api\V1\SyncController;
use App\Http\Controllers\Api\V1\TechnicianController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| AMC360 REST API Routes (Version 1)
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // Public Auth Endpoints
    Route::get('/auth/public-info', [AuthController::class, 'publicInfo']);
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/auth/verify-reset-code', [AuthController::class, 'verifyResetCode']);
    Route::post('/auth/reset-password', [AuthController::class, 'resetPassword']);

    // Authenticated Endpoints (Sanctum)
    Route::middleware('auth:sanctum')->group(function () {

        // Session & Profile
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/profile', [AuthController::class, 'updateProfile']);
        Route::post('/auth/change-password', [AuthController::class, 'changePassword']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        // Company & Settings
        Route::get('/company', [CompanyController::class, 'show']);
        Route::put('/company', [CompanyController::class, 'update']);

        // Reference Catalogs
        Route::get('/catalogs/asset-categories', [CategoryAndChecklistController::class, 'assetCategories']);
        Route::get('/catalogs/service-categories', [CategoryAndChecklistController::class, 'serviceCategories']);
        Route::get('/catalogs/checklist-templates', [CategoryAndChecklistController::class, 'checklistTemplates']);
        Route::get('/catalogs/parts', [CategoryAndChecklistController::class, 'parts']);

        // Dashboard & Analytics
        Route::get('/dashboard/summary', [ReportController::class, 'dashboard']);

        // Customers
        Route::get('/customers', [CustomerController::class, 'index']);
        Route::post('/customers', [CustomerController::class, 'store']);
        Route::get('/customers/{id}', [CustomerController::class, 'show']);
        Route::put('/customers/{id}', [CustomerController::class, 'update']);
        Route::delete('/customers/{id}', [CustomerController::class, 'destroy']);
        Route::get('/customers/{id}/assets', [CustomerController::class, 'assets']);
        Route::get('/customers/{id}/contracts', [CustomerController::class, 'contracts']);
        Route::get('/customers/{id}/visits', [CustomerController::class, 'visits']);
        Route::get('/customers/{id}/invoices', [CustomerController::class, 'invoices']);

        // Assets & QR Engine
        Route::get('/assets', [AssetController::class, 'index']);
        Route::post('/assets', [AssetController::class, 'store']);
        Route::get('/assets/{id}', [AssetController::class, 'show']);
        Route::put('/assets/{id}', [AssetController::class, 'update']);
        Route::delete('/assets/{id}', [AssetController::class, 'destroy']);
        Route::get('/assets/{id}/history', [AssetController::class, 'history']);
        Route::get('/assets/qr/{qrToken}', [AssetController::class, 'scanQr']);

        // AMC Contracts & Scheduling Preview
        Route::post('/contracts/preview-dates', [ContractController::class, 'previewDates']);
        Route::get('/contracts', [ContractController::class, 'index']);
        Route::post('/contracts', [ContractController::class, 'store']);
        Route::get('/contracts/{id}', [ContractController::class, 'show']);
        Route::post('/contracts/{id}/renew', [ContractController::class, 'renew']);
        Route::post('/contracts/{id}/request-renewal', [ContractController::class, 'requestRenewal']);
        Route::post('/contracts/{id}/quote-renewal', [ContractController::class, 'quoteRenewal']);
        Route::post('/contracts/{id}/accept-renewal', [ContractController::class, 'acceptRenewal']);
        Route::post('/contracts/{id}/decline-payment', [ContractController::class, 'declinePayment']);
        Route::post('/contracts/{id}/pay-contract', [ContractController::class, 'payContract']);

        // Service Schedules & Calendar
        Route::get('/schedules', [ScheduleController::class, 'index']);
        Route::post('/schedules/{id}/reschedule', [ScheduleController::class, 'reschedule']);
        Route::post('/schedules/{id}/cancel', [ScheduleController::class, 'cancel']);
        Route::post('/schedules/{id}/assign', [ScheduleController::class, 'assignTechnician']);

        // Technicians
        Route::get('/technicians', [TechnicianController::class, 'index']);
        Route::post('/technicians', [TechnicianController::class, 'store']);
        Route::get('/technicians/jobs', [TechnicianController::class, 'jobs']);
        Route::put('/technicians/{id}/availability', [TechnicianController::class, 'updateAvailability']);

        // Service Visits (Field Execution)
        Route::get('/service-visits', [ServiceVisitController::class, 'index']);
        Route::post('/service-visits/start', [ServiceVisitController::class, 'startVisit']);
        Route::get('/service-visits/{id}', [ServiceVisitController::class, 'show']);
        Route::post('/service-visits/{id}/checklist', [ServiceVisitController::class, 'updateChecklist']);
        Route::post('/service-visits/{id}/photos', [ServiceVisitController::class, 'addPhoto']);
        Route::post('/service-visits/{id}/parts', [ServiceVisitController::class, 'addPart']);
        Route::post('/service-visits/{id}/signature', [ServiceVisitController::class, 'captureSignature']);
        Route::post('/service-visits/{id}/complete', [ServiceVisitController::class, 'completeVisit']);
        Route::get('/service-visits/{id}/pdf', [ServiceVisitController::class, 'downloadPdf']);

        // Service Requests (Complaints / SLA)
        Route::get('/service-requests', [ServiceRequestController::class, 'index']);
        Route::post('/service-requests', [ServiceRequestController::class, 'store']);
        Route::get('/service-requests/{id}', [ServiceRequestController::class, 'show']);
        Route::post('/service-requests/{id}/assign', [ServiceRequestController::class, 'assignTechnician']);
        Route::put('/service-requests/{id}/status', [ServiceRequestController::class, 'updateStatus']);

        // Invoices & Billing
        Route::get('/invoices', [InvoiceController::class, 'index']);
        Route::post('/invoices', [InvoiceController::class, 'store']);
        Route::get('/invoices/{id}', [InvoiceController::class, 'show']);

        // Payments
        Route::get('/payments', [PaymentController::class, 'index']);
        Route::post('/payments', [PaymentController::class, 'store']);

        // Notifications
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);

        // Offline Sync (Idempotent)
        Route::post('/sync/offline-queue', [SyncController::class, 'syncOfflineQueue']);
    });
});
