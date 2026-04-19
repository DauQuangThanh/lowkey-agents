# Dot-source ta-strategy _common.ps1
$CommonPath = Join-Path (Split-Path (Split-Path $PSScriptRoot)) "ta-strategy/scripts/_common.ps1"
if (Test-Path $CommonPath) {
  . $CommonPath
}
