<?php

namespace Database\Seeders;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\ChecklistItem;
use App\Models\ChecklistTemplate;
use App\Models\Company;
use App\Models\Contract;
use App\Models\Customer;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Models\Part;
use App\Models\Payment;
use App\Models\Permission;
use App\Models\RolePermission;
use App\Models\ServiceCategory;
use App\Models\ServiceRequest;
use App\Models\ServiceSchedule;
use App\Models\ServiceVisit;
use App\Models\ServiceVisitChecklistItem;
use App\Models\ServiceVisitPart;
use App\Models\ServiceVisitSignature;
use App\Models\User;
use App\Services\ContractCalculationService;
use App\Services\NumberingService;
use App\Services\PdfReportService;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Seed Permissions
        $permissions = [
            // Customers
            ['name' => 'customers.view', 'display_name' => 'View Customers', 'group' => 'customers'],
            ['name' => 'customers.create', 'display_name' => 'Create Customers', 'group' => 'customers'],
            ['name' => 'customers.edit', 'display_name' => 'Edit Customers', 'group' => 'customers'],
            ['name' => 'customers.delete', 'display_name' => 'Delete Customers', 'group' => 'customers'],
            // Assets
            ['name' => 'assets.view', 'display_name' => 'View Assets', 'group' => 'assets'],
            ['name' => 'assets.create', 'display_name' => 'Create Assets', 'group' => 'assets'],
            ['name' => 'assets.edit', 'display_name' => 'Edit Assets', 'group' => 'assets'],
            // Contracts
            ['name' => 'contracts.view', 'display_name' => 'View Contracts', 'group' => 'contracts'],
            ['name' => 'contracts.create', 'display_name' => 'Create Contracts', 'group' => 'contracts'],
            ['name' => 'contracts.edit', 'display_name' => 'Edit Contracts', 'group' => 'contracts'],
            ['name' => 'contracts.renew', 'display_name' => 'Renew Contracts', 'group' => 'contracts'],
            // Visits
            ['name' => 'visits.view', 'display_name' => 'View Visits', 'group' => 'visits'],
            ['name' => 'visits.start', 'display_name' => 'Start Visits', 'group' => 'visits'],
            ['name' => 'visits.complete', 'display_name' => 'Complete Visits', 'group' => 'visits'],
            // Invoices & Payments
            ['name' => 'invoices.view', 'display_name' => 'View Invoices', 'group' => 'invoices'],
            ['name' => 'invoices.create', 'display_name' => 'Create Invoices', 'group' => 'invoices'],
            ['name' => 'payments.view', 'display_name' => 'View Payments', 'group' => 'payments'],
            ['name' => 'payments.create', 'display_name' => 'Record Payments', 'group' => 'payments'],
            // Reports & Settings
            ['name' => 'reports.view', 'display_name' => 'View Reports', 'group' => 'reports'],
            ['name' => 'settings.manage', 'display_name' => 'Manage Settings', 'group' => 'settings'],
        ];

        foreach ($permissions as $p) {
            Permission::firstOrCreate(['name' => $p['name']], $p);
        }

        // Assign default role permissions
        $technicianPermissions = ['assets.view', 'visits.view', 'visits.start', 'visits.complete'];
        foreach ($technicianPermissions as $permName) {
            $perm = Permission::where('name', $permName)->first();
            if ($perm) {
                RolePermission::firstOrCreate(['role' => 'technician', 'permission_id' => $perm->id]);
            }
        }

        $customerPermissions = ['assets.view', 'contracts.view', 'visits.view', 'invoices.view', 'payments.view'];
        foreach ($customerPermissions as $permName) {
            $perm = Permission::where('name', $permName)->first();
            if ($perm) {
                RolePermission::firstOrCreate(['role' => 'customer', 'permission_id' => $perm->id]);
            }
        }

        // 2. Create Company
        $company = Company::firstOrCreate(
            ['name' => 'CoolTech Engineering Solutions'],
            [
                'business_type' => 'AC / HVAC',
                'email' => 'contact@cooltech-amc.com',
                'phone' => '+91 98765 43210',
                'website' => 'https://cooltech-amc.com',
                'address_line_1' => 'Plot 42, Tech Park Central',
                'city' => 'Ahmedabad',
                'state' => 'Gujarat',
                'country' => 'India',
                'postal_code' => '380015',
                'tax_number' => '24ABCDE1234F1Z5',
                'currency' => 'INR',
                'currency_symbol' => '₹',
                'timezone' => 'Asia/Kolkata',
                'primary_color' => '#1E40AF',
                'secondary_color' => '#0D9488',
                'customer_prefix' => 'CUST-',
                'contract_prefix' => 'AMC-',
                'service_request_prefix' => 'SR-',
                'service_visit_prefix' => 'VISIT-',
                'service_report_prefix' => 'SRPT-',
                'invoice_prefix' => 'INV-',
                'payment_prefix' => 'PAY-',
                'default_tax_rate' => 18.00,
                'tax_enabled' => true,
                'require_customer_signature' => true,
                'require_gps' => false,
                'require_service_photos' => true,
            ]
        );

        // 3. Create Admin User
        $admin = User::firstOrCreate(
            ['email' => 'admin@cooltech.com'],
            [
                'company_id' => $company->id,
                'name' => 'Rajesh Mehta',
                'phone' => '+91 98765 00001',
                'role' => 'admin',
                'status' => 'active',
                'password' => Hash::make('Secret@123'),
            ]
        );

        // 4. Create 3 Technicians
        $tech1 = User::firstOrCreate(
            ['email' => 'rahul.tech@cooltech.com'],
            [
                'company_id' => $company->id,
                'name' => 'Rahul Sharma',
                'phone' => '+91 98765 11111',
                'role' => 'technician',
                'skills' => ['Split AC', 'Cassette AC', 'Electrical'],
                'availability_status' => 'available',
                'status' => 'active',
                'password' => Hash::make('Secret@123'),
            ]
        );

        $tech2 = User::firstOrCreate(
            ['email' => 'amit.tech@cooltech.com'],
            [
                'company_id' => $company->id,
                'name' => 'Amit Patel',
                'phone' => '+91 98765 22222',
                'role' => 'technician',
                'skills' => ['Chiller Plants', 'Air Handling Units', 'Gas Charging'],
                'availability_status' => 'available',
                'status' => 'active',
                'password' => Hash::make('Secret@123'),
            ]
        );

        $tech3 = User::firstOrCreate(
            ['email' => 'vikas.tech@cooltech.com'],
            [
                'company_id' => $company->id,
                'name' => 'Vikas Kumar',
                'phone' => '+91 98765 33333',
                'role' => 'technician',
                'skills' => ['VRV / VRF Systems', 'Ductable Units'],
                'availability_status' => 'available',
                'status' => 'active',
                'password' => Hash::make('Secret@123'),
            ]
        );

        // 5. Create Asset Categories
        $catSplit = AssetCategory::firstOrCreate(['company_id' => $company->id, 'name' => 'Split AC'], ['description' => 'Hi-wall inverter & non-inverter split units']);
        $catCassette = AssetCategory::firstOrCreate(['company_id' => $company->id, 'name' => 'Cassette AC'], ['description' => 'Ceiling mounted cassette air conditioners']);
        $catVRV = AssetCategory::firstOrCreate(['company_id' => $company->id, 'name' => 'VRV / VRF System'], ['description' => 'Variable Refrigerant Volume multi-zone systems']);

        // 6. Create Service Categories
        $svcPM = ServiceCategory::firstOrCreate(['company_id' => $company->id, 'name' => 'Preventive Maintenance'], ['description' => 'Periodic cleaning, inspection, and performance testing', 'duration_estimate' => 90]);
        $svcBD = ServiceCategory::firstOrCreate(['company_id' => $company->id, 'name' => 'Breakdown Service'], ['description' => 'Emergency troubleshooting and corrective repair', 'duration_estimate' => 120]);
        $svcGas = ServiceCategory::firstOrCreate(['company_id' => $company->id, 'name' => 'Gas Charging & Leakage'], ['description' => 'Refrigerant replenishment and pressure testing', 'duration_estimate' => 60]);

        // 7. Create Checklist Template
        $template = ChecklistTemplate::firstOrCreate(
            ['company_id' => $company->id, 'name' => 'Comprehensive HVAC PM Checklist'],
            ['service_category_id' => $svcPM->id, 'description' => 'Standard 8-point maintenance checklist', 'active' => true]
        );

        $items = [
            ['title' => 'Air Filter Inspection & Cleaning', 'response_type' => 'checkbox', 'required' => true, 'sort_order' => 1],
            ['title' => 'Evaporator & Condenser Coil Cleaning', 'response_type' => 'checkbox', 'required' => true, 'sort_order' => 2],
            ['title' => 'Drain Tray & Pipe De-clogging', 'response_type' => 'pass_fail', 'required' => true, 'sort_order' => 3],
            ['title' => 'Suction & Discharge Gas Pressure Check (PSI)', 'response_type' => 'reading', 'required' => true, 'sort_order' => 4],
            ['title' => 'Electrical Contacts & Amperage Reading (Amps)', 'response_type' => 'reading', 'required' => true, 'sort_order' => 5],
            ['title' => 'Grille Cooling Temperature (°C)', 'response_type' => 'reading', 'required' => true, 'sort_order' => 6],
            ['title' => 'Thermostat & Remote Calibration', 'response_type' => 'pass_fail', 'required' => false, 'sort_order' => 7],
            ['title' => 'Overall Operational Performance Test', 'response_type' => 'pass_fail', 'required' => true, 'sort_order' => 8],
        ];

        foreach ($items as $it) {
            ChecklistItem::firstOrCreate(['template_id' => $template->id, 'title' => $it['title']], $it);
        }

        // 8. Create Parts Catalogue
        $parts = [
            ['part_code' => 'PRT-GAS-R410A', 'name' => 'Refrigerant Gas R410A', 'unit' => 'kg', 'default_price' => 850.00, 'tax_rate' => 18.00],
            ['part_code' => 'PRT-CAP-45MFD', 'name' => 'Run Capacitor 45 MFD', 'unit' => 'pcs', 'default_price' => 450.00, 'tax_rate' => 18.00],
            ['part_code' => 'PRT-CONTR-30A', 'name' => '2-Pole Contactor 30A', 'unit' => 'pcs', 'default_price' => 750.00, 'tax_rate' => 18.00],
            ['part_code' => 'PRT-FAN-MTR', 'name' => 'Outdoor Condenser Fan Motor', 'unit' => 'pcs', 'default_price' => 2200.00, 'tax_rate' => 18.00],
            ['part_code' => 'PRT-COP-PIPE', 'name' => 'Copper Pipe Insulated 1/2"', 'unit' => 'meter', 'default_price' => 380.00, 'tax_rate' => 18.00],
        ];

        foreach ($parts as $p) {
            Part::firstOrCreate(['company_id' => $company->id, 'part_code' => $p['part_code']], $p);
        }

        // 9. Create 5 Customers
        $customersData = [
            [
                'customer_code' => 'CUST-00001',
                'name' => 'Mr. Vikram Singhania',
                'company_name' => 'Regency Grand Luxury Hotel',
                'phone' => '+91 98250 11223',
                'email' => 'customer1@regency.com',
                'gst_number' => '24AAACR1234D1Z8',
                'address_line_1' => 'Opposite Riverfront Promenade, Ashram Road',
                'city' => 'Ahmedabad',
                'state' => 'Gujarat',
                'country' => 'India',
                'postal_code' => '380009',
            ],
            [
                'customer_code' => 'CUST-00002',
                'name' => 'Dr. Ananya Iyer',
                'company_name' => 'Apex Healthcare & Multi-Speciality Hospital',
                'phone' => '+91 98250 22334',
                'email' => 'customer2@apexhealth.com',
                'gst_number' => '24AABCA5678E1Z9',
                'address_line_1' => 'SG Highway, Bodakdev',
                'city' => 'Ahmedabad',
                'state' => 'Gujarat',
                'country' => 'India',
                'postal_code' => '380054',
            ],
            [
                'customer_code' => 'CUST-00003',
                'name' => 'Kunal Joshi',
                'company_name' => 'Innovate Hub Coworking Spaces',
                'phone' => '+91 98250 33445',
                'email' => 'customer3@innovatehub.com',
                'address_line_1' => '5th Floor, Westgate Business Bay',
                'city' => 'Ahmedabad',
                'state' => 'Gujarat',
                'country' => 'India',
                'postal_code' => '380051',
            ],
            [
                'customer_code' => 'CUST-00004',
                'name' => 'Pradeep Kothari',
                'company_name' => 'Shreeji Pharmaceuticals Pvt Ltd',
                'phone' => '+91 98250 44556',
                'email' => 'customer4@shreejipharma.com',
                'address_line_1' => 'Sanand Industrial Estate GIDC Gate 2',
                'city' => 'Sanand',
                'state' => 'Gujarat',
                'country' => 'India',
                'postal_code' => '382110',
            ],
            [
                'customer_code' => 'CUST-00005',
                'name' => 'Sunita Rao',
                'company_name' => 'Emerald Heights Residences',
                'phone' => '+91 98250 55667',
                'email' => 'customer5@emerald.com',
                'address_line_1' => 'Bopal Ambli Road',
                'city' => 'Ahmedabad',
                'state' => 'Gujarat',
                'country' => 'India',
                'postal_code' => '380058',
            ],
        ];

        $seededCustomers = [];
        foreach ($customersData as $cd) {
            $cust = Customer::firstOrCreate(
                ['company_id' => $company->id, 'customer_code' => $cd['customer_code']],
                array_merge($cd, ['status' => 'active'])
            );
            $seededCustomers[] = $cust;

            // Create client portal login user
            User::firstOrCreate(
                ['email' => $cd['email']],
                [
                    'company_id' => $company->id,
                    'customer_id' => $cust->id,
                    'name' => $cust->name,
                    'phone' => $cust->phone,
                    'role' => 'customer',
                    'status' => 'active',
                    'password' => Hash::make('Customer@123'),
                ]
            );
        }

        // 10. Create 10 Assets
        $assetsData = [
            // Regency Grand (Customer 0)
            ['cust_idx' => 0, 'code' => 'AC-001', 'type' => 'Cassette AC 3.0 TR', 'brand' => 'Daikin', 'model' => 'FCQ71K', 'sn' => 'DAIK-882910', 'loc' => 'Main Reception Lobby', 'cat_id' => $catCassette->id],
            ['cust_idx' => 0, 'code' => 'AC-002', 'type' => 'Cassette AC 3.0 TR', 'brand' => 'Daikin', 'model' => 'FCQ71K', 'sn' => 'DAIK-882911', 'loc' => 'Restaurant Dining Area', 'cat_id' => $catCassette->id],
            ['cust_idx' => 0, 'code' => 'AC-003', 'type' => 'VRV Outdoor 16 HP', 'brand' => 'Daikin', 'model' => 'RXYQ16', 'sn' => 'DAIK-VRV-001', 'loc' => 'Rooftop West Wing', 'cat_id' => $catVRV->id],

            // Apex Healthcare (Customer 1)
            ['cust_idx' => 1, 'code' => 'AC-004', 'type' => 'Ductable Inverter 5.5 TR', 'brand' => 'Carrier', 'model' => 'CD55TR', 'sn' => 'CARR-994821', 'loc' => 'Operation Theatre 1', 'cat_id' => $catVRV->id],
            ['cust_idx' => 1, 'code' => 'AC-005', 'type' => 'Split AC 2.0 TR', 'brand' => 'Voltas', 'model' => 'V-245V', 'sn' => 'VOLT-332910', 'loc' => 'ICU Observation Room', 'cat_id' => $catSplit->id],

            // Innovate Hub (Customer 2)
            ['cust_idx' => 2, 'code' => 'AC-006', 'type' => 'Cassette AC 4.0 TR', 'brand' => 'Mitsubishi', 'model' => 'PL-4TR', 'sn' => 'MITS-110293', 'loc' => 'Open Coworking Zone A', 'cat_id' => $catCassette->id],
            ['cust_idx' => 2, 'code' => 'AC-007', 'type' => 'Split AC 1.5 TR', 'brand' => 'O General', 'model' => 'ASGA18', 'sn' => 'OGEN-773821', 'loc' => 'Conference Room Alpha', 'cat_id' => $catSplit->id],

            // Shreeji Pharma (Customer 3)
            ['cust_idx' => 3, 'code' => 'AC-008', 'type' => 'Precision AC 7.5 TR', 'brand' => 'Blue Star', 'model' => 'PAC-75', 'sn' => 'BLUE-662910', 'loc' => 'Formulation Clean Room', 'cat_id' => $catVRV->id],
            ['cust_idx' => 3, 'code' => 'AC-009', 'type' => 'Split AC 2.0 TR', 'brand' => 'Blue Star', 'model' => 'IA524', 'sn' => 'BLUE-662911', 'loc' => 'Quality Control Lab', 'cat_id' => $catSplit->id],

            // Emerald Heights (Customer 4)
            ['cust_idx' => 4, 'code' => 'AC-010', 'type' => 'Inverter Split 1.5 TR', 'brand' => 'Hitachi', 'model' => 'RAW518', 'sn' => 'HITA-440291', 'loc' => 'Clubhouse Gym', 'cat_id' => $catSplit->id],
        ];

        $seededAssets = [];
        foreach ($assetsData as $ad) {
            $cust = $seededCustomers[$ad['cust_idx']];
            $asset = Asset::firstOrCreate(
                ['company_id' => $company->id, 'asset_code' => $ad['code']],
                [
                    'customer_id' => $cust->id,
                    'category_id' => $ad['cat_id'],
                    'asset_type' => $ad['type'],
                    'brand' => $ad['brand'],
                    'model' => $ad['model'],
                    'serial_number' => $ad['sn'],
                    'capacity' => 'Standard Capacity',
                    'installation_date' => Carbon::now()->subMonths(18)->toDateString(),
                    'purchase_date' => Carbon::now()->subMonths(20)->toDateString(),
                    'warranty_start' => Carbon::now()->subMonths(18)->toDateString(),
                    'warranty_end' => Carbon::now()->subMonths(6)->toDateString(),
                    'location' => $ad['loc'],
                    'qr_token' => (string) Str::uuid(),
                    'status' => 'active',
                ]
            );
            $seededAssets[] = $asset;
        }

        // 11. Create 5 AMC Contracts & Schedules
        $calcService = new ContractCalculationService();
        $pdfService = new PdfReportService();

        // Contract 1: Regency Grand Hotel - 12 Months Comprehensive AMC, Quarterly (4 visits)
        $start1 = Carbon::now()->subMonths(3)->toDateString();
        $end1 = $calcService->calculateEndDate($start1, '12_months');
        $contract1 = Contract::firstOrCreate(
            ['company_id' => $company->id, 'contract_number' => 'AMC-2026-000001'],
            [
                'customer_id' => $seededCustomers[0]->id,
                'title' => 'Annual Comprehensive HVAC Maintenance Agreement',
                'start_date' => $start1,
                'end_date' => $end1,
                'duration_type' => '12_months',
                'service_frequency' => 'quarterly',
                'first_visit_rule' => 'start_date',
                'visit_count_type' => 'automatic',
                'total_price' => 72000.00,
                'billing_type' => 'fixed',
                'coverage_parts' => 'included',
                'coverage_emergency_visits' => 'included',
                'coverage_breakdown_visits' => 'included',
                'coverage_labour' => 'included',
                'exclusions' => 'Compressor coil replacement and external physical casing damage excluded.',
                'sla_response_time' => '4_hours',
                'sla_response_hours' => 4,
                'status' => 'active',
            ]
        );
        $contract1->assets()->sync([$seededAssets[0]->id, $seededAssets[1]->id, $seededAssets[2]->id]);

        $dates1 = $calcService->generateScheduledDates($start1, $end1, 'quarterly', null, 'start_date');
        $techs = [$tech1, $tech2, $tech3];

        foreach ($dates1 as $idx => $vDate) {
            $status = $idx === 0 ? 'completed' : ($idx === 1 ? 'scheduled' : 'scheduled');
            $sched = ServiceSchedule::firstOrCreate(
                ['contract_id' => $contract1->id, 'scheduled_date' => $vDate],
                [
                    'company_id' => $company->id,
                    'customer_id' => $contract1->customer_id,
                    'asset_id' => $seededAssets[0]->id,
                    'service_category_id' => $svcPM->id,
                    'technician_id' => $techs[$idx % 3]->id,
                    'scheduled_time_start' => '10:00:00',
                    'scheduled_time_end' => '12:00:00',
                    'visit_type' => 'amc_preventive',
                    'status' => $status,
                    'priority' => 'normal',
                ]
            );

            // If visit 0 is completed, build real completed ServiceVisit record with PDF!
            if ($idx === 0) {
                $vNum = 'VISIT-2026-000001';
                $rNum = 'SRPT-2026-000001';
                $visit = ServiceVisit::firstOrCreate(
                    ['company_id' => $company->id, 'visit_number' => $vNum],
                    [
                        'schedule_id' => $sched->id,
                        'contract_id' => $contract1->id,
                        'customer_id' => $contract1->customer_id,
                        'asset_id' => $seededAssets[0]->id,
                        'technician_id' => $tech1->id,
                        'service_category_id' => $svcPM->id,
                        'status' => 'completed',
                        'started_at' => Carbon::parse($vDate)->setTime(10, 5),
                        'completed_at' => Carbon::parse($vDate)->setTime(11, 45),
                        'start_latitude' => 23.0225,
                        'start_longitude' => 72.5714,
                        'completion_latitude' => 23.0226,
                        'completion_longitude' => 72.5715,
                        'work_performed' => 'Cleaned pre-filters, disinfected condenser coils, checked refrigerant charge, calibrated fan motor.',
                        'findings' => 'Airflow velocity restored to optimal 450 CFM. No gas leaks detected.',
                        'recommendations' => 'Keep return air louvers free of dust obstruction.',
                        'customer_remarks' => 'Technician arrived promptly and completed maintenance neatly.',
                        'is_chargeable' => false,
                        'visit_charge' => 0.00,
                        'report_number' => $rNum,
                    ]
                );

                // Add checklist responses
                foreach ($items as $chkItem) {
                    ServiceVisitChecklistItem::firstOrCreate(
                        ['service_visit_id' => $visit->id, 'title' => $chkItem['title']],
                        [
                            'response_type' => $chkItem['response_type'],
                            'required' => $chkItem['required'],
                            'value' => match ($chkItem['response_type']) {
                                'reading' => '65 PSI / 8.2 A / 14°C',
                                'pass_fail' => 'Passed',
                                default => 'Cleaned & Checked',
                            },
                            'is_passed' => true,
                        ]
                    );
                }

                // Add Part
                ServiceVisitPart::firstOrCreate(
                    ['service_visit_id' => $visit->id, 'part_name' => 'Run Capacitor 45 MFD'],
                    [
                        'quantity' => 1.00,
                        'unit_price' => 450.00,
                        'total_price' => 450.00,
                        'coverage_type' => 'included',
                        'notes' => 'Preventive replacement during AMC',
                    ]
                );

                // Add Signature
                ServiceVisitSignature::firstOrCreate(
                    ['service_visit_id' => $visit->id],
                    [
                        'signature_image_path' => 'signatures/demo_signature.png',
                        'signed_by_name' => 'Vikram Singhania (Hotel Manager)',
                        'signed_at' => Carbon::parse($vDate)->setTime(11, 45),
                    ]
                );

                // Compile real PDF report file
                $pdfService->generateServiceReport($visit);
            }
        }

        // Contract 2: Apex Healthcare - 6 Months, Monthly visits
        $start2 = Carbon::now()->subMonths(1)->toDateString();
        $end2 = $calcService->calculateEndDate($start2, '6_months');
        $contract2 = Contract::firstOrCreate(
            ['company_id' => $company->id, 'contract_number' => 'AMC-2026-000002'],
            [
                'customer_id' => $seededCustomers[1]->id,
                'title' => 'Critical Care HVAC Semi-Annual Contract',
                'start_date' => $start2,
                'end_date' => $end2,
                'duration_type' => '6_months',
                'service_frequency' => 'monthly',
                'first_visit_rule' => 'start_date',
                'visit_count_type' => 'automatic',
                'total_price' => 45000.00,
                'billing_type' => 'fixed',
                'coverage_parts' => 'excluded',
                'coverage_emergency_visits' => 'included',
                'sla_response_time' => '4_hours',
                'sla_response_hours' => 4,
                'status' => 'active',
            ]
        );
        $contract2->assets()->sync([$seededAssets[3]->id, $seededAssets[4]->id]);

        // Contract 3: Expiring Soon Contract (Demonstrates Section 53 Renewal Cohorts)
        $start3 = Carbon::now()->subMonths(11)->subDays(20)->toDateString();
        $end3 = Carbon::now()->addDays(10)->toDateString(); // Expiring in 10 days! (Cohort 8-30 days)
        $contract3 = Contract::firstOrCreate(
            ['company_id' => $company->id, 'contract_number' => 'AMC-2025-000088'],
            [
                'customer_id' => $seededCustomers[2]->id,
                'title' => 'Innovate Hub Annual Coworking AMC',
                'start_date' => $start3,
                'end_date' => $end3,
                'duration_type' => '12_months',
                'service_frequency' => 'quarterly',
                'first_visit_rule' => 'start_date',
                'total_price' => 38000.00,
                'status' => 'active',
            ]
        );
        $contract3->assets()->sync([$seededAssets[5]->id, $seededAssets[6]->id]);

        // 12. Create Invoices and Payments
        $inv1 = Invoice::firstOrCreate(
            ['company_id' => $company->id, 'invoice_number' => 'INV-2026-000001'],
            [
                'customer_id' => $seededCustomers[0]->id,
                'contract_id' => $contract1->id,
                'invoice_type' => 'amc',
                'issue_date' => $start1,
                'due_date' => Carbon::parse($start1)->addDays(15)->toDateString(),
                'subtotal' => 72000.00,
                'discount_amount' => 2000.00,
                'discount_type' => 'fixed',
                'taxable_amount' => 70000.00,
                'tax_rate' => 18.00,
                'tax_amount' => 12600.00,
                'total_amount' => 82600.00,
                'paid_amount' => 50000.00,
                'balance_due' => 32600.00,
                'status' => 'partially_paid',
                'notes' => '12-Month Comprehensive AMC Invoicing for Regency Grand Hotel',
            ]
        );

        InvoiceItem::firstOrCreate(
            ['invoice_id' => $inv1->id, 'description' => '12-Month Annual Maintenance Contract (HVAC Units)'],
            ['item_type' => 'amc_contract', 'quantity' => 1.00, 'unit_price' => 72000.00, 'total_price' => 72000.00]
        );

        Payment::firstOrCreate(
            ['company_id' => $company->id, 'payment_number' => 'PAY-2026-000001'],
            [
                'invoice_id' => $inv1->id,
                'customer_id' => $inv1->customer_id,
                'amount' => 50000.00,
                'payment_date' => Carbon::parse($start1)->addDays(5)->toDateString(),
                'payment_method' => 'bank_transfer',
                'transaction_reference' => 'NEFT-HDFC-99182301',
                'notes' => 'Advance milestone payment 60%',
                'recorded_by_user_id' => $admin->id,
            ]
        );

        // 13. Create Open Service Request (Complaint)
        ServiceRequest::firstOrCreate(
            ['company_id' => $company->id, 'request_number' => 'SR-2026-000001'],
            [
                'customer_id' => $seededCustomers[0]->id,
                'asset_id' => $seededAssets[1]->id,
                'contract_id' => $contract1->id,
                'title' => 'Abnormal V-Belt Noise in Dining Area Unit',
                'description' => 'Loud squeaking noise audible when blower fan engages at full speed.',
                'issue_type' => 'Abnormal Noise',
                'priority' => 'high',
                'preferred_date' => Carbon::now()->addDay()->toDateString(),
                'preferred_time' => '10:00 AM - 12:00 PM',
                'assigned_technician_id' => $tech1->id,
                'status' => 'assigned',
                'is_covered_under_amc' => true,
                'sla_due_at' => Carbon::now()->addHours(8),
            ]
        );
    }
}
