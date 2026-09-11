# Publish frontend for IIS (independent of backend)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $root "frontend"
$distDir = Join-Path $frontendDir "dist\frontend\browser"
$publishDir = Join-Path $root "publish-ui"

Write-Host "Building Angular app ..."
Push-Location $frontendDir
npm run build
Pop-Location

if (-not (Test-Path $distDir)) {
    throw "Build output not found at $distDir"
}

Write-Host "Copying build output to $publishDir ..."
if (Test-Path $publishDir) {
    Remove-Item -Recurse -Force $publishDir
}
New-Item -ItemType Directory -Path $publishDir | Out-Null
Copy-Item -Recurse "$distDir\*" $publishDir

Write-Host ""
Write-Host "Done. Copy contents of publish-ui\ to your IIS frontend folder (e.g. C:\inetpub\products-ui\)"
Write-Host "Frontend IIS site binding example: http://localhost:8080"
