param(
    [switch]$NoWait,
    [int]$Port = 9222
)

$installDir = "D:\TradingView"
$exePath = "$installDir\TradingView.exe"
$cdpPort = $Port

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TradingView Desktop + CDP 调试启动器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if already running with CDP
$existing = Get-NetTCPConnection -LocalPort $cdpPort -ErrorAction SilentlyContinue
if ($existing) {
    $ownerProc = Get-Process -Id $existing.OwningProcess -ErrorAction SilentlyContinue
    if ($ownerProc -and $ownerProc.ProcessName -like "*Trading*") {
        Write-Host "✓ TradingView CDP (端口 $cdpPort) 已在运行" -ForegroundColor Green
        Write-Host "  调试页面: http://localhost:$cdpPort" -ForegroundColor Gray
        exit 0
    }
}

# Check if TradingView exists
if (-not (Test-Path $exePath)) {
    Write-Host "✗ 未找到: $exePath" -ForegroundColor Red
    Write-Host "  请先安装 TradingView Desktop" -ForegroundColor Yellow
    exit 1
}

Write-Host "启动 TradingView Desktop (CDP 端口: $cdpPort)..." -ForegroundColor Yellow
Write-Host ""

# Launch TradingView with CDP enabled
$proc = Start-Process -FilePath $exePath -ArgumentList "--remote-debugging-port=$cdpPort" -PassThru
Write-Host "进程已启动, PID: $($proc.Id)" -ForegroundColor Cyan

if (-not $NoWait) {
    $timeout = 30
    $elapsed = 0
    Write-Host "等待 CDP 连接就绪..." -ForegroundColor Yellow
    while ($elapsed -lt $timeout) {
        Start-Sleep -Seconds 2
        $elapsed += 2
        $conn = Get-NetTCPConnection -LocalPort $cdpPort -ErrorAction SilentlyContinue
        if ($conn) {
            Write-Host ""
            Write-Host "✓ CDP 连接就绪! (${elapsed}s)" -ForegroundColor Green
            Write-Host "  调试页面: http://localhost:$cdpPort" -ForegroundColor Cyan
            Write-Host "  PID: $($conn.OwningProcess)" -ForegroundColor Gray
            Write-Host ""
            Write-Host "MCP 服务器已配置，重启 opencode 即可使用 tradingview 工具" -ForegroundColor Green
            exit 0
        }
    }
    Write-Host ""
    Write-Host "⚠ CDP 连接超时 (${timeout}s)" -ForegroundColor Red
    Write-Host "  请检查 TradingView 是否正常启动" -ForegroundColor Yellow
}
