<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action', 50)->index(); // login, contract_created, visit_completed, etc.
            $table->string('entity_type', 100)->index(); // Contract, ServiceVisit, Invoice, etc.
            $table->unsignedBigInteger('entity_id')->nullable()->index();
            $table->json('old_values')->nullable();
            $table->json('new_values')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamp('created_at')->useCurrent()->index();
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('title');
            $table->text('message');
            $table->string('type', 50)->default('system'); // service_request, assignment, visit_completed, invoice, payment, contract_expiry, sla_warning, system
            $table->string('related_entity_type', 100)->nullable();
            $table->unsignedBigInteger('related_entity_id')->nullable();
            $table->boolean('is_read')->default(false)->index();
            $table->timestamps();
        });

        Schema::create('sync_operations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->uuid('local_operation_id')->unique(); // Unique idempotency identifier
            $table->string('entity_type', 100);
            $table->unsignedBigInteger('entity_id')->nullable();
            $table->string('operation_type', 50); // create, update, complete_visit, etc.
            $table->json('payload');
            $table->string('sync_status', 30)->default('synced'); // pending, synced, failed
            $table->text('error_message')->nullable();
            $table->timestamps();
        });

        Schema::create('documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('customer_id')->nullable()->constrained('customers')->cascadeOnDelete();
            $table->foreignId('asset_id')->nullable()->constrained('assets')->nullOnDelete();
            $table->foreignId('contract_id')->nullable()->constrained('contracts')->nullOnDelete();
            $table->foreignId('service_visit_id')->nullable()->constrained('service_visits')->nullOnDelete();
            $table->foreignId('invoice_id')->nullable()->constrained('invoices')->nullOnDelete();
            $table->string('title');
            $table->string('file_path');
            $table->string('file_type', 50)->default('pdf');
            $table->unsignedBigInteger('file_size')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('documents');
        Schema::dropIfExists('sync_operations');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('audit_logs');
    }
};
