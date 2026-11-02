# Use a normal user-profile directory shared by VS Code and packaged desktop apps.
# LocalAppData can be virtualized differently by Windows for packaged applications.
$libraryStateDir = Join-Path $env:USERPROFILE 'FolioLibrary'
