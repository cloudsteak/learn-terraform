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

function Update-BackendBucketName {
    param([string]$Name)

    $content = Get-Content -Path $backendTf
    $updated = $content -replace 'bucket\s*=.*', "bucket         = `"$Name`""
    Set-Content -Path $backendTf -Value $updated -Encoding utf8NoBOM
}

function New-StateBucketName {
    $accountId = aws sts get-caller-identity --query Account --output text
    $suffix = Get-Random -Minimum 100000000 -Maximum 999999999
    return "learn-terraform-state-$accountId-$suffix"
}

function Test-BucketExists {
    param([string]$Name)

    aws s3api head-bucket --bucket $Name 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
}

function New-StateBucket {
    param(
        [string]$Name,
        [string]$Region
    )

    if ($Region -eq "us-east-1") {
        aws s3api create-bucket `
            --bucket $Name `
            --region $Region `
            --output none | Out-Null
    } else {
        aws s3api create-bucket `
            --bucket $Name `
            --region $Region `
            --create-bucket-configuration "LocationConstraint=$Region" `
            --output none | Out-Null
    }
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

Select-Profile

$region = Read-BackendValue "region"
$stateKey = Read-BackendValue "key"
$bucket = Read-BackendValue "bucket"

if (Test-BucketExists $bucket) {
    Write-Host "Using existing state bucket from backend.tf: $bucket"
} else {
    $bucket = New-StateBucketName
    Update-BackendBucketName $bucket
    Write-Host "Generated state bucket name: $bucket"
    Write-Host "Updated bucket in $backendTf"
}

Write-Host "Terraform backend settings:"
Write-Host "  Region:           $region"
Write-Host "  State bucket:     $bucket"
Write-Host "  State key:        $stateKey"
Write-Host "  Locking:          S3 lockfile (use_lockfile = true)"
Write-Host ""

if (-not (Test-BucketExists $bucket)) {
    Write-Host "Creating state bucket: $bucket"
    New-StateBucket -Name $bucket -Region $region
} else {
    Write-Host "State bucket already exists: $bucket"
}

aws s3api put-bucket-versioning `
    --bucket $bucket `
    --versioning-configuration Status=Enabled `
    --output none | Out-Null

aws s3api put-public-access-block `
    --bucket $bucket `
    --public-access-block-configuration `
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true `
    --output none | Out-Null

aws s3api put-bucket-encryption `
    --bucket $bucket `
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' `
    --output none | Out-Null

Write-Host ""
Write-Host "Remote state backend is ready for Terraform."
Write-Host "Next: terraform init && terraform apply"
