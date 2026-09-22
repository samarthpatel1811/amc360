<?php

namespace App\Traits;

use App\Models\Company;
use App\Scopes\TenantScope;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Auth;

trait BelongsToCompany
{
    /**
     * The "booted" method of the model.
     */
    protected static function bootBelongsToCompany(): void
    {
        static::addGlobalScope(new TenantScope);

        static::creating(function ($model) {
            if (empty($model->company_id) && Auth::check() && Auth::user()->company_id) {
                $model->company_id = Auth::user()->company_id;
            }
        });
    }

    /**
     * Company relationship.
     */
    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class);
    }
}
