[void] [reflection.assembly]::LoadWithPartialName("System.Windows.Forms")

$WarningPreference = 'silentlycontinue'
$ErrorActionPreference = "silentlycontinue"

#create Application box
$form = New-Object System.Windows.Forms.Form
    #$form.text = "Logoff"
    $form.size = New-Object System.Drawing.Size(220, 180)
    $form.TopMost = $true
    $form.MaximizeBox = $true
    $form.MinimizeBox = $true
    $form.ControlBox = $true
    $form.StartPosition = "CenterScreen"

#create Label Text
$label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Size(8, 8)
    $label.size = New-Object System.Drawing.Size(240, 32)
    $label.TextAlign = "topleft"
    $label.text = "Click to sign out of Therapy Source"
    $form.Controls.Add($label)

#create Button
$button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Size(8, 60)
    $button.Size = New-Object System.Drawing.Size(180, 32)
    $button.TextAlign = "middlecenter"
    $button.text = "Sign Out"
    $button.add_click({

    $logInfo = Get-Date -Format g

    #Query each of the three Therapy servers for whoever is running the application
    $ther1 = quser /server:shcp-rds-ther1 | Where-Object {$_ -match $env:USERNAME}
    $ther2 = quser /server:shcp-rds-ther2 | Where-Object {$_ -match $env:USERNAME}
    $ther3 = quser /server:shcp-rds-ther3 | Where-Object {$_ -match $env:USERNAME}

Try{

    $ErrorActionPreference = "stop"

    #See which server the user is logged into and run Invoke-RDUserLogoff against their session ID
    if($ther1 -ne $null){
        $id = ($ther1 -split ' +')[3]
        #Invoke-RDUserLogoff -HostServer shcp-rds-ther1 -UnifiedSessionID $id -Force
        logoff $id /server:shcp-rds-ther1
        $old = Get-Content "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $logInfo = "$env:USERNAME SHCP-RDS-THER1 $logInfo"
        $logInfo | Out-File -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $old | Out-File -Append -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        write-host("User $env:USERNAME was logged off of shcp-rds-ther1 c:" + ($old.Length + 1))
    } elseif ($ther2 -ne $null){
        $id = ($ther2 -split ' +')[3]
        #Invoke-RDUserLogoff -HostServer shcp-rds-ther2 -UnifiedSessionID $id -Force
        logoff $id /server:shcp-rds-ther2
        $old = Get-Content "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $logInfo = "$env:USERNAME SHCP-RDS-THER2 $logInfo"
        $logInfo | Out-File -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $old | Out-File -Append -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        write-host("User $env:USERNAME was logged off of shcp-rds-ther2 c:" + ($old.Length + 1))
    } elseif ($ther3 -ne $null){
        $id = ($ther3 -split ' +')[3]
        #Invoke-RDUserLogoff -HostServer shcp-rds-ther3 -UnifiedSessionID $id -Force
        logoff $id /server:shcp-rds-ther3
        $old = Get-Content "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $logInfo = "$env:USERNAME SHCP-RDS-THER3 $logInfo"
        $logInfo | Out-File -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $old | Out-File -Append -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        write-host("User $env:USERNAME was logged off of shcp-rds-ther3 c:" + ($old.Length + 1))
    } else {
        write-host("User $env:USERNAME was not found")
    }
} Catch {

    #See which server the user is logged into and run Invoke-RDUserLogoff against their session ID
    if($ther1 -ne $null){
        $id = ($ther1 -split ' +')[2]
        #Invoke-RDUserLogoff -HostServer shcp-rds-ther1 -UnifiedSessionID $id -Force
        logoff $id /server:shcp-rds-ther1
        $old = Get-Content "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $logInfo = "$env:USERNAME SHCP-RDS-THER1 $logInfo"
        $logInfo | Out-File -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $old | Out-File -Append -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        write-host("User $env:USERNAME was logged off of shcp-rds-ther1 c:" + ($old.Length + 1))
    } elseif ($ther2 -ne $null){
        $id = ($ther2 -split ' +')[2]
        #Invoke-RDUserLogoff -HostServer shcp-rds-ther2 -UnifiedSessionID $id -Force
        logoff $id /server:shcp-rds-ther2
        $old = Get-Content "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $logInfo = "$env:USERNAME SHCP-RDS-THER2 $logInfo"
        $logInfo | Out-File -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $old | Out-File -Append -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        write-host("User $env:USERNAME was logged off of shcp-rds-ther2 c:" + ($old.Length + 1))
    } elseif ($ther3 -ne $null){
        $id = ($ther3 -split ' +')[2]
        #Invoke-RDUserLogoff -HostServer shcp-rds-ther3 -UnifiedSessionID $id -Force
        logoff $id /server:shcp-rds-ther3
        $old = Get-Content "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $logInfo = "$env:USERNAME SHCP-RDS-THER3 $logInfo"
        $logInfo | Out-File -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        $old | Out-File -Append -FilePath "\\oapfs1\Apps\Apps\Install\TherapySource freeze log\Therapy Source freeze log.txt"
        write-host("User $env:USERNAME was logged off of shcp-rds-ther3 c:" + ($old.Length + 1))
    } else {
        write-host("User $env:USERNAME was not found")
    }
}
})

#Add button to form, show form
$form.Controls.Add($button)
[void] $form.ShowDialog()