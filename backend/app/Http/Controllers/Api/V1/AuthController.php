<?php

namespace App\Http\Controllers\Api\V1;

use App\Mail\PasswordResetMail;
use App\Models\User;
use App\Services\AuditLogService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class AuthController extends BaseApiController
{
    /**
     * User login with Email or 10-digit Indian Mobile Number.
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'nullable|string',
            'login' => 'nullable|string',
            'password' => 'required|string',
            'device_name' => 'nullable|string',
        ]);

        $identifier = trim($request->input('email') ?? $request->input('login') ?? '');

        if (empty($identifier)) {
            return $this->errorResponse('Please enter your email address or 10-digit mobile number.', null, 422);
        }

        $user = null;

        if (str_contains($identifier, '@')) {
            // Login via Email
            $user = User::withoutGlobalScopes()
                ->where('email', strtolower($identifier))
                ->with(['company', 'customer'])
                ->first();

            // Check if matching company official email (for Admin)
            if (!$user) {
                $company = \App\Models\Company::where('email', strtolower($identifier))->first();
                if ($company) {
                    $user = User::withoutGlobalScopes()
                        ->where('company_id', $company->id)
                        ->where('role', 'admin')
                        ->with(['company', 'customer'])
                        ->first();
                }
            }
        } else {
            // Login via 10-digit Indian Mobile Number
            $digits = preg_replace('/\D/', '', $identifier);
            if (strlen($digits) == 12 && str_starts_with($digits, '91')) {
                $digits = substr($digits, 2);
            } elseif (strlen($digits) == 11 && str_starts_with($digits, '0')) {
                $digits = substr($digits, 1);
            }

            if (strlen($digits) !== 10) {
                return $this->errorResponse('Mobile number must be exactly 10 digits (e.g. 9876543210).', null, 422);
            }

            if (!preg_match('/^[6-9]\d{9}$/', $digits)) {
                return $this->errorResponse('Please enter a valid 10-digit Indian mobile number starting with 6, 7, 8, or 9.', null, 422);
            }

            // Search by phone in users
            $user = User::withoutGlobalScopes()
                ->where(function ($q) use ($digits) {
                    $q->where('phone', 'like', "%{$digits}%")
                      ->orWhereRaw("REPLACE(REPLACE(REPLACE(REPLACE(phone, ' ', ''), '+', ''), '-', ''), '(', '') LIKE ?", ["%{$digits}%"]);
                })
                ->with(['company', 'customer'])
                ->first();

            // Also check company phone (for Admin)
            if (!$user) {
                $company = \App\Models\Company::where(function ($q) use ($digits) {
                    $q->where('phone', 'like', "%{$digits}%")
                      ->orWhereRaw("REPLACE(REPLACE(REPLACE(REPLACE(phone, ' ', ''), '+', ''), '-', ''), '(', '') LIKE ?", ["%{$digits}%"]);
                })->first();

                if ($company) {
                    $user = User::withoutGlobalScopes()
                        ->where('company_id', $company->id)
                        ->where('role', 'admin')
                        ->with(['company', 'customer'])
                        ->first();
                }
            }
        }

        if (!$user || !Hash::check($request->password, $user->password)) {
            return $this->errorResponse('Invalid credentials. Please check your email/mobile number and password.', null, 401);
        }

        if ($user->status !== 'active') {
            return $this->errorResponse('Your account is inactive. Please contact your company administrator.', null, 403);
        }

        $deviceName = $request->device_name ?: 'Mobile App';
        $token = $user->createToken($deviceName)->plainTextToken;

        AuditLogService::log('user_login', $user);

        return $this->successResponse([
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'company_id' => $user->company_id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role,
                'customer_id' => $user->customer_id,
                'skills' => $user->skills,
                'availability_status' => $user->availability_status,
                'avatar_url' => $user->avatar_url,
            ],
            'company' => $user->company,
            'customer' => $user->customer,
        ], 'Login successful.');
    }

    /**
     * Public application and company info for the login screen.
     */
    public function publicInfo(): JsonResponse
    {
        $company = \App\Models\Company::first();
        $admin = User::withoutGlobalScopes()->where('role', 'admin')->first();

        return $this->successResponse([
            'company_name' => $company?->name ?? 'AMC360 Command Center',
            'admin_email' => $admin?->email ?? $company?->email ?? 'admin@cooltech.com',
            'admin_name' => $admin?->name ?? 'Admin',
            'support_phone' => $company?->phone ?? '+91 98765 43210',
            'city' => $company?->city ?? 'Ahmedabad',
            'state' => $company?->state ?? 'Gujarat',
            'country' => $company?->country ?? 'India',
        ]);
    }

    /**
     * Authenticated user profile.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->load(['company', 'customer']);

        return $this->successResponse([
            'user' => $user,
            'company' => $user->company,
            'customer' => $user->customer,
        ], 'Profile retrieved.');
    }

    /**
     * Update user profile.
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'nullable|string|max:30',
            'avatar_url' => 'nullable|string',
            'skills' => 'nullable|array',
            'availability_status' => 'nullable|string|in:available,busy,on_leave,inactive',
        ]);

        $user->update($validated);

        return $this->successResponse($user->fresh(), 'Profile updated successfully.');
    }

    /**
     * Change password.
     */
    public function changePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:8|confirmed',
        ]);

        $user = $request->user();

        if (!Hash::check($request->current_password, $user->password)) {
            return $this->errorResponse('Current password does not match.', null, 422);
        }

        $user->password = Hash::make($request->new_password);
        $user->save();

        AuditLogService::log('password_changed', $user);

        return $this->successResponse(null, 'Password updated successfully.');
    }

    /**
     * Send password reset OTP verification email.
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $email = strtolower(trim($request->email));

        $user = User::withoutGlobalScopes()
            ->where('email', $email)
            ->first();

        if (!$user) {
            $company = \App\Models\Company::where('email', $email)->first();
            if ($company) {
                $user = User::withoutGlobalScopes()
                    ->where('company_id', $company->id)
                    ->where('role', 'admin')
                    ->first();
            }
        }

        if (!$user) {
            return $this->errorResponse('No account registered with this email address.', null, 404);
        }

        if ($user->status !== 'active') {
            return $this->errorResponse('This account is inactive. Please contact support.', null, 403);
        }

        // Generate 6-digit numeric OTP code
        $code = (string) random_int(100000, 999999);

        // Store hash of code in password_reset_tokens
        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $email],
            [
                'token' => Hash::make($code),
                'created_at' => now(),
            ]
        );

        $mailSent = false;
        $mailError = null;
        try {
            Mail::to($email)->send(new PasswordResetMail($code, $user->name));
            $mailSent = true;
        } catch (\Throwable $e) {
            $mailError = $e->getMessage();
            Log::error("Failed sending password reset email to {$email}: " . $mailError);
        }

        AuditLogService::log('password_reset_requested', $user, null, null, [
            'email' => $email,
            'mail_sent' => $mailSent,
            'mail_error' => $mailError,
        ]);

        return $this->successResponse([
            'email' => $email,
            'mail_sent' => $mailSent,
            'mail_error' => $mailError,
            'debug_code' => config('app.debug') ? $code : null,
        ], $mailSent 
            ? 'A 6-digit verification code has been sent to your email.' 
            : 'Verification code generated on server.');
    }

    /**
     * Verify 6-digit reset code.
     */
    public function verifyResetCode(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|string|size:6',
        ]);

        $email = strtolower(trim($request->email));
        $code = trim($request->code);

        $record = DB::table('password_reset_tokens')->where('email', $email)->first();

        if (!$record) {
            return $this->errorResponse('No active password reset request found. Please request a new code.', null, 400);
        }

        // Check 15-minute expiration
        if (now()->subMinutes(15)->gt($record->created_at)) {
            DB::table('password_reset_tokens')->where('email', $email)->delete();
            return $this->errorResponse('Verification code has expired. Please request a new one.', null, 400);
        }

        if (!Hash::check($code, $record->token)) {
            return $this->errorResponse('Invalid verification code. Please check your email and try again.', null, 422);
        }

        return $this->successResponse(['verified' => true], 'Verification code is valid.');
    }

    /**
     * Reset password using verified code.
     */
    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|string|size:6',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $email = strtolower(trim($request->email));
        $code = trim($request->code);

        $record = DB::table('password_reset_tokens')->where('email', $email)->first();

        if (!$record || !Hash::check($code, $record->token)) {
            return $this->errorResponse('Invalid or expired verification code.', null, 422);
        }

        if (now()->subMinutes(15)->gt($record->created_at)) {
            DB::table('password_reset_tokens')->where('email', $email)->delete();
            return $this->errorResponse('Verification code has expired. Please request a new one.', null, 400);
        }

        $user = User::withoutGlobalScopes()->where('email', $email)->first();
        if (!$user) {
            return $this->errorResponse('User not found.', null, 404);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        // Delete used token
        DB::table('password_reset_tokens')->where('email', $email)->delete();

        // Invalidate old tokens and issue a fresh session token
        $user->tokens()->delete();
        $token = $user->createToken('auth-token')->plainTextToken;
        $user->load('company');

        AuditLogService::log('password_reset_completed', $user);

        return $this->successResponse([
            'token' => $token,
            'user' => $user,
        ], 'Password has been reset successfully. Logging you in...');
    }

    /**
     * User logout.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        return $this->successResponse(null, 'Successfully logged out.');
    }
}
