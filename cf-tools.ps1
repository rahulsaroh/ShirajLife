<#
.SYNOPSIS
    Cloudflare Automation & Management Utility for ShirajLife
.DESCRIPTION
    Verify API tokens, inspect Cloudflare accounts, list zones/domains,
    manage Cloudflare Pages projects, and deploy directly to Cloudflare Pages.
#>

param (
    [Parameter(Position = 0)]
    [ValidateSet("verify", "accounts", "zones", "pages", "deploy", "help")]
    [string]$Action = "verify",

    [Parameter()]
    [string]$Token,

    [Parameter()]
    [string]$AccountId,

    [Parameter()]
    [string]$ProjectName = "shirajlife"
)

# Load .env file if present
$envFilePath = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFilePath) {
    Get-Content $envFilePath | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $parts = $line.Split("=", 2)
            $key = $parts[0].Trim()
            $val = $parts[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($key)) {
                [System.Environment]::SetEnvironmentVariable($key, $val, [System.EnvironmentVariableTarget]::Process)
            }
        }
    }
}

if (-not $Token) {
    $Token = $env:CLOUDFLARE_API_TOKEN
}
if (-not $AccountId) {
    $AccountId = $env:CLOUDFLARE_ACCOUNT_ID
}

if ($Action -eq "help") {
    Write-Host "`nUsage: .\cf-tools.ps1 [Action] [-Token '<token>'] [-AccountId '<id>']"
    Write-Host "Actions:"
    Write-Host "  verify   - Test API token connection and status"
    Write-Host "  accounts - Discover your Cloudflare Account Name and Account ID"
    Write-Host "  zones    - List all DNS zones / domains configured on Cloudflare"
    Write-Host "  pages    - List all Cloudflare Pages projects"
    Write-Host "  deploy   - Deploy website files to Cloudflare Pages via Wrangler"
    exit 0
}

if (-not $Token -or $Token -eq "your_cloudflare_api_token_here") {
    Write-Host " [!] No Cloudflare API Token provided." -ForegroundColor Yellow
    Write-Host "     Please set CLOUDFLARE_API_TOKEN in .env or pass -Token '<your_token>'." -ForegroundColor Yellow
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

function Verify-Token {
    Write-Host "`n[*] Verifying Cloudflare API Token..." -ForegroundColor Cyan
    try {
        $verifyUrl = "https://api.cloudflare.com/client/v4/user/tokens/verify"
        if ($Token.StartsWith("cfat_") -and $AccountId) {
            $verifyUrl = "https://api.cloudflare.com/client/v4/accounts/$AccountId/tokens/verify"
        }
        $response = Invoke-RestMethod -Uri $verifyUrl -Headers $headers -Method Get
        if ($response.success) {
            Write-Host " Token is valid and active!" -ForegroundColor Green
            Write-Host "   Status:    $($response.result.status)" -ForegroundColor Gray
            Write-Host "   Token ID:  $($response.result.id)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host " [X] Token verification returned failure." -ForegroundColor Red
            $response.errors | ForEach-Object { Write-Host "   Error: $($_.message)" -ForegroundColor Red }
            return $false
        }
    } catch {
        Write-Host " [X] Error validating token: $_" -ForegroundColor Red
        return $false
    }
}

function Get-Accounts {
    Write-Host "`n[*] Fetching Cloudflare Accounts..." -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/accounts" -Headers $headers -Method Get
        if ($response.success) {
            Write-Host " Found $($response.result.Count) account(s):" -ForegroundColor Green
            foreach ($acc in $response.result) {
                Write-Host "   -> Name: $($acc.name) | ID: $($acc.id)" -ForegroundColor Yellow
            }
            if (-not $AccountId -and $response.result.Count -gt 0) {
                $script:AccountId = $response.result[0].id
                Write-Host "   (Auto-selected Account ID: $script:AccountId)" -ForegroundColor Gray
            }
        } else {
            Write-Host " [X] Failed to list accounts." -ForegroundColor Red
            $response.errors | ForEach-Object { Write-Host "   Error: $($_.message)" -ForegroundColor Red }
        }
    } catch {
        Write-Host " [X] Error fetching accounts: $_" -ForegroundColor Red
    }
}

