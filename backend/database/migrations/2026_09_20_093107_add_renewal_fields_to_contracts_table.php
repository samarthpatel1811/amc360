<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('contracts', function (Blueprint $table) {
            $table->string('renewal_status', 30)->default('none')->index()->after('status'); // none, requested, quoted, renewed
            $table->string('renewal_duration_type', 30)->nullable()->after('renewal_status');
            $table->date('renewal_preferred_start_date')->nullable()->after('renewal_duration_type');
            $table->text('renewal_notes')->nullable()->after('renewal_preferred_start_date');
            $table->timestamp('renewal_requested_at')->nullable()->after('renewal_notes');
            $table->decimal('renewal_quoted_price', 12, 2)->nullable()->after('renewal_requested_at');
            $table->text('renewal_quoted_notes')->nullable()->after('renewal_quoted_price');
            $table->timestamp('renewal_quoted_at')->nullable()->after('renewal_quoted_notes');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('contracts', function (Blueprint $table) {
            $table->dropColumn([
                'renewal_status',
                'renewal_duration_type',
                'renewal_preferred_start_date',
                'renewal_notes',
                'renewal_requested_at',
                'renewal_quoted_price',
                'renewal_quoted_notes',
                'renewal_quoted_at',
            ]);
        });
    }
};
