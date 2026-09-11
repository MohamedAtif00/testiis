# Publish backend API for IIS (independent of frontend)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$publishDir = Join-Path $root "publish-api"

Write-Host "Publishing API to $publishDir ..."
Push-Location (Join-Path $root "backend")
dotnet publish -c Release -o $publishDir
Pop-Location

Write-Host ""
Write-Host "Done. Copy contents of publish-api\ to your IIS backend folder (e.g. C:\inetpub\products-api\)"
Write-Host "Backend IIS site binding example: http://localhost:5031"
