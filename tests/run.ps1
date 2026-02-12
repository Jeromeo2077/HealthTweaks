param(
  [string]$LuaExe = "lua"
)

$ErrorActionPreference = 'Stop'

Write-Host "Running Lua unit tests..." -ForegroundColor Cyan

# Try lua, then luajit, then embedded if user provides.
$exeCandidates = @($LuaExe, "luajit") | Where-Object { $_ -and $_.Trim().Length -gt 0 }

$exe = $null
foreach ($c in $exeCandidates) {
  $cmd = Get-Command $c -ErrorAction SilentlyContinue
  if ($cmd) { $exe = $cmd.Source; break }
}

if (-not $exe) {
  throw "No Lua interpreter found. Install Lua (lua.exe) or LuaJIT (luajit.exe), or pass -LuaExe <path>."
}

& $exe "tests/run.lua"
exit $LASTEXITCODE
