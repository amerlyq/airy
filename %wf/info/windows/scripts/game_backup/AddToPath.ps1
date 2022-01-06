$oldPersonalPath = [Environment]::GetEnvironmentVariable("Path", "User")
$oldPersonalPath += ";"+"c:\TeX_Full\texmf\miktex\bin"
[Environment]::SetEnvironmentVariable("Path", $oldPersonalPath, "User")