<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\Customer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthenticationAndTenantTest extends TestCase
{
    /**
     * Test admin login returns Sanctum token and correct role.
     */
    public function test_admin_login_success(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@cooltech.com',
            'password' => 'Secret@123',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.role', 'admin')
            ->assertJsonStructure([
                'data' => [
                    'token',
                    'user' => ['id', 'email', 'role'],
                    'company' => ['id', 'name'],
                ],
            ]);
    }

    /**
     * Test invalid password returns 401.
     */
    public function test_login_with_invalid_password(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@cooltech.com',
            'password' => 'WrongPassword',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    /**
     * Test technician cannot create customer (admin only).
     */
    public function test_technician_cannot_create_customer(): void
    {
        $tech = User::where('email', 'rahul.tech@cooltech.com')->first();
        $token = $tech->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/customers', [
                'name' => 'Unauthorized Customer',
                'phone' => '+91 99999 88888',
                'address_line_1' => 'Road 1',
                'city' => 'Ahmedabad',
                'state' => 'Gujarat',
            ]);

        $response->assertStatus(403);
    }

    /**
     * Test customer cannot see another customer's data.
     */
    public function test_customer_isolation_from_other_customers(): void
    {
        $custUser1 = User::where('email', 'customer1@regency.com')->first();
        $cust2 = Customer::where('email', 'customer2@apexhealth.com')->first();

        $token = $custUser1->createToken('test')->plainTextToken;

        // Customer 1 attempts to access Customer 2 detail
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/customers/' . $cust2->id);

        $response->assertStatus(403);
    }
}
