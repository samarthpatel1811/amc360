<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Service Report - {{ $visit->report_number }}</title>
    <style>
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            color: #333;
            font-size: 12px;
            line-height: 1.4;
            margin: 0;
            padding: 20px;
        }
        .header {
            border-bottom: 2px solid {{ $company->primary_color ?? '#1E40AF' }};
            padding-bottom: 12px;
            margin-bottom: 18px;
        }
        .company-title {
            font-size: 20px;
            font-weight: bold;
            color: {{ $company->primary_color ?? '#1E40AF' }};
        }
        .badge {
            display: inline-block;
            padding: 3px 8px;
            font-size: 11px;
            font-weight: bold;
            color: #fff;
            background-color: #10B981;
            border-radius: 4px;
        }
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 14px;
        }
        .table th, .table td {
            border: 1px solid #E5E7EB;
            padding: 6px 8px;
            text-align: left;
        }
        .table th {
            background-color: #F3F4F6;
            font-weight: 600;
        }
        .section-title {
            font-size: 13px;
            font-weight: bold;
            color: {{ $company->primary_color ?? '#1E40AF' }};
            border-bottom: 1px solid #E5E7EB;
            padding-bottom: 4px;
            margin-top: 14px;
            margin-bottom: 8px;
            text-transform: uppercase;
        }
        .signature-box {
            border: 1px dashed #9CA3AF;
            padding: 8px;
            width: 200px;
            height: 70px;
            text-align: center;
        }
        .signature-img {
            max-width: 180px;
            max-height: 60px;
        }
    </style>
