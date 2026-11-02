. (Join-Path $PSScriptRoot 'library-paths.ps1')
$ErrorActionPreference = 'Stop'
$base = 'http://127.0.0.1:8080/api'
$stateDir =  $libraryStateDir
$config = Import-Clixml -LiteralPath (Join-Path $stateDir 'credentials.xml')
$adminPassword = [System.Net.NetworkCredential]::new('', $config.AdminPassword).Password
function Login($username, $password) {
 $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
 $csrf = Invoke-RestMethod "$base/auth/csrf" -WebSession $session
 $headers = @{}; $headers[$csrf.headerName] = $csrf.token
 Invoke-RestMethod "$base/auth/login" -Method Post -WebSession $session -Headers $headers -Body @{username=$username;password=$password} | Out-Null
 return $session
}
$admin = Login 'admin' $adminPassword
$csrf = Invoke-RestMethod "$base/auth/csrf" -WebSession $admin
$headers = @{}; $headers[$csrf.headerName] = $csrf.token
$existing = @(Invoke-RestMethod "$base/admin/customers" -WebSession $admin)
foreach ($demo in @(
 @{username='demo.aarav';fullName='Aarav Sharma';email='demo.aarav@example.test'},
 @{username='demo.meera';fullName='Meera Patel';email='demo.meera@example.test'}
)) {
 $credentialFile = Join-Path $stateDir ($demo.username + '.xml')
 if ($existing.username -contains $demo.username) {
  if (!(Test-Path $credentialFile)) { throw "Account $($demo.username) already exists; its password will not be overwritten." }
  $password = [System.Net.NetworkCredential]::new('', (Import-Clixml -LiteralPath $credentialFile)).Password
 } else {
  $password = 'Read-' + [guid]::NewGuid().ToString('N').Substring(0,16) + '!'
  $body = @{fullName=$demo.fullName;username=$demo.username;email=$demo.email;phoneNumber='';active=$true;password=$password} | ConvertTo-Json
  Invoke-RestMethod "$base/admin/customers" -Method Post -WebSession $admin -Headers $headers -ContentType 'application/json' -Body $body | Out-Null
  ConvertTo-SecureString $password -AsPlainText -Force | Export-Clixml -LiteralPath $credentialFile
 }
 $reader = Login $demo.username $password
 $me = Invoke-RestMethod "$base/auth/me" -WebSession $reader
 if ($me.role -ne 'CUSTOMER' -or !$me.active) { throw 'Demo customer verification failed.' }
 Write-Host "VERIFIED CUSTOMER: $($demo.fullName) | Username: $($demo.username) | Password: $password"
}
Write-Host "VERIFIED ADMIN: Username: admin | Password: $adminPassword"
