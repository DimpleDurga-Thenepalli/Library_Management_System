$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
try {
 $running = Invoke-WebRequest 'http://127.0.0.1:5173' -UseBasicParsing -TimeoutSec 3
 if ($running.Content -match '<title>Folio') { Write-Host 'Library frontend is already running. Open http://127.0.0.1:5173'; exit 0 }
} catch { }
$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
$nodePath = if ($nodeCommand) { $nodeCommand.Source } else { Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe' }
if (!(Test-Path $nodePath)) { throw 'Install Node.js 22 LTS first.' }
$env:PATH = (Split-Path $nodePath) + ';' + $env:PATH
$npmCli = Join-Path $PSScriptRoot '.tools/package/bin/npm-cli.js'
if (!(Test-Path $npmCli)) {
 New-Item -ItemType Directory -Force '.tools' | Out-Null
 Invoke-WebRequest 'https://registry.npmjs.org/npm/-/npm-10.9.2.tgz' -OutFile '.tools/npm.tgz'
 tar -xzf '.tools/npm.tgz' -C '.tools'
}
if (!(Test-Path 'node_modules/vite')) { & $nodePath $npmCli ci; if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed.' } }
& $nodePath $npmCli run dev
exit $LASTEXITCODE
