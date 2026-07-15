#Requires -Version 7.0

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendTf = Join-Path $scriptDir "backend.tf"

if (-not (Test-Path $backendTf)) {
    Write-Error "backend.tf not found at $backendTf"
}

$activeAccount = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
if (-not $activeAccount) {
    Write-Error "Not logged in to Google Cloud. Run 'gcloud auth login' first."
}

function Read-BackendValue {
    param([string]$Key)

    $line = Select-String -Path $backendTf -Pattern $Key | Select-Object -First 1
    if (-not $line) {
        Write-Error "Could not read '$Key' from $backendTf"
    }

    if ($line.Line -match '=\s*"([^"]+)"') {
        return $Matches[1]
    }

    Write-Error "Could not parse '$Key' from $backendTf"
}

function Test-BucketExists {
    param([string]$Name)

    gcloud storage buckets describe "gs://$Name" 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
}

function Select-Project {
    $projects = @(gcloud projects list --format="csv[no-heading](projectId,name)")

    if ($projects.Count -eq 0) {
        Write-Error "No GCP projects found."
    }

    Write-Host "Available GCP projects:"
    Write-Host ""

    for ($index = 0; $index -lt $projects.Count; $index++) {
        $parts = $projects[$index] -split ",", 2
        $number = $index + 1
        Write-Host "  $number) $($parts[0])"
        if ($parts.Count -gt 1) {
            Write-Host "     $($parts[1])"
        }
        Write-Host ""
    }

    while ($true) {
        $choice = Read-Host "Select project [1-$($projects.Count)]"
        if ($choice -match '^\d+$') {
            $selectedIndex = [int]$choice - 1
            if ($selectedIndex -ge 0 -and $selectedIndex -lt $projects.Count) {
                $projectId = ($projects[$selectedIndex] -split ",", 2)[0]
                gcloud config set project $projectId | Out-Null
                Write-Host ""
                Write-Host "Using project: $projectId"
                Write-Host ""
                return
            }
        }

        Write-Warning "Invalid selection. Enter a number between 1 and $($projects.Count)."
    }
}

Select-Project

$projectId = gcloud config get-value project 2>$null
$statePrefix = Read-BackendValue "prefix"
$bucket = Read-BackendValue "bucket"

Write-Host "This will permanently delete the Terraform remote state backend:"
Write-Host "  Project:          $projectId"
Write-Host "  State bucket:     $bucket"
Write-Host "  State prefix:     $statePrefix"
Write-Host ""
Write-Host "Run 'terraform destroy' in this directory before cleanup when possible."
Write-Host "The entire state bucket is removed, including all objects and versions."
Write-Host ""

$confirm = Read-Host "Type 'yes' to permanently delete these resources"
if ($confirm -ne "yes") {
    Write-Host "Cleanup cancelled."
    exit 0
}

Write-Host ""

if (Test-BucketExists $bucket) {
    Write-Host "Deleting all objects in state bucket: $bucket"
    gcloud storage rm -r "gs://$bucket/**" --all-versions --quiet 2>$null
    if ($LASTEXITCODE -ne 0) {
        $null = $LASTEXITCODE
    }

    Write-Host "Deleting state bucket: $bucket"
    gcloud storage buckets delete "gs://$bucket" --quiet | Out-Null
} else {
    Write-Host "State bucket not found (already deleted): $bucket"
}

Write-Host ""
Write-Host "Remote state backend cleanup complete."
