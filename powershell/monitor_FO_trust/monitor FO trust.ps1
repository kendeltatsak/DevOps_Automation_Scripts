
# Function to send email if trust is broken
function global:trustBroken(){

    $global:down = Get-Date -Format g;
    Write-Host "date $down in trustBroken"
    $password = $Env:FOCTrustEmail
    $password = ConvertTo-SecureString “PlainTextPassword” -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential (“xxxx.xxxxx.xxxxx@xxxxxx.com”, $password)
    $From = "xxx.xxx.xxxx@xxxxxxx.com"
    $To = "helpdesk@xxxxxx.com"
    $CC = "kendel.tatsak@xxxxxx.com"
    $Subject = "FOC Trust is Down or otherwise unreachable"
    $Body = "Trust went down at $down or is otherwise unreachable. `n`t`n Please reply all to this email if you're able to fix it."
    $SMTPServer = "10.20.143.90"
    Send-MailMessage -From $From -to $To -cc $CC -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Credential $Cred
}

# Function to send me an email for every 24 hours the trust stays up
function global:trustUpForXDays(){
    
    $password = $Env:FOCTrustEmail
    $password = ConvertTo-SecureString “PlainTextPassword” -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential (“xxx.xxxx.xxxxxx@xxxxxxx.com”, $password)
    $From = "xxx.xxx.xxxx@xxxxxxx.com"
    $To = "helpdesk@xxxxxx.com"
    $CC = "kendel.tatsak@xxxxxx.com"
    $Subject = "FOC Trust is Down or otherwise unreachable"
    $Body = "Trust went down at $down or is otherwise unreachable. `n`t`n Please reply all to this email if you're able to fix it."
    $SMTPServer = "10.20.143.90"
    Send-MailMessage -From $From -to $To -cc $CC -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Credential $Cred
    
}

# Frunction to send email once trust has been restored
function global:trustRestored(){

    $global:restDate = Get-Date -Format g;
    Write-Host "date $restDate in trustRestored"
    $password = $Env:FOCTrustEmail
    $password = ConvertTo-SecureString “PlainTextPassword” -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential (“FOC.Trust.Notifications@spectrummg.com”, $password)
    $From = "FOC.Trust.Notifications@spectrummg.com"
    $To = "smg.it.support@spectrummg.com"
    $CC = "kendel.tatsak@spectrummg.com"
    $Subject = "FOC Trust has been restored and has regained connectivity"
    $time = New-TimeSpan -Start $down -End $restDate
    Write-Host "time $time in trustRestored"
    $Body = "Trust was restored on $restDate ; conectvity has been restored. `n`t`n Trust was down for " + $time.Days + " days " + $time.Hours + " hours " + $time.Minutes + " minutes."
    $SMTPServer = "10.20.143.90"
    Send-MailMessage -From $From -to $To -cc $CC -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Credential $Cred
}

# Main Method
function mainProgram(){

    # initialize count variables
    $i = 0; # minutes
    $d = 0; # days
    while($true){

        $bool = Test-Path \\server01\common\chuck;

        if($bool -eq $true){ # server01 reachable
            Start-Sleep -Seconds 300
            $i = $i + 5;
            Write-Host ("trust has been up for $i minutes.");
            if ($i % 1440 -eq 0){ # 1440 minutes in a 24 period
                $d = $d + 1;
                trustUpForXDays; # Function to send me an email for every 24 hours the trust stays up
            }
        } 
        else { # server01 unreachable
            Start-Sleep -Seconds 300 # wait 5 minutes then double check to see if server01 is still unreachable
            $bool = Test-Path \\server01\common\chuck;
            if ($bool -eq $false){ # server01 unreachable
                trustBroken; # Function to send email if trust is broken
                $d = 0; # reset days counter back to 0
                    while($bool -eq $false){
                        Write-Host "trust has been down for $d minutes"
                        Start-Sleep -Seconds 60
                        $d = $d + 1;
                        $bool = Test-Path \\server01\common\chuck;
                    }
                trustRestored; # Function to send email once trust has been restored
                Write-Host("Trust has been restored")
                $i = 0; # reset counter variable
                $d = 0;
            }
        }
    }
}

mainProgram;