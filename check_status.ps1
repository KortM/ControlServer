function Loop{
    while ($true)
    {
        $schedule_db = Get-Content '.\schedule.json' | Select-Object | ConvertFrom-Json
        foreach ($val in $schedule_db.Reboot)
        {
            #Бесконечно проверяем хосты в файле .\schedule.json из списка Reboot
            #Проверяем подключение на порт RDP через TNC
            $res = TNC $val.Name -Port 3389
            if ($res.TcpTestSucceeded)
            {
                #Удалось подключиться на порт
                Write-Output "Host is UP -> $($val.Name):3389"
                #Включаем DrainMode на хосте
                try {
                    Set-RDSessionHost -SessionHost $val.Name -NewConnectionAllowed Yes -ConnectionBroker "fs-zud-srv-04.zud.mrg.gazprom.ru"
                }
                catch {
                    Write-Output "Host is up, but dosn't enable DrainMode"
                }
                #Удаляем из списка хостов на перезагрузку
                $schedule_db.Reboot = $schedule_db.Reboot | Where-Object {$_.Name -ne $val.Name}
                $schedule_db | ConvertTo-Json -Depth 100 | Out-File '.\schedule.json'
            }
            else
            {
                #Не удалось подключиться на порт
                Write-Output "Host is Down -> $($val.Name):3389"
            }
        }
    }
    Start-Sleep -Seconds 2
}
Loop;