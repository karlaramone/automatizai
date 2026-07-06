# Vercel + GitHub setup for preview/production Supabase isolation
# Prerequisites: supabase CLI logged in, vercel CLI logged in
# From repo root: .\scripts\setup-preview-environment.ps1

$ErrorActionPreference = 'Stop'

$PreviewRef = 'rbinxzqgwuvfzhdphjfy'
$ProdRef = 'hntnfpmsjaaoehlxybin'
$VercelScope = 'karla-trancoso'
$RepoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $RepoRoot

function Get-SupabasePublishableKey {
    param([string]$ProjectRef)
    $json = & .\node_modules\supabase\bin\supabase.exe projects api-keys --project-ref $ProjectRef -o json | Out-String
    $keys = $json | ConvertFrom-Json
    return ($keys | Where-Object { $_.type -eq 'publishable' }).api_key
}

Write-Host 'Fetching Supabase API keys...'
$previewKey = Get-SupabasePublishableKey -ProjectRef $PreviewRef
$prodKey = Get-SupabasePublishableKey -ProjectRef $ProdRef

Write-Host 'Configuring Vercel Preview environment...'
yarn vercel env add VITE_SUPABASE_URL preview --force --no-sensitive --value "https://${PreviewRef}.supabase.co" --yes --scope $VercelScope
yarn vercel env add VITE_SUPABASE_PROJECT_ID preview --force --no-sensitive --value $PreviewRef --yes --scope $VercelScope
yarn vercel env add VITE_SUPABASE_PUBLISHABLE_KEY preview --force --no-sensitive --value $previewKey --yes --scope $VercelScope

Write-Host 'Configuring Vercel Production environment...'
yarn vercel env add VITE_SUPABASE_URL production --force --no-sensitive --value "https://${ProdRef}.supabase.co" --yes --scope $VercelScope
yarn vercel env add VITE_SUPABASE_PROJECT_ID production --force --no-sensitive --value $ProdRef --yes --scope $VercelScope
yarn vercel env add VITE_SUPABASE_PUBLISHABLE_KEY production --force --no-sensitive --value $prodKey --yes --scope $VercelScope

Write-Host 'Vercel env vars configured. Run .\scripts\set-github-secrets.ps1 next.'

Pop-Location
