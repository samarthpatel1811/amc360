<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ContractAsset extends Model
{
    protected $table = 'contract_assets';
    protected $guarded = ['id'];

    public function contract(): BelongsTo
    {
        return $this->belongsTo(Contract::class);
    }

    public function asset(): BelongsTo
    {
        return $this->belongsTo(Asset::class);
    }
}
