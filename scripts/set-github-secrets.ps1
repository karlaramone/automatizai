# GitHub Actions secrets required for preview/production isolation
# Prerequisites: gh auth login
# From repo root: .\scripts\set-github-secrets.ps1

$ErrorActionPreference = 'Stop'

$PreviewRef = 'rbinxzqgwuvfzhdphjfy'
$ProdRef = 'hntnfpmsjaaoehlxybin'
$RepoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $RepoRoot

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required. Install: winget install GitHub.cli'
}

gh auth status | Out-Null

$previewDbPassword = (Get-Content -Path 'docs\db-password.txt' -Raw).Trim()
$encodedPreviewPassword = [uri]::EscapeDataString($previewDbPassword)
$databaseUrlPreview = "postgresql://postgres.${PreviewRef}:${encodedPreviewPassword}@aws-0-us-east-1.pooler.supabase.com:5432/postgres"

Write-Host 'Create a Supabase access token at: https://supabase.com/dashboard/account/tokens'
$supabaseToken = Read-Host 'Paste SUPABASE_ACCESS_TOKEN'

Write-Host 'Enter the production database password (Project Settings -> Database)'
$prodDbPassword = Read-Host 'Paste SUPABASE_DB_PASSWORD_PROD' -AsSecureString
$prodDbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($prodDbPassword)
)

gh secret set SUPABASE_ACCESS_TOKEN --body $supabaseToken
gh secret set SUPABASE_PREVIEW_PROJECT_REF --body $PreviewRef
gh secret set SUPABASE_PROD_PROJECT_REF --body $ProdRef
gh secret set DATABASE_URL_PREVIEW --body $databaseUrlPreview
gh secret set SUPABASE_DB_PASSWORD_PREVIEW --body $previewDbPassword
gh secret set SUPABASE_DB_PASSWORD_PROD --body $prodDbPasswordPlain

Write-Host 'GitHub secrets configured.'

Pop-Location
