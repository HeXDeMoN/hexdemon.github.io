$file = '.\addons.xml'
$hash = (Get-FileHash -Path $file -Algorithm MD5).hash
Add-Content -Path ($file + '.md5') -Value $hash
