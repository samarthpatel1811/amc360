<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('asset_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->string('name');
            $table->text('description')->nullable();
            $table->timestamps();

            $table->unique(['company_id', 'name']);
        });

        Schema::create('assets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->foreignId('category_id')->nullable()->constrained('asset_categories')->nullOnDelete();
            $table->string('asset_code', 50)->index();
            $table->string('asset_type', 100);
            $table->string('brand', 100);
            $table->string('model', 100)->nullable();
            $table->string('serial_number', 100)->index();
            $table->string('capacity', 50)->nullable();
            $table->date('installation_date')->nullable();
            $table->date('purchase_date')->nullable();
            $table->date('warranty_start')->nullable();
            $table->date('warranty_end')->nullable()->index();
            $table->string('location')->nullable(); // e.g. 'Roof Top - Block B'
            $table->string('qr_token', 64)->unique(); // Secure random token for QR scanning
            $table->string('status', 30)->default('active')->index(); // 'active', 'under_maintenance', 'under_repair', 'inactive', 'retired'
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['company_id', 'asset_code']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('assets');
        Schema::dropIfExists('asset_categories');
    }
};
