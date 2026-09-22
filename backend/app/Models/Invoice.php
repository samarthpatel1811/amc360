<?php

namespace App\Models;

use App\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Invoice extends Model
{
    use HasFactory, BelongsToCompany;

    protected $guarded = ['id'];

    protected $casts = [
        'issue_date' => 'date',
        'due_date' => 'date',
        'subtotal' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'taxable_amount' => 'decimal:2',
        'tax_rate' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'paid_amount' => 'decimal:2',
        'balance_due' => 'decimal:2',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function contract(): BelongsTo
    {
        return $this->belongsTo(Contract::class);
    }

    public function serviceVisit(): BelongsTo
    {
        return $this->belongsTo(ServiceVisit::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(InvoiceItem::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function recalculateBalance(): void
    {
        $paid = $this->payments()->sum('amount');
        $this->paid_amount = $paid;
        $this->balance_due = max(0, $this->total_amount - $paid);

        if ($this->balance_due == 0 && $this->total_amount > 0) {
            $this->status = 'paid';
        } elseif ($paid > 0 && $this->balance_due > 0) {
            $this->status = 'partially_paid';
        } elseif ($this->status !== 'cancelled' && $this->status !== 'draft') {
            $this->status = 'issued';
        }

        $this->save();
    }
}
