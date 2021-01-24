$version = '1.1'

$file = (Get-ChildItem .\latestaddons.xml)
$hash = (Get-FileHash -Path $file.FullName -Algorithm MD5).hash
Set-Content -Path ($file.FullName + '.md5') -Value $hash -Force

<# Kodi doesnt like compress-archive find alternative
$DirToCompress=".\repository.hexdemon"
$TempDir = "$env:TEMP\repository.hexdemon"
$ZipFile=".\repository.hexdemon\repository.hexdemon-$($version).zip"

Remove-Item -Force $TempDir
New-Item $TempDir -ItemType "directory"
Get-ChildItem $DirToCompress -Exclude '*.zip' | Copy-Item -Destination $TempDir -Force
Compress-Archive $TempDir -DestinationPath $ZipFile
#>