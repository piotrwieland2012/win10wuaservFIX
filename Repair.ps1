Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv
Write-Host -Object ('The key that was pressed was: {0}' -f [System.Console]::ReadKey().Key.ToString());
