function Loop {
    while ($true) {
        $schedule_db = Get-Content '.\schedule.json' | Select-Object | ConvertFrom-Json
        foreach ($val in $schedule_db.Reboot) {
            if ($val) {
                #Бесконечно проверяем хосты в файле .\schedule.json из списка Reboot
                #Проверяем подключение на порт RDP через TNC
                $res = TNC $val.Name -Port 3389 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if ($res.TcpTestSucceeded) {
                    #Удалось подключиться на порт
                    Write-Output "Host is UP -> $($val.Name):3389"
                    if ($schedule_db.DrainMode | Where-Object { $_.Name -eq $val.Name }){
                        try {
                            #Включаем DrainMode на хосте
                            Set-RDSessionHost -SessionHost $val.Name -NewConnectionAllowed Yes -ConnectionBroker "fs-zud-srv-04.zud.mrg.gazprom.ru"
                            #Set-RDSessionHost -SessionHost $val.Name -NewConnectionAllowed Yes -ConnectionBroker "192.168.2.2"
                        }
                        catch {
                            Write-Output "Host is up, but dosn't enable DrainMode"
                        }
                        $schedule_db.DrainMode = $schedule_db.DrainMode | Where-Object { $_.Name -ne $val.Name }
                    }
                    #Удаляем из списка хостов на перезагрузку
                    $schedule_db.Reboot = $schedule_db.Reboot | Where-Object { $_.Name -ne $val.Name }
                    if ($schedule_db.Reboot.Count -eq 0) {
                        $schedule_db.Reboot += New-Object string[] 1
                    }
                    $schedule_db | ConvertTo-Json -Depth 100 | Out-File '.\schedule.json'
                }
                else {
                    #Не удалось подключиться на порт
                    Write-Output "Host is Down -> $($val.Name):3389"
                }
            }
            
        }
        Start-Sleep -Seconds 2
    }
    
}
Loop;