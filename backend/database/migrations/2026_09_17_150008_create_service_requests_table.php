<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->foreignId('asset_id')->constrained('assets')->cascadeOnDelete();
            $table->foreignId('contract_id')->nullable()->constrained('contracts')->nullOnDelete();
            $table->string('request_number', 50)->index();
            $table->string('title');
            $table->text('description');
            $table->string('issue_type', 100);
            $table->string('priority', 20)->default('normal'); // low, normal, high, urgent
            $table->date('preferred_date')->nullable();
            $table->string('preferred_time', 50)->nullable();
            $table->string('photo_path')->nullable();
            $table->foreignId('assigned_technician_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status', 30)->default('new')->index(); // new, assigned, accepted, on_the_way, in_progress, waiting_for_customer, waiting_for_part, completed, cancelled
            $table->boolean('is_covered_under_amc')->default(true);
            $table->dateTime('sla_due_at')->nullable()->index();
            $table->dateTime('first_responded_at')->nullable();
            $table->dateTime('completed_at')->nullable();
            $table->text('cancellation_reason')->nullable();
            $table->timestamps();

            $table->unique(['company_id', 'request_number']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_requests');
    }
};
