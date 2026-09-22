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
        Schema::create('companies', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('business_type')->default('AC / HVAC');
            $table->string('custom_business_type')->nullable();
            $table->string('email')->nullable();
            $table->string('phone')->nullable();
            $table->string('website')->nullable();
            $table->string('address_line_1')->nullable();
            $table->string('address_line_2')->nullable();
            $table->string('city')->nullable();
            $table->string('state')->nullable();
            $table->string('country')->default('India');
            $table->string('postal_code')->nullable();
            $table->string('tax_number')->nullable(); // GST / VAT
            $table->string('currency', 10)->default('INR');
            $table->string('currency_symbol', 10)->default('₹');
            $table->string('timezone')->default('Asia/Kolkata');
            $table->string('primary_color', 20)->default('#1E40AF'); // Deep Royal Blue
            $table->string('secondary_color', 20)->default('#0D9488'); // Teal
            $table->string('logo_url')->nullable();
            $table->string('invoice_logo_url')->nullable();
            $table->string('report_logo_url')->nullable();
            $table->string('customer_prefix', 20)->default('CUST-');
            $table->string('contract_prefix', 20)->default('AMC-');
            $table->string('service_request_prefix', 20)->default('SR-');
            $table->string('service_visit_prefix', 20)->default('VISIT-');
            $table->string('service_report_prefix', 20)->default('SRPT-');
            $table->string('invoice_prefix', 20)->default('INV-');
            $table->string('payment_prefix', 20)->default('PAY-');
            $table->decimal('default_tax_rate', 5, 2)->default(18.00);
            $table->boolean('tax_enabled')->default(true);
            $table->boolean('require_customer_signature')->default(true);
            $table->boolean('require_gps')->default(false);
            $table->boolean('require_service_photos')->default(false);
            $table->timestamps();
        });

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->unsignedBigInteger('customer_id')->nullable()->index();
            $table->string('name');
            $table->string('email');
            $table->string('phone')->nullable();
            $table->string('role', 30)->default('admin'); // 'admin', 'technician', 'customer'
            $table->json('skills')->nullable(); // For technicians: ['AC', 'Electrical']
            $table->string('availability_status', 30)->default('available'); // 'available', 'busy', 'on_leave', 'inactive'
            $table->string('status', 30)->default('active'); // 'active', 'inactive'
            $table->string('avatar_url')->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
            $table->timestamps();

            $table->unique(['company_id', 'email']);
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');
        Schema::dropIfExists('companies');
    }
};
