<?php

namespace App\Models;

use App\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChecklistTemplate extends Model
{
    use BelongsToCompany;

    protected $guarded = ['id'];

    protected $casts = [
        'active' => 'boolean',
    ];

    public function serviceCategory(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(ChecklistItem::class, 'template_id')->orderBy('sort_order');
    }
}
