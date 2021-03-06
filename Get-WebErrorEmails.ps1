#do nothing

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

UpdateStatusFile -key "lastStarted" -value (GetTime)

$currentStatus = "init"
UpdateStatusFile -key "currentStatus" -value $currentStatus

cd c:\WindowsPowerShell\PoSh\Load
. ./invoke-sqlcmd2.ps1

$DESTINATION = "dest"
$DESTINATIONDB = "destdb"

# First create Outlook object and get the Mapi namespace. 
[void] [System.Reflection.Assembly]::LoadWithPartialname("Microsoft.Office.Interop.Outlook")
$Outlook = New-Object -com Outlook.Application 
$Namespace = $Outlook.GetNamespace("MAPI") 

# Then look for specific folders.
$WebErrors    =  $Namespace.Folders    | ? { $_.name -eq "Web Errors"    }
$Inbox        =  $WebErrors.Folders    | ? { $_.name -eq "Inbox"         }
$DeletedItems =  $WebErrors.Folders    | ? { $_.name -eq "Deleted Items" }

$ToProcessCount = $Inbox.Items.Count
UpdateStatusFile -key "itemsCount" -value $ToProcessCount

#----------------------------------------------------------------------------------------------
#lets step thru the email items, if they are not marked as read, and put them into the database

if ( $ToProcessCount -gt 0) {
   UpdateStatusFile -key "currentStatus" -value "Processing..."

   $string = ""

   for ($inc = $Inbox.Items.count; $inc -gt 0 ; $inc--) {
      $Item = $Inbox.Items.Item($inc)

      if (($inc%100) -eq 0) {
         if ($string -ne "") {
            invoke-sqlcmd2 -Username "Monitoring" -Password "M0nitorm3" -query $string -ServerInstance $DESTINATION -database $DESTINATIONDB
         }

         $itemCount = $Inbox.Items.count
         $currentStatus = "Processed `'{0}`' of `'{1}`' in `'{2}`' items" -f $inc, $ToProcessCount, $itemCount
         UpdateStatusFile -key "currentStatus" -value $currentStatus
         UpdateStatusFile -key "itemsCount" -value $itemCount
      
         $string = ""
      }
      
      if ($Item.UnRead -eq $TRUE) {
         try { 
            if ($Item.Body.Length -ge 4000) { 
               $Body = $Item.Body.substring(0,4000)
            }
            else {
               $Body = $Item.Body.substring(0,$Item.Body.Length)
            }
         }
         catch {
            $ex = $_.Exception 
            Write-Error ""$ex.Message"" 
         }
      
         $Body = $Body.Replace("'","")
         $Subject = $Item.Subject
         $Date = $Item.CreationTime
         $Item.UnRead = $FALSE
   
         if ($Date) { $string += "INSERT INTO WebErrorEmails ( [Subject], [Body], [DateTime]) values ( '{0}', '{1}', '{2}');" -f $Subject,  $Body, $Date}
         if (!$Date) { $string += "INSERT INTO WebErrorEmails ( [Subject], [Body]) values ( '{0}', '{1}');" -f $Subject,  $Body}
      }

      $Item.Move($DeletedItems) | out-null
   }
} 

$Outlook.Quit()

if ($string -ne "") {
   invoke-sqlcmd2 -Username "user" -Password "pass" -query $string -ServerInstance $DESTINATION -database $DESTINATIONDB
}      

$itemCount = $Inbox.Items.count
UpdateStatusFile -key "itemsCount" -value $itemCount
UpdateStatusFile -key "lastEnded" -value (GetTime)
UpdateStatusFile -key "currentStatus" -value "Ended Successfully"