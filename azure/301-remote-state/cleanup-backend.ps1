#Requires -Version 7.0

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendTf = Join-Path $scriptDir "backend.tf"

if (-not (Test-Path $backendTf)) {
    Write-Error "backend.tf not found at $backendTf"
}

try {
    $null = az account show 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Not logged in"
    }
} catch {
    Write-Error "Not logged in to Azure. Run 'az login' first."
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

function Select-Subscription {
    $subscriptions = az account list --query '[].{name:name, id:id}' -o json | ConvertFrom-Json

    if (-not $subscriptions -or $subscriptions.Count -eq 0) {
        Write-Error "No Azure subscriptions found."
    }

    Write-Host "Available Azure subscriptions:"
    Write-Host ""

    for ($index = 0; $index -lt $subscriptions.Count; $index++) {
        $number = $index + 1
        Write-Host "  $number) $($subscriptions[$index].name)"
        Write-Host "     $($subscriptions[$index].id)"
        Write-Host ""
    }

    while ($true) {
        $choice = Read-Host "Select subscription [1-$($subscriptions.Count)]"
        if ($choice -match '^\d+$') {
            $selectedIndex = [int]$choice - 1
            if ($selectedIndex -ge 0 -and $selectedIndex -lt $subscriptions.Count) {
                az account set --subscription $subscriptions[$selectedIndex].id | Out-Null
                Write-Host ""
                Write-Host "Using subscription: $(az account show --query name -o tsv)"
                Write-Host ""
                return
            }
        }

        Write-Warning "Invalid selection. Enter a number between 1 and $($subscriptions.Count)."
    }
}

Select-Subscription

$resourceGroup = Read-BackendValue "resource_group_name"
$containerName = Read-BackendValue "container_name"
$stateKey = Read-BackendValue "key"
$storageAccount = Read-BackendValue "storage_account_name"

Write-Host "This will permanently delete the Terraform remote state backend:"
Write-Host "  Resource group:   $resourceGroup"
Write-Host "  Storage account:  $storageAccount"
Write-Host "  Container:        $containerName"
Write-Host "  State key:        $stateKey"
Write-Host ""
Write-Host "Run 'terraform destroy' in this directory before cleanup when possible."
Write-Host "The entire resource group is removed, including the storage account and all state blobs."
Write-Host ""

$confirm = Read-Host "Type 'yes' to permanently delete these resources"
if ($confirm -ne "yes") {
    Write-Host "Cleanup cancelled."
    exit 0
}

Write-Host ""

$existingGroup = az group show --name $resourceGroup 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Deleting resource group: $resourceGroup"
    az group delete --name $resourceGroup --yes --no-wait | Out-Null
    Write-Host "Resource group deletion started."
} else {
    Write-Host "Resource group not found (already deleted): $resourceGroup"
}

Write-Host ""
Write-Host "Remote state backend cleanup complete."
