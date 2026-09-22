<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('contracts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->string('contract_number', 50)->index();
            $table->string('title')->nullable();
            $table->date('start_date')->index();
            $table->date('end_date')->index();
            $table->string('duration_type', 30)->default('12_months'); // 1_month, 3_months, 6_months, 12_months, 24_months, custom
            $table->string('service_frequency', 30)->default('quarterly'); // weekly, biweekly, monthly, bimonthly, quarterly, four_monthly, half_yearly, yearly, custom_days, custom_months
            $table->integer('frequency_interval_value')->nullable(); // e.g. 45 (days) or 5 (months)
            $table->string('first_visit_rule', 30)->default('start_date'); // start_date, after_interval, custom_date
            $table->date('custom_first_visit_date')->nullable();
            $table->string('visit_count_type', 30)->default('automatic'); // automatic, fixed, custom
            $table->integer('included_visit_count')->nullable(); // e.g. 7
            $table->decimal('total_price', 12, 2)->default(0.00);
            $table->string('billing_type', 30)->default('fixed'); // fixed, recurring, installments
            $table->string('recurring_period', 30)->nullable(); // monthly, quarterly
            $table->string('coverage_parts', 30)->default('excluded'); // included, excluded, partial
            $table->string('coverage_emergency_visits', 30)->default('chargeable'); // included, chargeable
            $table->string('coverage_breakdown_visits', 30)->default('chargeable'); // included, chargeable
            $table->string('coverage_labour', 30)->default('included'); // included, chargeable
            $table->text('custom_coverage_terms')->nullable();
            $table->text('exclusions')->nullable();
            $table->string('sla_response_time', 30)->default('24_hours'); // 4_hours, 8_hours, 12_hours, 24_hours, 48_hours, no_sla, custom
            $table->integer('sla_response_hours')->nullable();
            $table->text('payment_terms')->nullable();
            $table->text('notes')->nullable();
            $table->string('status', 30)->default('active')->index(); // draft, pending_approval, active, suspended, expired, cancelled, renewed
            $table->unsignedBigInteger('renewed_from_contract_id')->nullable()->index();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['company_id', 'contract_number']);
            $table->foreign('renewed_from_contract_id')->references('id')->on('contracts')->nullOnDelete();
        });

        Schema::create('contract_assets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('contract_id')->constrained('contracts')->cascadeOnDelete();
            $table->foreignId('asset_id')->constrained('assets')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['contract_id', 'asset_id']);
        });

        Schema::create('service_schedules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('contract_id')->nullable()->constrained('contracts')->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->foreignId('asset_id')->nullable()->constrained('assets')->nullOnDelete();
            $table->foreignId('service_category_id')->nullable()->constrained('service_categories')->nullOnDelete();
            $table->foreignId('technician_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('scheduled_date')->index();
            $table->time('scheduled_time_start')->nullable();
            $table->time('scheduled_time_end')->nullable();
            $table->string('visit_type', 30)->default('amc_preventive'); // amc_preventive, breakdown, inspection, emergency, chargeable
            $table->string('status', 30)->default('scheduled')->index(); // scheduled, in_progress, completed, rescheduled, cancelled
            $table->string('priority', 20)->default('normal'); // low, normal, high, urgent
            $table->date('rescheduled_from_date')->nullable();
            $table->text('reschedule_reason')->nullable();
            $table->text('cancellation_reason')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_schedules');
        Schema::dropIfExists('contract_assets');
        Schema::dropIfExists('contracts');
    }
};
