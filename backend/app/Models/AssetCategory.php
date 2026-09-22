<?php

namespace App\Models;

use App\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AssetCategory extends Model
{
    use BelongsToCompany;

    protected $guarded = ['id'];

    public function assets(): HasMany
    {
        return $this->hasMany(Asset::class, 'category_id');
    }
}
