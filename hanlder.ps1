
function ProcessScheduler {
    #Обработчик хостов на перезагрузку и включения drain mode
    Write-Output "Proccess"

    while ($true)
    {
        $schedule_db = Get-Content '.\schedule.json' | Select-Object | ConvertFrom-Json
        $date = Get-Date
        $day = $date.Day
        $hour = $date.Hour 
        $minute = $date.Minute

        foreach ($val in $schedule_db.hosts) {
            if (($val.DrainMode -eq "Yes") -and ($val.DrainModeDay -eq $day) -and ($val.DrainModeHour -eq $hour) -and ($val.DrainModeMinute -eq $minute)) {
                #Если указан Drain Mode и время совпадает, проверяем, входит ли данный хост в список хостов с включенным Drain Mode
                #Если не входит, то добавляем в список для дальнейшего контроля
                $check = $schedule_db.DrainMode | Where-Object { $_.Name -eq $val.Name }
                if ($check) {
                    continue
                }
                else {
                    Write-Output "Time to enable DrainMode"
                    try {
                        #Отключаем возможность подключения к RDP (DrainMode Off)
                        Set-RDSessionHost -SessionHost $val.Name -NewConnectionAllowed No -ConnectionBroker "fs-zud-srv-04.zud.mrg.gazprom.ru"   
                    }
                    catch {
                        Write-Output "Failed to disable DrainMode!"
                    }
                    $schedule_db.DrainMode += @{
                        Name = $val.Name
                    }
                    $schedule_db | ConvertTo-Json -Depth 100 | Out-File ".\schedule.json"
                }
            }
            if (($val.RunningState) -and ($val.TimeRebootHour -eq $hour) -and ($val.TimeRebootMinute -eq $minute) -and ($val.TimeRebootDay -eq $day)) {
                #Проверка на время перезагрузки
                #Если запустили перезагрузку, то добавляем в список для дальнейшего контроля
                $check = $schedule_db.Reboot | Where-Object { $_.Name -eq $val.Name }
                if ($check) {
                    #Функция проверки доступности после перезагрузки вынесена в отдельный модуль check_status.ps1
                    continue
                }
                else {
                    Write-Output "Starting reboot " $val.Name
                    #Restart-Computer -ComputerName $val.Name -Force; Start-Sleep -Seconds
                    $schedule_db.Reboot += @{
                        Name = $val.Name
                    }
                    $schedule_db | ConvertTo-Json -Depth 100 | Out-File ".\schedule.json"
                }
            }
        }
        Start-Sleep -Seconds 30
    }
}
ProcessScheduler;