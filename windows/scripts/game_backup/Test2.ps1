function Pause
{
    Write-Host -NoNewLine "Press any key to continue . . . "
    [Console]::ReadKey($true) | Out-Null
    Write-Host
}

Pause