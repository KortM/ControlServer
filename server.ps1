using namespace System.Collections.Generic;
try {
    $config_file = Get-Content 'config.ini' | Select-Object -Skip 1 | ConvertFrom-StringData
    $schedule_db = Get-Content 'schedule.json' | Select-Object | ConvertFrom-Json
    $schedule_pid = 0
}
catch {
    Write-Output "Not found configuration files: config.ini and schedule.json"
}
function main() {
    loop;
}
function send_mail {
    Write-Output "Sending email notification..."
    try {
        Send-MailMessage -From $config_file.email -To $config_file.recepients -Subject "Reboot Script" -SmtpServer $config_file.server
    }
    finally {
        Write-Output "Error sending email message!"
    }
}
function StopSchedule{
    $file_PID = New-Object System.IO.StreamReader{.\PID.txt}
    $schedule_pid = $file_PID.ReadLine()
    $file_PID.Close()
    $p_proc = Get-Process | Where-Object {$_.Id -eq $schedule_pid}
    try {
        $p_proc.Kill()
        Write-Host "Schedule running canceled!" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Schedule is not running" -ForegroundColor Red
    }
}
function Status{
    $file_PID = New-Object System.IO.StreamReader{.\PID.txt}
    $schedule_pid = $file_PID.ReadLine()
    $file_PID.Close()
    $p_proc = Get-Process | Where-Object {$_.Id -eq $schedule_pid}
    if ($p_proc)
    {
        Write-Host "Shedule is running" -ForegroundColor Green
    }
    else
    {
        Write-Host "Schedule is not running" -ForegroundColor Red
    }
}
function check_running {
    $file_PID = New-Object System.IO.StreamReader{.\PID.txt}
    $schedule_pid =  $file_PID.ReadLine()
    $file_PID.Close()
    $pr = Get-Process | Where-Object {$_.Id -eq $schedule_pid}
    if ($pr)
    {
        return $true
    }else
    {
        return $false
    }
}
function StartSchedule{
    if (check_running)
    {
        Write-Host "Schedule state is running! Not start new proccess" -ForegroundColor Red
        send_mail;
    }
    else
    {
        $schedule_process =  Start-Process powershell -ArgumentList ".\hanlder.ps1" -PassThru -WindowStyle Hidden
        Write-Output $schedule_process.Id | Out-File ".\PID.txt" 
        Write-Host "Schedule state is running" -ForegroundColor Green
    }
}
function ListHosts {
    #TODO
    Write-Output "List host:"
    $db = Get-Content -Path ".\schedule.json" -Raw | ConvertFrom-Json
    $hosts = [System.Collections.ArrayList]::new()
    foreach ($val in $db.hosts)
    {
        $drain_date = Get-Date -Hour $val.DrainModeHour -Day $val.DrainModeDay -Minute $val.DrainModeMinute
        $reboot_date = Get-Date -Hour $val.TimeRebootHour -Day $val.TimeRebootDay -Minute $val.TimeRebootMinute
        $drain_mode = $val.DrainMode

        $hosts.Add(@{
            Host = $val.Name
            TimeReboot = $reboot_date
            DrainMode = $drain_mode
            DrainModeTime = $drain_date
        })
    }
    $hosts | Format-Table -AutoSize;
    #$db.hosts | Format-Table -AutoSize;
}
function addHost {
    param (
        $h,
        $time_reboot_day,
        $time_reboot_hour,
        $time_reboot_minute,
        $drain_mode,
        $time_drain
    )
    Write-Host "Coount "
    $date = Get-Date -Day $time_reboot_day -Hour $time_reboot_hour -Minute $time_reboot_minute
    $schedule_db.hosts += @{
        Name             = $h
        TimeRebootDay    = $time_reboot_day
        TimeRebootHour   = $time_reboot_hour
        TimeRebootMinute = $time_reboot_minute
        DrainMode        = $drain_mode
        DrainModeDay     = $date.AddHours(-$time_drain).Day
        DrainModeHour    = $date.AddHours(-$time_drain).Hour
        DrainModeMinute  = $date.AddHours(-$time_drain).Minute
        RunningState     = $true
    }
    $schedule_db | ConvertTo-Json -Depth 100 | Out-File "schedule.json"
}
function deleteHost {
    param (
        $h
    )
    $db = Get-Content -Path ".\schedule.json" -Raw | ConvertFrom-Json
    $check = $db.hosts | Where-Object { $_.Name -eq $h }
    if ($check)
    {
        $db.hosts = $db.hosts | Where-Object { $_.Name -ne $h }
        if ($db.hosts.Length -le 1)
        {
            $db.hosts = @()
            Write-Output $db.hosts
            $db | ConvertTo-Json -Depth 100 | Out-File "schedule.json"
            Write-Host "Delete success!" -ForegroundColor Green
        }
        else
        {
            Write-Output $db.hosts
            $db | ConvertTo-Json -Depth 100 | Out-File "schedule.json"
            Write-Host "Delete success!" -ForegroundColor Green
        }
        
    }
    else
    {
        Write-Host "No host in the list: $h" -ForegroundColor Red
    }
    
}
function loop {

    while ($true) {
        $key = Read-Host "-----------------
0: Add host to schedule
1: Delete host from schedule
2: List Hosts
3: Status
4: Start schedule
5: Stop schedule
6: Exit
-----------------
"
        if ($key -eq 6) {
            return
        }
        if ($key -eq 0) {
            $h = Read-Host "Input host domain name: ";
            $drain = Read-Host "Enable Drain Mode?[Default No] "
            $time_reboot_day = Read-Host "Time reboot server day of month:"
            $time_reboot_hour = Read-Host "Time reboot server hour"
            $time_reboot_minute = Read-Host "Time reboot minute"
            if (($drain -eq "yes") -or ($drain -eq "Yes")) {
                $time_drain = Read-Host "Time enable Drain Mode (format: time_reboot - time drain mode )"
            }
            else {
                $drain = "No"
                $time_drain = 0
            }
            if (($h.Length -gt 0) -and ($time_reboot_day.Length -gt 0) -and ($time_reboot_hour.Length -gt 0) -and ($time_reboot_minute.Length -gt 0)) {
                addHost -h $h -time_reboot_day $time_reboot_day -time_reboot_hour $time_reboot_hour -time_reboot_minute $time_reboot_minute -drain_mode $drain -time_drain $time_drain
            }
            else {
                Write-Host "Failed add host to scheduler! All parameters not specified!" -ForegroundColor Red
                continue
            }
        }
        if ($key -eq 1) {
            $h = Read-Host "Input host domain name: "
            if ($h.Length -gt 0) {
                deleteHost($h)
            }
            else
            {
                Write-Host "Not valid input" -ForegroundColor Red
            }
        }
        if ($key -eq 2) {
            ListHosts;
        }
        if ($key -eq 3) {
            Status;
        }
        if ($key -eq 4)
        {
            StartSchedule;
        }
        if ($key -eq 5)
        {
            StopSchedule;
        }
    }
}
main;