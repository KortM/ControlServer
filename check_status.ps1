function Loop{
    while ($true)
    {
        $schedule_db = Get-Content '.\schedule.json' | Select-Object | ConvertFrom-Json
        foreach ($val in $schedule_db.Reboot)
        {
            $res = TNC $val.Name -Port 3389
            Write-Output $res.TcpTestSucceeded
           #Start-Job -ScriptBlock { TNC $val.Name -Port 3389 } | Wait-Job | Receive-Job
        }
    }
    Start-Sleep -Seconds 2
}
Loop;