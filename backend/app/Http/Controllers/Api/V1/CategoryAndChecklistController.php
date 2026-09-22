<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\AssetCategory;
use App\Models\ChecklistTemplate;
use App\Models\Part;
use App\Models\ServiceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryAndChecklistController extends BaseApiController
{
    public function assetCategories(): JsonResponse
    {
        return $this->successResponse(AssetCategory::all());
    }

    public function serviceCategories(): JsonResponse
    {
        return $this->successResponse(ServiceCategory::where('active', true)->get());
    }

    public function checklistTemplates(): JsonResponse
    {
        return $this->successResponse(ChecklistTemplate::where('active', true)->with('items')->get());
    }

    public function parts(): JsonResponse
    {
        return $this->successResponse(Part::where('active', true)->get());
    }
}