</head>
<body>
    <div class="header">
        <table style="width: 100%;">
            <tr>
                <td>
                    <div class="company-title">{{ $company->name }}</div>
                    <div>{{ $company->address_line_1 }}, {{ $company->city }}, {{ $company->state }}</div>
                    <div>Phone: {{ $company->phone }} | Email: {{ $company->email }}</div>
                    @if($company->tax_number)
                        <div>GST/Tax Reg: <strong>{{ $company->tax_number }}</strong></div>
                    @endif
                </td>
                <td style="text-align: right; vertical-align: top;">
                    <div style="font-size: 16px; font-weight: bold; color: #111827;">SERVICE REPORT</div>
                    <div style="font-size: 12px; color: #6B7280;">Report #: <strong>{{ $visit->report_number }}</strong></div>
                    <div style="font-size: 12px; color: #6B7280;">Visit #: {{ $visit->visit_number }}</div>
                    <div style="font-size: 12px; color: #6B7280;">Date: {{ $visit->completed_at ? $visit->completed_at->format('d M Y') : date('d M Y') }}</div>
                    <div class="badge">COMPLETED</div>
                </td>
            </tr>
        </table>
    </div>

    <!-- Customer & Equipment Info -->
    <table class="table">
        <tr>
            <th style="width: 50%;">CUSTOMER DETAILS</th>
            <th style="width: 50%;">EQUIPMENT / ASSET DETAILS</th>
        </tr>
        <tr>
            <td>
                <strong>{{ $visit->customer->name }}</strong><br>
                @if($visit->customer->company_name)
                    {{ $visit->customer->company_name }}<br>
                @endif
                Phone: {{ $visit->customer->phone }}<br>
                Address: {{ $visit->customer->address_line_1 }}, {{ $visit->customer->city }}<br>
                Customer Code: {{ $visit->customer->customer_code }}
            </td>
            <td>
                <strong>Asset Code: {{ $visit->asset->asset_code }}</strong><br>
                Type: {{ $visit->asset->asset_type }}<br>
                Brand / Model: {{ $visit->asset->brand }} {{ $visit->asset->model }}<br>
                Serial Number: <strong>{{ $visit->asset->serial_number }}</strong><br>
                Location: {{ $visit->asset->location ?? 'On Site' }}
            </td>
        </tr>
    </table>

    <!-- Contract & Service Details -->
    <table class="table">
        <tr>
            <th style="width: 25%;">Contract</th>
            <th style="width: 25%;">Service Type</th>
            <th style="width: 25%;">Technician</th>
            <th style="width: 25%;">Service Window</th>
        </tr>
        <tr>
            <td>{{ $visit->contract ? $visit->contract->contract_number : 'Non-AMC / Chargeable' }}</td>
            <td>{{ $visit->serviceCategory ? $visit->serviceCategory->name : 'Preventive Maintenance' }}</td>
            <td>{{ $visit->technician->name }} ({{ $visit->technician->phone }})</td>
            <td>{{ $visit->started_at->format('H:i') }} - {{ $visit->completed_at ? $visit->completed_at->format('H:i') : '-' }}</td>
        </tr>
    </table>

    <!-- Checklist -->
    @if($visit->checklistItems->isNotEmpty())
        <div class="section-title">Maintenance Checklist</div>
        <table class="table">
            <thead>
                <tr>
                    <th style="width: 10%;">#</th>
                    <th style="width: 60%;">Checklist Item</th>
                    <th style="width: 30%;">Result / Reading</th>
                </tr>
            </thead>
            <tbody>
                @foreach($visit->checklistItems as $idx => $item)
                    <tr>
                        <td>{{ $idx + 1 }}</td>
                        <td>{{ $item->title }}</td>
                        <td>
                            @if($item->response_type === 'pass_fail')
                                <strong style="color: {{ $item->is_passed ? '#10B981' : '#EF4444' }};">
                                    {{ $item->is_passed ? 'PASSED' : 'FAILED' }}
                                </strong>
                            @else
                                {{ $item->value ?? 'Checked' }}
                            @endif
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @endif

    <!-- Notes & Observations -->
    <div class="section-title">Work Summary & Technical Observations</div>
    <table class="table">
        <tr>
            <td style="width: 50%;">
                <strong>Work Performed:</strong><br>
                {{ $visit->work_performed ?: 'Preventive maintenance performed per manufacturer checklist.' }}
            </td>
            <td style="width: 50%;">
                <strong>Findings & Condition:</strong><br>
                {{ $visit->findings ?: 'Equipment running within standard operational tolerances.' }}
            </td>
        </tr>
        <tr>
            <td>
                <strong>Recommendations:</strong><br>
                {{ $visit->recommendations ?: 'Continue regular quarterly maintenance.' }}
            </td>
            <td>
                <strong>Customer Remarks:</strong><br>
                {{ $visit->customer_remarks ?: 'Work completed satisfactorily.' }}
            </td>
        </tr>
    </table>

    <!-- Parts Used -->
    @if($visit->parts->isNotEmpty())
        <div class="section-title">Parts / Materials Used</div>
        <table class="table">
            <thead>
                <tr>
                    <th>Part Name</th>
                    <th>Qty</th>
                    <th>Coverage</th>
                    <th>Unit Price</th>
                    <th>Total Price</th>
                </tr>
            </thead>
            <tbody>
                @foreach($visit->parts as $part)
                    <tr>
                        <td>{{ $part->part_name }}</td>
                        <td>{{ $part->quantity }}</td>
                        <td>
                            <strong>{{ strtoupper(str_replace('_', ' ', $part->coverage_type)) }}</strong>
                        </td>
                        <td>{{ $company->currency_symbol }} {{ number_format($part->unit_price, 2) }}</td>
                        <td>{{ $company->currency_symbol }} {{ number_format($part->total_price, 2) }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @endif

    <!-- Signatures -->
    <div class="section-title">Signatures & Acknowledgement</div>
    <table style="width: 100%; margin-top: 10px;">
        <tr>
            <td style="width: 50%; vertical-align: top;">
                <strong>Technician:</strong> {{ $visit->technician->name }}<br>
                <span>Completed: {{ $visit->completed_at ? $visit->completed_at->format('d M Y, H:i') : '' }}</span>
            </td>
            <td style="width: 50%; text-align: right; vertical-align: top;">
                <strong>Customer Representative:</strong><br>
                @if($visit->signature)
                    <div style="font-weight: 600;">{{ $visit->signature->signed_by_name }}</div>
                    <div style="font-size: 11px; color: #6B7280;">Signed on: {{ $visit->signature->signed_at->format('d M Y, H:i') }}</div>
                    @if(file_exists(storage_path('app/' . $visit->signature->signature_image_path)))
                        <img src="{{ storage_path('app/' . $visit->signature->signature_image_path) }}" class="signature-img" style="border: 1px solid #ddd; margin-top: 4px;"><br>
                    @endif
                @else
                    <div style="color: #6B7280; font-style: italic;">Customer signature recorded digitally</div>
                @endif
            </td>
        </tr>
    </table>
</body>
</html>
