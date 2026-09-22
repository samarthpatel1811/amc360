<?php

namespace App\Models;

use App\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Contract extends Model
{
    use HasFactory, SoftDeletes, BelongsToCompany;

    protected $guarded = ['id'];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'custom_first_visit_date' => 'date',
        'renewal_preferred_start_date' => 'date',
        'renewal_requested_at' => 'datetime',
        'renewal_quoted_at' => 'datetime',
        'total_price' => 'decimal:2',
        'renewal_quoted_price' => 'decimal:2',
        'included_visit_count' => 'integer',
        'frequency_interval_value' => 'integer',
        'sla_response_hours' => 'integer',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function assets(): BelongsToMany
    {
        return $this->belongsToMany(Asset::class, 'contract_assets')
            ->withTimestamps();
    }

    public function serviceSchedules(): HasMany
    {
        return $this->hasMany(ServiceSchedule::class);
    }

    public function serviceVisits(): HasMany
    {
        return $this->hasMany(ServiceVisit::class);
    }

    public function invoices(): HasMany
    {
        return $this->hasMany(Invoice::class);
    }

    public function renewedFromContract(): BelongsTo
    {
        return $this->belongsTo(Contract::class, 'renewed_from_contract_id');
    }

    public function renewals(): HasMany
    {
        return $this->hasMany(Contract::class, 'renewed_from_contract_id');
    }

    public function documents(): HasMany
    {
        return $this->hasMany(Document::class);
    }
}
