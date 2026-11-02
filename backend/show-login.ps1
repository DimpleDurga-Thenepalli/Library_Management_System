. (Join-Path $PSScriptRoot 'library-paths.ps1')
$config = Import-Clixml -LiteralPath (Join-Path $libraryStateDir 'credentials.xml')
Write-Host 'Select ADMIN on the login screen.'
Write-Host 'Username: admin'
Write-Host ('Password: ' + [System.Net.NetworkCredential]::new('', $config.AdminPassword).Password)
