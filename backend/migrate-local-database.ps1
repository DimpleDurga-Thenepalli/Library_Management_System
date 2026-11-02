$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'library-paths.ps1')
$oldState = Join-Path $env:LOCALAPPDATA 'FolioLibrary'
$pgBin = 'C:\Program Files\PostgreSQL\18\bin'
$destination = Join-Path $libraryStateDir 'PostgreSQL18'
if (Test-Path $destination) { throw 'Migration destination already exists. It will not be overwritten.' }
$config = Import-Clixml -LiteralPath (Join-Path $oldState 'credentials.xml')
$env:PGPASSWORD = [System.Net.NetworkCredential]::new('', $config.DatabasePassword).Password
try {
 $source = & "$pgBin\psql.exe" -h 127.0.0.1 -p 5433 -U library_app -d postgres -w -Atc 'SHOW data_directory'
 if ($LASTEXITCODE -ne 0) { throw 'Cannot authenticate to the existing database. Nothing was changed.' }
 $expected = Join-Path $oldState 'PostgreSQL18'
 if ($source.Replace('/','\').TrimEnd('\') -ne $expected.Replace('/','\').TrimEnd('\')) { throw 'Port 5433 belongs to a different database. Nothing was changed.' }
 New-Item -ItemType Directory -Force $libraryStateDir | Out-Null
 Get-ChildItem -LiteralPath $oldState -Filter '*.xml' | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $libraryStateDir }
 & "$pgBin\pg_basebackup.exe" -h 127.0.0.1 -p 5433 -U library_app -w -D $destination -X stream --checkpoint=fast
 if ($LASTEXITCODE -ne 0) { throw 'Database copy failed; the original database is untouched.' }
 & "$pgBin\pg_ctl.exe" stop -D $expected -m fast -w
 if ($LASTEXITCODE -ne 0) { throw 'Original server did not stop. The copy is retained; no data was deleted.' }
 & "$pgBin\pg_ctl.exe" start -D $destination -l (Join-Path $libraryStateDir 'postgres.log') -o '-p 5433 -h 127.0.0.1' -w
 if ($LASTEXITCODE -ne 0) { throw 'Copied database did not start. Original data is retained for recovery.' }
 Write-Host "Database copied safely to $destination. Original files retained."
} finally { Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue }
