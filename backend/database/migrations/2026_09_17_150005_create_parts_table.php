<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('parts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->string('part_code', 50)->index();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('unit', 20)->default('pcs'); // pcs, kg, meter, ltr, etc.
            $table->decimal('default_price', 10, 2)->default(0.00);
            $table->decimal('tax_rate', 5, 2)->default(18.00);
            $table->boolean('active')->default(true);
            $table->timestamps();

            $table->unique(['company_id', 'part_code']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('parts');
    }
};
