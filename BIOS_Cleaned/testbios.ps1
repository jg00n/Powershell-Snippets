#
# This is a BIOS configurator, the principle is that it first generates an excel template consisting of the possible BIOS configurations for a machine.
# Then you could edit it and use it to automatically configure "most" settings. Handy for mass deployments.
# NOTE: Have only tested on a lenovo enviroment and on a portable edition of windows.
#
# The origins of this script is composed of this source here: http://www.systanddeploy.com/2019/03/list-and-change-bios-settings-with.html
#
# Some client sensitive data has been omitted from this sample. 
# Note added 9/28/21. Last tested sometime before 3/10/20.

#Elevate user account.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
    $Global:Result = $null
    $Model = (Get-CimInstance -ClassName Win32_Computersystem).Model


function BIOSParse{
    begin{
    #This is redundant.
    $Manfact = (Get-CimInstance -ClassName "Win32_ComputerSystem").Manufacturer
    $Type = "BIOS Type: $Manfact"
 }
    process{

        switch ($Manfact){

            {$_ -contains "LENOVO"}{
            #Refer to article https://download.lenovo.com/pccbbs/mobiles_pdf/kbl-r_deploy_01.pdf for documentation
            $IsPasswordSet = (Get-wmiObject -Class Lenovo_BiosPasswordSettings -Namespace root\wmi -ComputerName $env:ComputerName).PasswordState
            #Refer to article https://forums.lenovo.com/t5/Enterprise-Client-Management/Script-or-Query-for-Hard-Drive-Password/m-p/3401031#M2470
                switch($IsPasswordSet){
                 0{"No Password Set"}
                 1{"Power on Password Set"}
                 2{"Supervisor Password Set"}
                 default{"Password set in multiple conditions, shouldn't see this in typical builds"}
                 }

                 #Announce Type
                $Type
                $Script:Get_BIOS_Settings = Get-CimInstance -ClassName Lenovo_BiosSetting  -namespace root\wmi  | select-object currentsetting | Where-Object {$_.CurrentSetting -ne ""} |
                    select-object @{label = "Setting"; expression = {$_.currentsetting.split(",")[0]}} , 
                    @{label = "Value"; expression = {$_.currentsetting.split(",*;[")[1]}}
                    $Global:Result = $IsPasswordSet
            }
            {$_ -contains "HP"}{
                $Type
                $Script:Get_BIOS_Settings = Get-WmiObject -Namespace root/hp/instrumentedBIOS -Class hp_biosEnumeration -ErrorAction SilentlyContinue |  
                    ForEach-Object { New-Object psobject -Property @{    
                        Setting = $_."Name"
                        Value = $_."currentvalue"
                        Available_Values = $_."possiblevalues"}
                    }| select-object Setting, Value, possiblevalues
            }
            {$_ -contains "Dell"}{
                $Type
                $WarningPreference='silentlycontinue'
                If (Get-Module -ListAvailable -Name DellBIOSProvider){} 
                Else{Install-Module -Name DellBIOSProvider -Force}
                get-command -module DellBIOSProvider | out-null
                $Script:Get_BIOS_Settings = get-childitem -path DellSmbios:\ | select-object category | 
                ForEach-Object {
                    get-childitem -path @("DellSmbios:\" + $_.Category)  | select-object attribute, currentvalue} 
                $Script:Get_BIOS_Settings = $Get_BIOS_Settings |  ForEach-Object { New-Object psobject -Property @{
                    Setting = $_."attribute" 
                    Value = $_."currentvalue"}
                }| select-object Setting, Value 
            }
            default{"Unknown $Type"}
            }
    }
    end{
    
    $Get_BIOS_Settings | Out-GridView -Title "Current BIOS configuration"
    $Get_BIOS_Settings | export-csv -NoTypeInformation -Path "$PSScriptRoot\$Model.csv"
    
    }
}



function BiosSet{
    
    $query = Read-Host "Commit BIOS Configuration?"
    switch($query){
    'y'{
        #Condition if yes.
        switch($Global:Result){
            {$_ -in 0   }{"Password not detected."}
            {$_ -in 1..2}{"Password Detected."

            #For loop was going to be implemented in this area for multiple clients, currently tailored for a client with lenovo machines.
        
            #BIOS password is defined here, pretty insecure I know.
            $Password = 'abc123'}
            #This condition is reached when multiple passwords are issued to a single model. Will revise in the future...probably.    
            #default{"Assigned Multiple Passwords" ; pause; $Trigger = 1}
        }
            Write-Output $Model
            pause
            #Define approved machine configs here.
            $ApprovedMods = @(
            # Configs Similar to 20JNS14P2M
            "20JNS14P2M"
            "20F5S1G10L" 
            "20K5S16A0Y"
            "20HD000WUS"
            "20FES14500"
            "20JJS1KA0V" # No USB Provisioning on this one.
            #eo similar configs 
            "20QQS0YQ58"
            "20ELS0CG00"
            #Configs similar to 20NKS0HP02
            "20NMS0C900"
            "20NKS0HP02"
            #ThinkStation
            "30CY0014US"
            #Another client
            "10GSS2RP00"
            )
            #If the machine exists in the previous array, configure the machine, otherwise state that it's not found.
            switch($Model){            

            {$_ -in $ApprovedMods}{$CSV_File = "$PSscriptroot\Configs\$_.csv"; $_ | Out-File -FilePath $PSScriptRoot\$_.txt -Encoding utf8 -Force -Append}

            default{"No configuration detected for this computer."; $Trigger = 1}
            }
            if(!$Trigger){
                if($Model){"Configuration Detected. Loaded model $_"| Out-File -FilePath $Psscriptroot\$_ -Encoding utf8 -Force -Append}
                if($CSV_File){$Get_CSV_Content = import-csv $CSV_File
                    $Count =$null

                    $BIOS = Get-wmiObject -class Lenovo_SetBiosSetting -namespace root\wmi 
                    ForEach($Settings in $Get_CSV_Content){
                        $MySetting = $Settings.Setting
                        $NewValue = $Settings.Value


                        if($Password){$ConfigText = "$MySetting,$NewValue,$Password,ascii,us"}
                        else{$ConfigText =  "$MySetting,$NewValue"}

                        $val = $BIOS.SetBiosSetting($ConfigText)
                        write-output "Changed $MySetting : $Results $($val.return)" | Out-File -FilePath $PSScriptRoot\$Type.txt -Encoding utf8 -Force -Append

                        switch($val.return){'Success'{$Count++}}
                    }

                $Save_BIOS = (Get-WmiObject -class Lenovo_SaveBiosSettings -namespace root\wmi)
                $Save_BIOS.SaveBiosSettings("$Password,ascii,us")
                Write-Output "Completed Operations $($Count)/$($Get_CSV_Content.Length)"
                BiosParse
                pause
                }
            }else{"unable to configure."}

        }
        default{
            #Condition if no.
            "Whoops not here"; pause
            exit
        }

    }

}

#Execution occurs here.
Clear-Host
BiosParse
BiosSet
pause