function Get-Zones {
    Write-Host "`n[*] Fetching DNS Zones / Domains..." -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/zones" -Headers $headers -Method Get
        if ($response.success) {
            Write-Host " Found $($response.result.Count) zone(s):" -ForegroundColor Green
            foreach ($zone in $response.result) {
                Write-Host "   -> Domain: $($zone.name) (Status: $($zone.status), Plan: $($zone.plan.name))" -ForegroundColor Yellow
                Write-Host "      Name Servers: $($zone.name_servers -join ', ')" -ForegroundColor Gray
            }
        } else {
            Write-Host " [!] Zone query message:" -ForegroundColor Yellow
            $response.errors | ForEach-Object { Write-Host "   Info/Error: $($_.message)" -ForegroundColor Yellow }
        }
    } catch {
        Write-Host " [!] Unable to query zones (token may lack Zone permissions): $_" -ForegroundColor Yellow
    }
}

function Get-PagesProjects {
    if (-not $AccountId) {
        Get-Accounts
    }
    if (-not $AccountId) {
        Write-Host " [X] Account ID required to list Pages projects. Set CLOUDFLARE_ACCOUNT_ID." -ForegroundColor Red
        return
    }
    Write-Host "`n[*] Fetching Cloudflare Pages projects for Account: $AccountId..." -ForegroundColor Cyan
    try {
        $url = "https://api.cloudflare.com/client/v4/accounts/$AccountId/pages/projects"
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        if ($response.success) {
            Write-Host " Found $($response.result.Count) Pages project(s):" -ForegroundColor Green
            foreach ($proj in $response.result) {
                Write-Host "   -> Project: $($proj.name)" -ForegroundColor Yellow
                Write-Host "      Production URL: $($proj.subdomain)" -ForegroundColor Gray
                Write-Host "      Domains: $(($proj.domains) -join ', ')" -ForegroundColor Gray
            }
        } else {
            Write-Host " [X] Failed to list Pages projects." -ForegroundColor Red
            $response.errors | ForEach-Object { Write-Host "   Error: $($_.message)" -ForegroundColor Red }
        }
    } catch {
        Write-Host " [X] Error fetching Pages projects: $_" -ForegroundColor Red
    }
}

function Deploy-Pages {
    Write-Host "`n[*] Staging web assets into dist/..." -ForegroundColor Cyan
    $dist = Join-Path $PSScriptRoot "dist"
    if (-not (Test-Path $dist)) {
        New-Item -ItemType Directory -Path $dist | Out-Null
    }

    Get-ChildItem -Path $PSScriptRoot -File | Where-Object {
        $_.Extension -in @(".html", ".css", ".js", ".png", ".jpg", ".jpeg", ".svg", ".ico", ".webmanifest", ".pdf") -and
        $_.Name -ne "server.py" -and
        $_.Name -ne "replace_currency.py"
    } | ForEach-Object {
        Copy-Item $_.FullName -Destination $dist -Force
    }

    $iconsDir = Join-Path $PSScriptRoot "icons"
    if (Test-Path $iconsDir) {
        Copy-Item -Recurse $iconsDir -Destination (Join-Path $dist "icons") -Force
    }
    
    $workerFile = Join-Path $PSScriptRoot "_worker.js"
    if (Test-Path $workerFile) {
        Copy-Item $workerFile -Destination (Join-Path $dist "_worker.js") -Force
    }

    Write-Host " Staged $((Get-ChildItem -Path $dist).Count) assets into dist/." -ForegroundColor Green
    Write-Host "`n[*] Deploying dist/ to Cloudflare Pages (Project: $ProjectName)..." -ForegroundColor Cyan
    $env:CLOUDFLARE_API_TOKEN = $Token
    if ($AccountId) {
        $env:CLOUDFLARE_ACCOUNT_ID = $AccountId
    }
    
    npx -y wrangler pages deploy $dist --project-name $ProjectName --branch main --commit-dirty=true
}

# Main Dispatcher
switch ($Action) {
    "verify"   { Verify-Token }
    "accounts" { Get-Accounts }
    "zones"    { Get-Zones }
    "pages"    { Get-PagesProjects }
    "deploy"   { Deploy-Pages }
    "help"     {
        Write-Host "`nUsage: .\cf-tools.ps1 [Action] [-Token '<token>'] [-AccountId '<id>']"
        Write-Host "Actions: verify, accounts, zones, pages, deploy"
    }
}
