# Build and deploy Angular + .NET API to IIS folders.
# Requires environment variables (set by GitHub Actions or manually):
#   DEPLOY_BACKEND_PATH, DEPLOY_FRONTEND_PATH,
#   PRODUCTION_API_URL, PRODUCTION_FRONTEND_ORIGIN,
#   IIS_API_APP_POOL, IIS_UI_APP_POOL

$ErrorActionPreference = "Stop"

function Require-Env($Name) {
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Environment variable '$Name' is required."
    }
    return $value
}

function Recycle-AppPool($Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) {
        return
    }

    Write-Host "Recycling app pool: $Name"
    & "$env:windir\system32\inetsrv\appcmd.exe" recycle apppool "$Name" | Out-Null
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$staging = Join-Path $root ".deploy-staging"
$stagingApi = Join-Path $staging "api"
$stagingUi = Join-Path $staging "ui"

$deployBackendPath = Require-Env "DEPLOY_BACKEND_PATH"
$deployFrontendPath = Require-Env "DEPLOY_FRONTEND_PATH"
$productionApiUrl = Require-Env "PRODUCTION_API_URL"
$productionFrontendOrigin = Require-Env "PRODUCTION_FRONTEND_ORIGIN"
$iisApiAppPool = $env:IIS_API_APP_POOL
$iisUiAppPool = $env:IIS_UI_APP_POOL

Write-Host "=== Deploy started ==="
Write-Host "Backend target:  $deployBackendPath"
Write-Host "Frontend target: $deployFrontendPath"

# Inject production API URL into Angular environment
$envProdFile = Join-Path $root "frontend\src\environments\environment.prod.ts"
$envProdContent = Get-Content $envProdFile -Raw
$envProdContent = $envProdContent.Replace("__PRODUCTION_API_URL__", $productionApiUrl)
Set-Content -Path $envProdFile -Value $envProdContent -NoNewline

try {
    if (Test-Path $staging) {
        Remove-Item -Recurse -Force $staging
    }
    New-Item -ItemType Directory -Path $stagingApi -Force | Out-Null
    New-Item -ItemType Directory -Path $stagingUi -Force | Out-Null

    Write-Host "Publishing API..."
    Push-Location (Join-Path $root "backend")
    dotnet publish -c Release -o $stagingApi
    Pop-Location

    Write-Host "Building frontend..."
    Push-Location (Join-Path $root "frontend")
    npm ci
    npm run build
    Pop-Location

    $distDir = Join-Path $root "frontend\dist\frontend\browser"
    if (-not (Test-Path $distDir)) {
        throw "Frontend build output not found at $distDir"
    }

    Copy-Item -Recurse "$distDir\*" $stagingUi

    $appsettingsProduction = @{
        FrontendOrigin = $productionFrontendOrigin
    } | ConvertTo-Json
    Set-Content -Path (Join-Path $stagingApi "appsettings.Production.json") -Value $appsettingsProduction

    New-Item -ItemType Directory -Path $deployBackendPath -Force | Out-Null
    New-Item -ItemType Directory -Path $deployFrontendPath -Force | Out-Null

    Recycle-AppPool $iisApiAppPool

    Write-Host "Deploying API to $deployBackendPath ..."
    & robocopy $stagingApi $deployBackendPath /MIR /XD logs /NFL /NDL /NJH /NJS /nc /ns /np
    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed for API deploy (exit code $LASTEXITCODE)"
    }

    Write-Host "Deploying frontend to $deployFrontendPath ..."
    & robocopy $stagingUi $deployFrontendPath /MIR /NFL /NDL /NJH /NJS /nc /ns /np
    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed for frontend deploy (exit code $LASTEXITCODE)"
    }

    Recycle-AppPool $iisApiAppPool
    Recycle-AppPool $iisUiAppPool

    Write-Host "=== Deploy completed successfully ==="
}
finally {
    # Restore placeholder so the repo file is not left with a baked-in URL
    $restoreContent = @"
export const environment = {
  production: true,
  apiUrl: '__PRODUCTION_API_URL__',
};

"@
    Set-Content -Path $envProdFile -Value $restoreContent -NoNewline

    if (Test-Path $staging) {
        Remove-Item -Recurse -Force $staging
    }
}
