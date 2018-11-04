Param(
   [string]$PSerr
)

function UpdateStatusFile {
   param(
      [string]$key,
      [string]$value
   )

   $statusFile = 'status\status.json'
   $statusObj = (Get-Content $statusFile) -join "`n" | ConvertFrom-Json
   $statusObj.$key = $value
   $statusObj | ConvertTo-Json | Out-File $statusFile
   
   Write-Host "$key -> $value"
}

function GetTime {
   $dt = Get-Date -Format HH:mm:ss.fff
   $time = "{0:G}" -f [datetime]$dt
   return $time
}

$ErrorActionPreference = "stop"

$status = "Error - " + (GetTime) + " - Sending email..."
UpdateStatusFile -key "currentStatus" -value $status

$From = "no-reply-WEPM@domain.com"  
$To = "whoever@may.concern"
$Subject = "WEPM did not complete successfully" 
$Body = "Please check on it: http://localhost.local:12345/status `n`n$PSerr"
$SMTPServer = "smtp.server.ninja"

#Start-Sleep -s 15

Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer

$status = "Error - " + (GetTime) + " - Email sent."
UpdateStatusFile -key "currentStatus" -value $status
