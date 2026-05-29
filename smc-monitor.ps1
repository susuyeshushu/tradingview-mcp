param(
    [string]$symbol = "OANDA:XAUUSD",
    [double]$shortEntry = 4395,
    [double]$shortStop = 4410,
    [double]$sweepLow = 4375
)

$prevStatus = ""
Write-Host "Starting SMC monitor for $symbol ..." -ForegroundColor Cyan

while ($true) {
    $json = node -e "
        import('./src/core/data.js').then(async (mod) => {
            var q = await mod.getQuote({symbol: '$symbol'});
            process.stdout.write(JSON.stringify({last: q.last, high: q.high, low: q.low}));
            process.exit(0);
        }).catch(e => {
            process.stdout.write(JSON.stringify({error: e.message}));
            process.exit(1);
        });
    " 2>&1

    try {
        $data = $json | ConvertFrom-Json
        if (-not $data.error -and $data.last) {
            $price = [double]$data.last
            $high  = [double]$data.high
            $low   = [double]$data.low
            $now = Get-Date -Format "HH:mm:ss"
            $status = ""

            if ($price -ge $shortEntry) {
                $status = "SELL SIGNAL! Price $price at supply zone $shortEntry`nStop $shortStop | Targets $sweepLow -> 4366"
            } elseif ($price -le $sweepLow) {
                $status = "LIQUIDITY SWEEP! Price $price below $sweepLow`nWatch for reclaim -> possible bull trap"
            } elseif ($price -ge 4390 -and $price -lt $shortEntry) {
                $status = "Approaching sell zone $price (target $shortEntry)"
            } else {
                $status = "Holding $price (range $sweepLow-$shortEntry)"
            }

            if ($status -ne $prevStatus) {
                Clear-Host
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host "  XAUUSD SMC Monitor ($now)" -ForegroundColor Yellow
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  Price: $price" -ForegroundColor White
                Write-Host "  High/Low: $high / $low" -ForegroundColor DarkGray
                Write-Host ""
                Write-Host "  Levels:" -ForegroundColor Cyan
                Write-Host "    Short Entry: $shortEntry" -ForegroundColor Red
                Write-Host "    Sweep Zone:  $sweepLow" -ForegroundColor Magenta
                Write-Host ""
                Write-Host "  $status" -ForegroundColor Green
                Write-Host ""
                Write-Host "  Press Ctrl+C to stop" -ForegroundColor DarkGray
                $prevStatus = $status
            }
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    Start-Sleep -Seconds 30
}
