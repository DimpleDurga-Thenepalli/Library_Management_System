. (Join-Path $PSScriptRoot 'library-paths.ps1')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'setup-local.ps1')
try {
 $running = Invoke-RestMethod 'http://127.0.0.1:8080/api/auth/csrf' -TimeoutSec 3
 if ($running.token) { Write-Host 'Library backend is already running on http://127.0.0.1:8080. Reusing it.'; exit 0 }
} catch { }
$config = Import-Clixml -LiteralPath (Join-Path $libraryStateDir 'credentials.xml')
$env:DB_URL = 'jdbc:postgresql://127.0.0.1:5433/library_management'
$env:DB_USERNAME = 'library_app'
$env:DB_PASSWORD = [System.Net.NetworkCredential]::new('', $config.DatabasePassword).Password
$env:ADMIN_USERNAME = 'admin'
$env:ADMIN_PASSWORD = [System.Net.NetworkCredential]::new('', $config.AdminPassword).Password
$runtimeTmp = Join-Path $libraryStateDir 'tmp'
New-Item -ItemType Directory -Force $runtimeTmp | Out-Null
$env:TEMP = $runtimeTmp
$env:TMP = $runtimeTmp
$env:JAVA_TOOL_OPTIONS = "-Djava.io.tmpdir=$runtimeTmp"
try { & (Join-Path $PSScriptRoot 'mvnw.cmd') spring-boot:run; $backendExit = $LASTEXITCODE } finally { Remove-Item Env:DB_PASSWORD,Env:ADMIN_PASSWORD -ErrorAction SilentlyContinue }
exit $backendExit
