<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Permission extends Model
{
    protected $guarded = ['id'];

    public function rolePermissions(): HasMany
    {
        return $this->hasMany(RolePermission::class);
    }
}
