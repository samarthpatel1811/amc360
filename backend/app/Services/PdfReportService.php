<?php

namespace App\Services;

use App\Models\ServiceVisit;
use App\Models\Invoice;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Storage;

class PdfReportService
{
    /**
     * Generate PDF Service Report and store in storage/app/public/reports.
     */
    public function generateServiceReport(ServiceVisit $visit): string
    {
        $visit->load([
            'company',
            'customer',
            'asset',
            'contract',
            'technician',
            'serviceCategory',
            'checklistItems',
            'parts',
            'signature',
        ]);

        $company = $visit->company;
        $pdf = Pdf::loadView('reports.service_report', [
            'visit' => $visit,
            'company' => $company,
        ]);

        $filename = 'reports/service_report_' . $visit->report_number . '.pdf';
        Storage::disk('public')->put($filename, $pdf->output());

        $visit->report_pdf_path = 'storage/' . $filename;
        $visit->save();

        return $visit->report_pdf_path;
    }
}
