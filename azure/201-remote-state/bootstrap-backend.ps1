#Requires -Version 7.0

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendTf = Join-Path $scriptDir "backend.tf"
$location = "Sweden Central"

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

function Update-BackendStorageName {
    param([string]$Name)

    $content = Get-Content -Path $backendTf
    $updated = $content -replace 'storage_account_name\s*=.*', "storage_account_name = `"$Name`""
    Set-Content -Path $backendTf -Value $updated -Encoding utf8NoBOM
}

function New-StorageAccountName {
    $suffix = Get-Random -Minimum 100000000 -Maximum 999999999
    return "terraform$suffix"
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
$stateKey = Read-BackendValue "state_key"
$storageAccount = Read-BackendValue "storage_account_name"

$existingAccount = az storage account show --name $storageAccount --resource-group $resourceGroup 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Using existing storage account from backend.tf: $storageAccount"
} else {
    $storageAccount = New-StorageAccountName
    Update-BackendStorageName $storageAccount
    Write-Host "Generated storage account name: $storageAccount"
    Write-Host "Updated storage_account_name in $backendTf"
}

Write-Host "Terraform backend settings:"
Write-Host "  Resource group:   $resourceGroup"
Write-Host "  Storage account:  $storageAccount"
Write-Host "  Container:        $containerName"
Write-Host "  State key:        $stateKey"
Write-Host ""

$existingGroup = az group show --name $resourceGroup 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating resource group: $resourceGroup"
    az group create --name $resourceGroup --location $location --output none
} else {
    Write-Host "Resource group already exists: $resourceGroup"
}

$existingAccount = az storage account show --name $storageAccount --resource-group $resourceGroup 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating storage account: $storageAccount"
    az storage account create `
        --name $storageAccount `
        --resource-group $resourceGroup `
        --location $location `
        --sku Standard_LRS `
        --min-tls-version TLS1_2 `
        --output none
} else {
    Write-Host "Storage account already exists: $storageAccount"
}

$accountKey = az storage account keys list `
    --resource-group $resourceGroup `
    --account-name $storageAccount `
    --query "[0].value" `
    --output tsv

$existingContainer = az storage container show `
    --name $containerName `
    --account-name $storageAccount `
    --account-key $accountKey 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating blob container: $containerName"
    az storage container create `
        --name $containerName `
        --account-name $storageAccount `
        --account-key $accountKey `
        --output none
} else {
    Write-Host "Blob container already exists: $containerName"
}

Write-Host ""
Write-Host "Remote state backend is ready for Terraform."
Write-Host "Next: terraform init && terraform apply"
