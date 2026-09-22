<?php

namespace App\Models;

use App\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Model;

class Part extends Model
{
    use BelongsToCompany;

    protected $guarded = ['id'];

    protected $casts = [
        'default_price' => 'decimal:2',
        'tax_rate' => 'decimal:2',
        'active' => 'boolean',
    ];
}
