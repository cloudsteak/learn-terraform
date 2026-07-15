#Requires -Version 7.0

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendTf = Join-Path $scriptDir "backend.tf"

if (-not (Test-Path $backendTf)) {
    Write-Error "backend.tf not found at $backendTf"
}

try {
    $null = aws sts get-caller-identity 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "AWS credentials not configured"
    }
} catch {
    Write-Error "AWS credentials not configured. Run 'aws configure' first."
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

function Select-Profile {
    $profiles = @(aws configure list-profiles)

    if ($profiles.Count -eq 0) {
        Write-Host "Using default AWS credential chain (no named profiles found)."
        Write-Host ""
        return
    }

    if ($profiles.Count -eq 1) {
        $env:AWS_PROFILE = $profiles[0]
        Write-Host "Using AWS profile: $($env:AWS_PROFILE)"
        Write-Host ""
        return
    }

    Write-Host "Available AWS profiles:"
    Write-Host ""

    for ($index = 0; $index -lt $profiles.Count; $index++) {
        $number = $index + 1
        Write-Host "  $number) $($profiles[$index])"
    }

    Write-Host ""

    while ($true) {
        $choice = Read-Host "Select profile [1-$($profiles.Count)]"
        if ($choice -match '^\d+$') {
            $selectedIndex = [int]$choice - 1
            if ($selectedIndex -ge 0 -and $selectedIndex -lt $profiles.Count) {
                $env:AWS_PROFILE = $profiles[$selectedIndex]
                Write-Host ""
                Write-Host "Using AWS profile: $($env:AWS_PROFILE)"
                Write-Host ""
                return
            }
        }

        Write-Warning "Invalid selection. Enter a number between 1 and $($profiles.Count)."
    }
}

function Test-BucketExists {
    param([string]$Name)

    aws s3api head-bucket --bucket $Name 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
}

Select-Profile

$region = Read-BackendValue "region"
$stateKey = Read-BackendValue "key"
$bucket = Read-BackendValue "bucket"

Write-Host "This will permanently delete the Terraform remote state backend:"
Write-Host "  Region:           $region"
Write-Host "  State bucket:     $bucket"
Write-Host "  State key:        $stateKey"
Write-Host "  Locking:          S3 lockfile (use_lockfile = true)"
Write-Host ""
Write-Host "Run 'terraform destroy' in this directory before cleanup when possible."
Write-Host "The entire state bucket is removed, including state files and lock files."
Write-Host ""

$confirm = Read-Host "Type 'yes' to permanently delete these resources"
if ($confirm -ne "yes") {
    Write-Host "Cleanup cancelled."
    exit 0
}

Write-Host ""

if (Test-BucketExists $bucket) {
    Write-Host "Deleting state bucket: $bucket"
    aws s3 rb "s3://$bucket" --force | Out-Null
} else {
    Write-Host "State bucket not found (already deleted): $bucket"
}

Write-Host ""
Write-Host "Remote state backend cleanup complete."
