# start-tunnel.ps1 - Khoi dong Edumy Online Tunnel
$ErrorActionPreference = "Continue"

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "       KHOI DONG HE THONG EDUMY ONLINE QUA CLOUDFLARE     " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Kiem tra Docker
Write-Host "`n[1/3] Kiem tra cac container Docker..." -ForegroundColor Green
$running = docker ps --filter "name=edumy_frontend" --format "{{.Names}}"
if (-not $running) {
    Write-Host "Containers chua chay. Dang khoi dong..." -ForegroundColor Yellow
    Push-Location "C:\Users\bacle\Downloads\Edumy-Project\Edumy-main\Edumy"
    docker compose up -d
    Pop-Location
} else {
    Write-Host "Docker containers dang hoat dong tot!" -ForegroundColor Green
}

# 2. Dam bao Nginx proxy duoc cap nhat
docker cp "C:\Users\bacle\Downloads\Edumy-Project\Edumy-main\Edumy\Frontend\nginx.conf" edumy_frontend:/etc/nginx/conf.d/default.conf 2>$null
docker exec edumy_frontend nginx -s reload 2>$null

# 3. Chay cloudflared
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
    Write-Host "`nLuu y: Ban co the gui link tren cho thay co hoac ban be vao test thoai mai!" -ForegroundColor White
    Write-Host "Cua so nay can duoc GIU BAT trong suot thoi gian muon chay server online.`n" -ForegroundColor Yellow
    Write-Host "Nhan Ctrl + C de dung server online.`n" -ForegroundColor Gray
    
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
