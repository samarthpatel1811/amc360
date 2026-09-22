<?php

namespace App\Models;

use App\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Asset extends Model
{
    use HasFactory, SoftDeletes, BelongsToCompany;

    protected $guarded = ['id'];

    protected $casts = [
        'installation_date' => 'date',
        'purchase_date' => 'date',
        'warranty_start' => 'date',
        'warranty_end' => 'date',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(AssetCategory::class, 'category_id');
    }

    public function contracts(): BelongsToMany
    {
        return $this->belongsToMany(Contract::class, 'contract_assets')
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

    public function serviceRequests(): HasMany
    {
        return $this->hasMany(ServiceRequest::class);
    }

    public function documents(): HasMany
    {
        return $this->hasMany(Document::class);
    }
}
