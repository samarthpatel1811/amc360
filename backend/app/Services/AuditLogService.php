<?php

namespace App\Services;

use App\Models\AuditLog;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Request;

class AuditLogService
{
    /**
     * Record an audit log entry.
     */
    public static function log(
        string $action,
        ?Model $entity = null,
        ?array $oldValues = null,
        ?array $newValues = null
    ): ?AuditLog {
        $user = Auth::user();
        $companyId = $user?->company_id ?? ($entity && isset($entity->company_id) ? $entity->company_id : null);

        if (!$companyId) {
            return null;
        }

        // Sanitize sensitive fields
        $sensitiveKeys = ['password', 'remember_token', 'token', 'secret'];
        if ($oldValues) {
            foreach ($sensitiveKeys as $key) {
                unset($oldValues[$key]);
            }
        }
        if ($newValues) {
            foreach ($sensitiveKeys as $key) {
                unset($newValues[$key]);
            }
        }

        return AuditLog::create([
            'company_id' => $companyId,
            'user_id' => $user?->id,
            'action' => $action,
            'entity_type' => $entity ? class_basename($entity) : 'System',
            'entity_id' => $entity?->id,
            'old_values' => $oldValues,
            'new_values' => $newValues,
            'ip_address' => Request::ip(),
            'user_agent' => substr(Request::userAgent() ?? '', 0, 255),
            'created_at' => now(),
        ]);
    }
}
