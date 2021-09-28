#This is older content used in 2018, probably going to expand on the content later.

$obj1 = Get-CimInstance Win32_PnPEntity -Property *|  Where-Object {$_.ClassGuid -ne $null}
$obj2 = Get-CimInstance Win32_PNPSignedDriver -Property * |  Where-Object {$_.ClassGuid -ne $null}

[pscustomobject]$combined = foreach ($obj in $obj1) {
    #Lookup hostname in obj2 for current row in obj1
    $other = $obj2 | Where-Object{($_.ClassGuid -eq $obj.ClassGuid) -and ( $_.DeviceID -eq $obj.DeviceID)}

 

    #Loop thru all object in other query
    foreach ($subObj in @($other)) {
       #Create a new object
        $obj | Select `
        @{ n = "Class Description"; e = {$_.Class}},
        @{ n = "Driver"           ; e = {$_.Name}},
        @{ n = "File Name"        ; e = {$subObj.infName}},
        @{ n = "Version"          ; e = {$subObj.DriverVersion}},
        @{ n = "   Date   "       ; e = {$subObj.DriverDate}},
        @{ n = "Device ID"        ; e = {$subObj.DeviceID}},
        @{ n = "Bus Location"     ; e = {(($subObj.PDO).ToString()).Remove(0, 8).Replace('000000','')}},
        @{ n = "Status"           ; e = {$_.Status}},
        @{ n = "Service"          ; e = {$_.Service}},
        @{ n = "Guid"             ; e = {$_.ClassGuid}}
    }              
}
"Deteced PCI Devices: $($combined."Driver".Length)"
($combined|Sort-Object -Property "Class Description" -Descending| Format-Table -Property * -AutoSize | Out-String -Width 512).trim()