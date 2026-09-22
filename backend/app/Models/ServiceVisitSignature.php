<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ServiceVisitSignature extends Model
{
    protected $guarded = ['id'];

    protected $casts = [
        'signed_at' => 'datetime',
    ];

    public function serviceVisit(): BelongsTo
    {
        return $this->belongsTo(ServiceVisit::class);
    }
}
