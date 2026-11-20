# start-tunnel.ps1 - Khoi dong Edumy Online Tunnel
$ErrorActionPreference = "Continue"

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "       KHOI DONG HE THONG EDUMY ONLINE QUA CLOUDFLARE     " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Kiem tra Docker Engine
Write-Host "`n[1/3] Kiem tra Docker Desktop..." -ForegroundColor Green
$dockerRunning = $false
try {
    $null = docker info 2>$null
    if ($LASTEXITCODE -eq 0) { $dockerRunning = $true }
} catch {
    $dockerRunning = $false
}

if (-not $dockerRunning) {
    Write-Host "Docker Desktop chua chay. Dang tu dong khoi dong Docker Desktop..." -ForegroundColor Yellow
    if (Test-Path "C:\Program Files\Docker\Docker\Docker Desktop.exe") {
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    }
    $timeout = 60
    while ($timeout -gt 0) {
        Start-Sleep -Seconds 3
        try {
            $null = docker info 2>$null
            if ($LASTEXITCODE -eq 0) {
                $dockerRunning = $true
                break
            }
        } catch {}
        $timeout -= 3
        Write-Host -NoNewline "."
    }
    Write-Host ""
}

# Kiem tra cac container
$running = docker ps --filter "name=edumy_frontend" --format "{{.Names}}" 2>$null
if (-not $running) {
    Write-Host "Containers chua chay. Dang khoi dong bang Docker Compose..." -ForegroundColor Yellow
    Push-Location "C:\Users\bacle\Downloads\Edumy-Project\Edumy-main\Edumy"
    docker compose up -d
    Pop-Location
} else {
    Write-Host "Docker containers dang hoat dong tot!" -ForegroundColor Green
}

# 2. Chay cloudflared
Write-Host "`n[2/3] Dang tao duong link HTTPS cong khai qua Cloudflare..." -ForegroundColor Green
$cloudflaredPath = "C:\Program Files (x86)\cloudflared\cloudflared.exe"

$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $cloudflaredPath
$processInfo.Arguments = "tunnel --protocol http2 --url http://localhost:3000"
$processInfo.RedirectStandardError = $true
$processInfo.UseShellExecute = $false
$processInfo.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processInfo
$process.Start() | Out-Null

$tunnelUrl = ""
while (-not $process.HasExited) {
    $line = $process.StandardError.ReadLine()
    if ($line -match "https://[a-zA-Z0-9-]+\.trycloudflare\.com") {
        $tunnelUrl = $matches[0]
        break
    }
}

if ($tunnelUrl) {
    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "            DUONG LINK ONLINE EDUMY CUA BAN               " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "`n>> Trang Web Edumy: $tunnelUrl" -ForegroundColor Cyan
    Write-Host ">> Backend API:     $tunnelUrl/api" -ForegroundColor Cyan
    Write-Host "`nLuu y:" -ForegroundColor White
    Write-Host "1. Ban co the gui link tren cho thay co hoac ban be test tu xa!" -ForegroundColor Gray
    Write-Host "2. Neu ban test tren chinh may tinh nay, co the dung truc tiep: http://localhost:3000" -ForegroundColor Gray
    Write-Host "3. Cua so nay can duoc GIU MO trong suot luc muon chay online." -ForegroundColor Yellow
    Write-Host "`nNhan Ctrl + C de dung server online.`n" -ForegroundColor DarkGray
    
    # Cap nhat vao .env cua Mobile App
    $envPath = "C:\Users\bacle\Downloads\Edumy-Project\Edumy-App\.env"
    if (Test-Path $envPath) {
        $envContent = Get-Content $envPath -Raw
        $envContent = $envContent -replace 'EXPO_PUBLIC_API_BASE_URL=.*', "EXPO_PUBLIC_API_BASE_URL=$tunnelUrl/api/v1"
        $envContent = $envContent -replace 'EXPO_PUBLIC_WEB_BASE_URL=.*', "EXPO_PUBLIC_WEB_BASE_URL=$tunnelUrl"
        Set-Content -Path $envPath -Value $envContent
        Write-Host "[OK] Da cap nhat tu dong URL moi vao file .env cua Edumy-App" -ForegroundColor DarkGray
    }

    $process.WaitForExit()
} else {
    Write-Host "Khong the tao tunnel, vui long kiem tra ket noi mang!" -ForegroundColor Red
}
