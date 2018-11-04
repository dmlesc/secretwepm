# First create Outlook object and get the Mapi namespace. 
[void] [System.Reflection.Assembly]::LoadWithPartialname("Microsoft.Office.Interop.Outlook")
$Outlook = New-Object -com Outlook.Application 
$Namespace = $Outlook.GetNamespace("MAPI") 

# Then look for specific folders.
$WebErrors    =  $Namespace.Folders    | ? { $_.name -eq "Web Errors"    }
$DeletedItems =  $WebErrors.Folders    | ? { $_.name -eq "Deleted Items" }

Write-Host $DeletedItems.Items.Count

$count = 0
foreach ($item in $DeletedItems.Items) {
   $item.Delete()
   $count++
   Write-Host $count
}
