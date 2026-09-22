<?php

namespace App\Models;

use App\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ServiceVisit extends Model
{
    use HasFactory, BelongsToCompany;

    protected $guarded = ['id'];

    protected $casts = [
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
        'start_latitude' => 'decimal:7',
        'start_longitude' => 'decimal:7',
        'completion_latitude' => 'decimal:7',
        'completion_longitude' => 'decimal:7',
        'is_chargeable' => 'boolean',
        'visit_charge' => 'decimal:2',
    ];

    public function schedule(): BelongsTo
    {
        return $this->belongsTo(ServiceSchedule::class, 'schedule_id');
    }

    public function contract(): BelongsTo
    {
        return $this->belongsTo(Contract::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function asset(): BelongsTo
    {
        return $this->belongsTo(Asset::class);
    }

    public function technician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'technician_id');
    }

    public function serviceCategory(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class);
    }

    public function checklistItems(): HasMany
    {
        return $this->hasMany(ServiceVisitChecklistItem::class);
    }

    public function photos(): HasMany
    {
        return $this->hasMany(ServiceVisitPhoto::class);
    }

    public function parts(): HasMany
    {
        return $this->hasMany(ServiceVisitPart::class);
    }

    public function signature(): HasOne
    {
        return $this->hasOne(ServiceVisitSignature::class);
    }

    public function invoices(): HasMany
    {
        return $this->hasMany(Invoice::class);
    }

    public function documents(): HasMany
    {
        return $this->hasMany(Document::class);
    }
}
