$file = (Get-ChildItem .\addons.xml)
$hash = (Get-FileHash -Path $file.FullName -Algorithm MD5).hash
Set-Content -Path ($file.BaseName + '.md5') -Value $hash -Force

