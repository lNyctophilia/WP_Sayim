$pubPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\pubspec.yaml"
$pub = [System.IO.File]::ReadAllText($pubPath)
if ($pub -match "version: (\d+\.\d+\.\d+)\+(\d+)") {
    $base = $matches[1]
    $num = [int]$matches[2] + 1
    $newVer = "version: ${base}+${num}"
    $pub = $pub -replace "version: \d+\.\d+\.\d+\+\d+", $newVer
    [System.IO.File]::WriteAllText($pubPath, $pub)
    Write-Host "Otomatik olarak pubspec.yaml surumu artirildi: $newVer"
}
