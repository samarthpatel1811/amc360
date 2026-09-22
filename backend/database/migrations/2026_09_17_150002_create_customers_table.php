<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->cascadeOnDelete();
            $table->string('customer_code', 50)->index();
            $table->string('customer_type', 30)->default('commercial'); // 'commercial', 'residential', 'industrial'
            $table->string('name');
            $table->string('company_name')->nullable();
            $table->string('phone', 30)->index();
            $table->string('alternate_phone', 30)->nullable();
            $table->string('email')->nullable();
            $table->string('gst_number', 50)->nullable();
            $table->string('address_line_1');
            $table->string('address_line_2')->nullable();
            $table->string('city', 100);
            $table->string('state', 100);
            $table->string('country', 100)->default('India');
            $table->string('postal_code', 20)->nullable();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->text('notes')->nullable();
            $table->string('status', 30)->default('active')->index(); // 'active', 'inactive', 'archived'
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['company_id', 'customer_code']);
        });

        // Add foreign key from users.customer_id to customers.id
        Schema::table('users', function (Blueprint $table) {
            $table->foreign('customer_id')->references('id')->on('customers')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['customer_id']);
        });
        Schema::dropIfExists('customers');
    }
};
