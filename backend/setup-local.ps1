. (Join-Path $PSScriptRoot 'library-paths.ps1')
# Creates an isolated PostgreSQL 18 server. Existing PostgreSQL instances are untouched.
$ErrorActionPreference = 'Stop'
$pgBin = 'C:\Program Files\PostgreSQL\18\bin'
if (!(Test-Path "$pgBin\initdb.exe")) { throw 'Install PostgreSQL 18 first, then rerun this script.' }
$stateDir =  $libraryStateDir
$dataDir = Join-Path $stateDir 'PostgreSQL18'
$configFile = Join-Path $stateDir 'credentials.xml'
New-Item -ItemType Directory -Force $stateDir | Out-Null
if (!(Test-Path $configFile)) {
 $dbPassword = 'Db-' + [guid]::NewGuid().ToString('N')
 $adminPassword = 'Folio-' + [guid]::NewGuid().ToString('N')
 $config = [pscustomobject]@{ DatabasePassword = (ConvertTo-SecureString $dbPassword -AsPlainText -Force); AdminPassword = (ConvertTo-SecureString $adminPassword -AsPlainText -Force) }
 $config | Export-Clixml -LiteralPath $configFile
}
$config = Import-Clixml -LiteralPath $configFile
$dbPassword = [System.Net.NetworkCredential]::new('', $config.DatabasePassword).Password
if (!(Test-Path (Join-Path $dataDir 'PG_VERSION'))) {
 & "$pgBin\pg_isready.exe" -h 127.0.0.1 -p 5433 *> $null
 if ($LASTEXITCODE -eq 0) { throw 'A server is already running on port 5433, but this data directory is not initialized. Refusing duplicate initialization. No data was deleted.' }
 if ((Test-Path $dataDir) -and @(Get-ChildItem -LiteralPath $dataDir -Force).Count -gt 0) { throw 'The PostgreSQL directory contains partial or existing data. Refusing initialization; retain the folder for recovery.' }
 $passwordFile = Join-Path $stateDir 'init-password.tmp'
 try {
  [System.IO.File]::WriteAllText($passwordFile, $dbPassword)
  Write-Host 'Initializing PostgreSQL once. Subsequent runs will reuse this database.'
  & "$pgBin\initdb.exe" -D $dataDir -U library_app --pwfile=$passwordFile --auth=scram-sha-256 --encoding=UTF8 --locale=C --no-clean -c max_connections=100 -c shared_buffers=128MB
  if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL initialization failed.' }
 } finally { if (Test-Path $passwordFile) { Remove-Item -LiteralPath $passwordFile } }
}
& "$pgBin\pg_ctl.exe" status -D $dataDir *> $null
if ($LASTEXITCODE -ne 0) {
 & "$pgBin\pg_ctl.exe" start -D $dataDir -l (Join-Path $stateDir 'postgres.log') -o '-p 5433 -h 127.0.0.1' -w
 if ($LASTEXITCODE -ne 0) { throw "Unable to start PostgreSQL on port 5433. See $libraryStateDir/postgres.log." }
}
$env:PGPASSWORD = $dbPassword
try {
 $exists = & "$pgBin\psql.exe" -h 127.0.0.1 -p 5433 -U library_app -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='library_management'"
 if ($LASTEXITCODE -ne 0) { throw 'Database connection failed.' }
 if ($exists -ne '1') { & "$pgBin\createdb.exe" -h 127.0.0.1 -p 5433 -U library_app library_management; if ($LASTEXITCODE -ne 0) { throw 'Database creation failed.' } }
} finally { Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue }
Write-Host 'PostgreSQL 18 is ready on 127.0.0.1:5433. Database: library_management.'
Write-Host "Data and encrypted credentials: $libraryStateDir"
