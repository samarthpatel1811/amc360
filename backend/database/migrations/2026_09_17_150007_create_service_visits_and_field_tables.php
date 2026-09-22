<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_visits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('schedule_id')->nullable()->constrained('service_schedules')->nullOnDelete();
            $table->foreignId('contract_id')->nullable()->constrained('contracts')->nullOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->foreignId('asset_id')->constrained('assets')->cascadeOnDelete();
            $table->foreignId('technician_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('service_category_id')->nullable()->constrained('service_categories')->nullOnDelete();
            $table->string('visit_number', 50)->index();
            $table->string('status', 30)->default('in_progress')->index(); // in_progress, completed, cancelled
            $table->dateTime('started_at');
            $table->dateTime('completed_at')->nullable()->index();
            $table->decimal('start_latitude', 10, 7)->nullable();
            $table->decimal('start_longitude', 10, 7)->nullable();
            $table->decimal('completion_latitude', 10, 7)->nullable();
            $table->decimal('completion_longitude', 10, 7)->nullable();
            $table->text('work_performed')->nullable();
            $table->text('findings')->nullable();
            $table->text('recommendations')->nullable();
            $table->text('customer_remarks')->nullable();
            $table->boolean('is_chargeable')->default(false);
            $table->decimal('visit_charge', 10, 2)->default(0.00);
            $table->string('report_number', 50)->nullable()->index();
            $table->string('report_pdf_path')->nullable();
            $table->uuid('client_operation_id')->nullable()->unique(); // For offline idempotency
            $table->timestamps();

            $table->unique(['company_id', 'visit_number']);
        });

        Schema::create('service_visit_checklist_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('service_visit_id')->constrained('service_visits')->cascadeOnDelete();
            $table->foreignId('checklist_item_id')->nullable()->constrained('checklist_items')->nullOnDelete();
            $table->string('title');
            $table->string('response_type', 30)->default('checkbox');
            $table->boolean('required')->default(false);
            $table->text('value')->nullable();
            $table->boolean('is_passed')->nullable();
            $table->timestamps();
        });

        Schema::create('service_visit_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('service_visit_id')->constrained('service_visits')->cascadeOnDelete();
            $table->string('photo_type', 30)->default('equipment'); // before, after, equipment, damage, other
            $table->string('file_path');
            $table->string('caption')->nullable();
            $table->timestamps();
        });

        Schema::create('service_visit_parts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('service_visit_id')->constrained('service_visits')->cascadeOnDelete();
            $table->foreignId('part_id')->nullable()->constrained('parts')->nullOnDelete();
            $table->string('part_name');
            $table->decimal('quantity', 8, 2)->default(1.00);
            $table->decimal('unit_price', 10, 2)->default(0.00);
            $table->decimal('total_price', 10, 2)->default(0.00);
            $table->string('coverage_type', 30)->default('included'); // included, chargeable, warranty
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        Schema::create('service_visit_signatures', function (Blueprint $table) {
            $table->id();
            $table->foreignId('service_visit_id')->constrained('service_visits')->cascadeOnDelete();
            $table->string('signature_image_path');
            $table->string('signed_by_name');
            $table->dateTime('signed_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_visit_signatures');
        Schema::dropIfExists('service_visit_parts');
        Schema::dropIfExists('service_visit_photos');
        Schema::dropIfExists('service_visit_checklist_items');
        Schema::dropIfExists('service_visits');
    }
};
