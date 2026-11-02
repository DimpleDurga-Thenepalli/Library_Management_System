# Live API smoke test. Creates disposable records and removes them afterward.
param([switch]$PreparePersistence,[switch]$CheckPersistence)
. (Join-Path $PSScriptRoot 'library-paths.ps1')
$ErrorActionPreference = 'Stop'
$base = 'http://127.0.0.1:8080/api'
$config = Import-Clixml -LiteralPath (Join-Path $libraryStateDir 'credentials.xml')
function New-Client($username, $password) {
 $client = @{ Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession; Csrf = $null }
 $client.Csrf = Invoke-RestMethod "$base/auth/csrf" -WebSession $client.Session
 $headers = @{}; $headers[$client.Csrf.headerName] = $client.Csrf.token
 Invoke-RestMethod "$base/auth/login" -Method Post -WebSession $client.Session -Headers $headers -Body @{username=$username;password=$password} | Out-Null
 $client.Csrf = Invoke-RestMethod "$base/auth/csrf" -WebSession $client.Session
 return $client
}
function Call($client,$method,$path,$body=$null) {
 $headers=@{}; $headers[$client.Csrf.headerName]=$client.Csrf.token
 $args=@{Uri="$base$path";Method=$method;WebSession=$client.Session;Headers=$headers}
 if ($null -ne $body) {$args.ContentType='application/json';$args.Body=ConvertTo-Json -InputObject $body -Depth 10 -Compress}
 Invoke-RestMethod @args
}
function Assert($condition,$label) {if(!$condition){throw "FAIL: $label"};Write-Host "PASS: $label"}
function Denied($client,$method,$path,$body,$status) {try{Call $client $method $path $body | Out-Null;throw "Expected HTTP $status for $path"}catch{if([int]$_.Exception.Response.StatusCode -ne $status){throw}}}
$admin=New-Client 'admin' ([System.Net.NetworkCredential]::new('', $config.AdminPassword).Password)
$fixturePath=Join-Path $PSScriptRoot '.local/persistence.json'
if($PreparePersistence){
 $fixtureBook=Call $admin Post '/admin/books' @{title='Persistence verification';author='Verification';genre='Testing';description='Disposable restart fixture';price=1}
 $fixtureChapter=Call $admin Post "/admin/books/$($fixtureBook.id)/chapters" @{title='Saved chapter';content='<h2>Saved heading</h2><p>This content must survive a server restart.</p>'}
 Call $admin Put "/books/$($fixtureBook.id)/progress" @{chapterId=$fixtureChapter.id} | Out-Null
 $fixtureUser=Call $admin Post '/admin/customers' @{fullName='Persistence Reader';username=('persist_'+[guid]::NewGuid().ToString('N').Substring(0,8));email=([guid]::NewGuid().ToString('N')+'@example.test');active=$true;password=('Persist-'+[guid]::NewGuid().ToString('N'))}
 New-Item -ItemType Directory -Force (Split-Path $fixturePath) | Out-Null
 @{bookId=$fixtureBook.id;chapterId=$fixtureChapter.id;userId=$fixtureUser.id}|ConvertTo-Json|Set-Content $fixturePath
 Write-Host 'Restart fixture saved: book, chapter, customer and reading progress.'
 return
}
if($CheckPersistence){
 $fixture=Get-Content $fixturePath -Raw|ConvertFrom-Json
 Assert ((Call $admin Get "/books/$($fixture.bookId)").title -eq 'Persistence verification') 'Book survived restart'
 $fixtureChapters=Call $admin Get "/books/$($fixture.bookId)/chapters"
 Assert ($fixtureChapters[0].content -match 'must survive a server restart') 'Chapter content survived restart'
 Assert ((Call $admin Get "/books/$($fixture.bookId)/progress").chapterId -eq $fixture.chapterId) 'Reading progress survived restart'
 Assert (@(Call $admin Get '/admin/customers').id -contains $fixture.userId) 'Customer survived restart'
 Call $admin Delete "/admin/books/$($fixture.bookId)" | Out-Null
 Call $admin Delete "/admin/customers/$($fixture.userId)" | Out-Null
 Remove-Item -LiteralPath $fixturePath
 return
}
$suffix=[guid]::NewGuid().ToString('N').Substring(0,10)
$book=$null;$customer=$null
try {
 $me=Call $admin Get '/auth/me';Assert ($me.role -eq 'ADMIN') 'Real admin authentication'
 Assert (-not ($me.PSObject.Properties.Name -contains 'passwordHash')) 'Passwords absent from user responses'
 $d=@{title="Verification $suffix";author='Test Author';isbn="TEST-$suffix";genre='Testing';description='Disposable integration test book';price=5.25;publicationDate='2026-01-01'}
 $book=Call $admin Post '/admin/books' $d;Assert ($book.status -eq 'DRAFT') 'Create draft book'
 $d.title="Verified $suffix";$updated=Call $admin Put "/admin/books/$($book.id)" $d;Assert ($updated.title -eq $d.title) 'Update book metadata'
 Add-Type -AssemblyName System.Net.Http
 Add-Type -AssemblyName System.Drawing
 $handler=New-Object System.Net.Http.HttpClientHandler
 $handler.CookieContainer=$admin.Session.Cookies
 $http=New-Object System.Net.Http.HttpClient($handler)
 $http.DefaultRequestHeaders.Add($admin.Csrf.headerName,$admin.Csrf.token)
 $bitmap=New-Object System.Drawing.Bitmap(4,4)
 $stream=New-Object System.IO.MemoryStream
 $bitmap.Save($stream,[System.Drawing.Imaging.ImageFormat]::Png)
 $multipart=New-Object System.Net.Http.MultipartFormDataContent
 $imageContent=[System.Net.Http.ByteArrayContent]::new($stream.ToArray())
 $imageContent.Headers.ContentType=[System.Net.Http.Headers.MediaTypeHeaderValue]::new('image/png')
 $multipart.Add($imageContent,'file','test.png')
 try{$response=$http.PostAsync("$base/admin/books/$($book.id)/cover",$multipart).GetAwaiter().GetResult();Assert ($response.IsSuccessStatusCode) 'Cover image upload';$covered=Call $admin Get "/books/$($book.id)";Assert ($covered.coverImagePath.StartsWith('data:image/png;base64,')) 'Cover image persisted in PostgreSQL'}finally{$multipart.Dispose();$stream.Dispose();$bitmap.Dispose();$http.Dispose()}
 $c1=Call $admin Post "/admin/books/$($book.id)/chapters" @{title='First';content='<h2>Heading</h2><p>A complete original test paragraph.</p><script>alert(1)</script>'}
 Assert ($c1.content -notmatch '<script' -and $c1.content -match '<h2>') 'Chapter HTML sanitization preserves headings'
 $c2=Call $admin Post "/admin/books/$($book.id)/chapters" @{title='Second';content='<p>The second chapter.</p>'}
 Call $admin Put "/admin/books/$($book.id)/chapters/order" @($c2.id,$c1.id) | Out-Null
 $ordered=Call $admin Get "/books/$($book.id)/chapters";Assert ($ordered[0].id -eq $c2.id) 'Reorder chapters'
 $edited=Call $admin Put "/admin/books/$($book.id)/chapters/$($c1.id)" @{title='First revised';content='<p>Edited story.</p>'};Assert ($edited.title -eq 'First revised') 'Edit chapter'
 $password='Reader-'+[guid]::NewGuid().ToString('N')
 $u=@{fullName='Verification Reader';username="verify_$suffix";email="verify_$suffix@example.test";phoneNumber='1234567890';password=$password;active=$true}
 $customer=Call $admin Post '/admin/customers' $u;Assert ($customer.role -eq 'CUSTOMER') 'Create customer account'
 $reader=New-Client $u.username $password
 Denied $reader Get "/books/$($book.id)" $null 404
 Denied $reader Get "/books/$($book.id)/chapters" $null 404
 Assert ($true) 'Customer cannot access draft or draft content'
 Denied $reader Post '/admin/books' $d 403
 Denied $reader Get '/admin/customers' $null 403
 Assert ($true) 'Customer cannot manage books or users'
 Call $admin Put "/admin/books/$($book.id)/status" @{published=$true} | Out-Null
 $visible=Call $reader Get "/books/$($book.id)";Assert ($visible.status -eq 'PUBLISHED') 'Published book visible to customer'
 Call $reader Put "/books/$($book.id)/progress" @{chapterId=$c1.id} | Out-Null
 $p=Call $reader Get "/books/$($book.id)/progress";Assert ($p.chapterId -eq $c1.id) 'Reading progress saved and retrieved'
 $u.fullName='Updated Reader';$u.Remove('password');$updated=Call $admin Put "/admin/customers/$($customer.id)" $u;Assert ($updated.fullName -eq 'Updated Reader') 'Update customer details'
 Call $admin Put "/admin/customers/$($customer.id)/active" @{active=$false} | Out-Null
 Denied $reader Get '/auth/me' $null 401
 Assert ($true) 'Deactivation revokes existing session on next request'
 Call $admin Put "/admin/customers/$($customer.id)/active" @{active=$true} | Out-Null
 $newPassword='Reset-'+[guid]::NewGuid().ToString('N')
 Call $admin Put "/admin/customers/$($customer.id)/password" @{password=$newPassword} | Out-Null
 $reader=New-Client $u.username $newPassword
 Assert ((Call $reader Get '/auth/me').id -eq $customer.id) 'Reset password authenticates with new password'
 Call $admin Put "/admin/books/$($book.id)/status" @{published=$false} | Out-Null
 Denied $reader Get "/books/$($book.id)" $null 404
 Assert ($true) 'Unpublishing removes customer access'
 Call $admin Delete "/admin/books/$($book.id)/chapters/$($c1.id)" | Out-Null
 $left=@(Call $admin Get "/books/$($book.id)/chapters");Assert ($left.Count -eq 1 -and $left[0].chapterNumber -eq 1) 'Delete chapter and normalize ordering'
 Call $reader Post '/auth/logout' | Out-Null
 Denied $reader Get '/auth/me' $null 401
 Assert ($true) 'Logout invalidates session'
} finally {
 if($book){Call $admin Delete "/admin/books/$($book.id)" | Out-Null;Write-Host 'PASS: Delete test book'}
 if($customer){Call $admin Delete "/admin/customers/$($customer.id)" | Out-Null;Write-Host 'PASS: Delete test customer'}
}
Write-Host 'All live API checks passed.'
