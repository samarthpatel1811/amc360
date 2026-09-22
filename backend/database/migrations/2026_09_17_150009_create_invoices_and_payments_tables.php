<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('invoices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->foreignId('contract_id')->nullable()->constrained('contracts')->nullOnDelete();
            $table->foreignId('service_visit_id')->nullable()->constrained('service_visits')->nullOnDelete();
            $table->string('invoice_number', 50)->index();
            $table->string('invoice_type', 30)->default('amc'); // amc, service, parts, extra_visit, combined
            $table->date('issue_date')->index();
            $table->date('due_date')->index();
            $table->decimal('subtotal', 12, 2)->default(0.00);
            $table->decimal('discount_amount', 12, 2)->default(0.00);
            $table->string('discount_type', 20)->default('fixed'); // fixed, percentage
            $table->decimal('taxable_amount', 12, 2)->default(0.00);
            $table->decimal('tax_rate', 5, 2)->default(18.00); // Historical rate preserved
            $table->decimal('tax_amount', 12, 2)->default(0.00);
            $table->decimal('total_amount', 12, 2)->default(0.00);
            $table->decimal('paid_amount', 12, 2)->default(0.00);
            $table->decimal('balance_due', 12, 2)->default(0.00);
            $table->string('status', 30)->default('draft')->index(); // draft, issued, partially_paid, paid, overdue, cancelled
            $table->text('notes')->nullable();
            $table->string('pdf_path')->nullable();
            $table->timestamps();

            $table->unique(['company_id', 'invoice_number']);
        });

        Schema::create('invoice_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('invoice_id')->constrained('invoices')->cascadeOnDelete();
            $table->string('description');
            $table->string('item_type', 30)->default('custom'); // amc_contract, service_visit, part, custom
            $table->decimal('quantity', 8, 2)->default(1.00);
            $table->decimal('unit_price', 12, 2)->default(0.00);
            $table->decimal('total_price', 12, 2)->default(0.00);
            $table->timestamps();
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->foreignId('invoice_id')->constrained('invoices')->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->string('payment_number', 50)->index();
            $table->decimal('amount', 12, 2);
            $table->date('payment_date')->index();
            $table->string('payment_method', 30)->default('bank_transfer'); // cash, upi, bank_transfer, card, cheque, other
            $table->string('transaction_reference')->nullable();
            $table->text('notes')->nullable();
            $table->foreignId('recorded_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->unique(['company_id', 'payment_number']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
        Schema::dropIfExists('invoice_items');
        Schema::dropIfExists('invoices');
    }
};
