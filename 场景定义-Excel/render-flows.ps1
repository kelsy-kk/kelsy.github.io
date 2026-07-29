$ErrorActionPreference = "Stop"

$flowsDir = Join-Path $PSScriptRoot "flows"
if (-not (Test-Path $flowsDir)) { New-Item -ItemType Directory -Path $flowsDir | Out-Null }

function Save-KrokiPng([string]$Code, [string]$OutPath) {
    Write-Host "Rendering -> $OutPath"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Code)
    Invoke-WebRequest -Uri "https://kroki.io/mermaid/png" -Method POST -Body $bytes -ContentType "text/plain; charset=utf-8" -OutFile $OutPath -UseBasicParsing -TimeoutSec 120
    $kb = [math]::Round((Get-Item $OutPath).Length / 1KB, 1)
    Write-Host "OK  $OutPath  ($kb KB)"
}

$jobs = @(
    @{ In = "flow-00-overview.mmd"; Out = "00-overview.png" },
    @{ In = "flow-A-preset.mmd"; Out = "A-preset.png" },
    @{ In = "flow-B-create.mmd"; Out = "B-create.png" },
    @{ In = "flow-C-manage.mmd"; Out = "C-manage.png" },
    @{ In = "flow-D-newflow.mmd"; Out = "D-newflow.png" },
    @{ In = "flow-E-states.mmd"; Out = "E-states.png" }
)

foreach ($job in $jobs) {
    $src = Join-Path $flowsDir $job.In
    $out = Join-Path $flowsDir $job.Out
    $code = (Get-Content -Path $src -Raw -Encoding UTF8).Trim()
    Save-KrokiPng -Code $code -OutPath $out
}

# Copy to Chinese filenames for user convenience
$rename = @{
    "00-overview.png" = "00-总览-四条用户路径.png"
    "A-preset.png" = "A-浏览与选用预置场景.png"
    "B-create.png" = "B-创建自定义场景.png"
    "C-manage.png" = "C-管理已有自定义场景.png"
    "D-newflow.png" = "D-从新建流程选用场景.png"
    "E-states.png" = "E-状态机总图.png"
}
foreach ($kv in $rename.GetEnumerator()) {
    $from = Join-Path $flowsDir $kv.Key
    $to = Join-Path $flowsDir $kv.Value
    if (Test-Path $from) { Copy-Item -Path $from -Destination $to -Force }
}

Write-Host "All done."
