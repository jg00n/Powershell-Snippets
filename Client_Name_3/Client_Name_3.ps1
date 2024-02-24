clear-host
<# Client_Name_3 Domain Check + End Users
Written by: Jonathan Goon
REDACTED VERSION FOR CLIENT CONFIDENTIALITY (8/21/2019)
Last Revision Date: 6/29/2019
VERSION 1.2.0
#>
#region Variable Definitions

#Elevates Script before continuing
 if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
  
#region GenericVariables

$LicenseKey = ''
$hostname = hostname
$serialnumber = (gwmi win32_bios).SerialNumber
$Automation = 0
$Debug = 0
#endregion GenericVariables
#region SpecificVariables

#Machine Variable Assignments

#region Nested Region SN_Var
$Global:Order = $null
$Global:Name_PC = $null
$Global:Name_User = $null
$Global:TimeZ = $null
$Global:Serial = New-Object System.Collections.Generic.List[System.Object]
#endregion Nested Region SN_Var
#region Nested Region CSV_Var
    $CSV_Order = @{}
    $CSV_Serial = @{}
    $CSV_PC = @{} 
    $CSV_User = @{}
    $CSV_Time = @{}
    #endregion Nested Region CSV_Var

function Variable_UserCheck{

$CurrentLocation = Split-Path -Parent $PSCommandPath
$filePath ="$CurrentLocation\Client_3_User_Variables.csv"
    if(test-path $filePath){
    $csv = Import-Csv $filePath 
        ForEach($item in $csv){
        $CSV_Order.add($item.SerialNumber, $item.OrderNumber)
        $CSV_PC.add($item.SerialNumber, $item.ComputerName)
        $CSV_User.add($item.SerialNumber, $item.UserName)
        $CSV_Time.add($item.SerialNumber, $item.Timezone)
        $Global:Serial.add($item.SerialNumber)
        }
    }else{Error_Text $filePath 1}
}

#Populate array with CSV data
function Variable_CSVPop{
Variable_UserCheck
        
        if($Global:Serial -contains $serialnumber){ 
        $Global:Order = $CSV_Order[$serialnumber]
        $Global:Name_PC = $CSV_PC[$serialnumber]
        $Global:Name_User = $CSV_User[$serialnumber]
        $Global:TimeZ = $CSV_Time[$serialnumber]
            if($debug -eq 1){
            Error_Text "" 100
            write-host $serialnumber
            }
        }else{Error_Text $serialnumber 3}

}
#endregion SpecificVariables
#region DomainVariables

$DomainName = 'BigCompany.BigCity.com'
$DomainCurrent = (Get-WmiObject -Class Win32_ComputerSystem).Domain

#endregion DomainVariables
#region Credentials
$DomainUser_Unsec = "administrator"
$DomainUser = [string]"$DomainName\$($DomainUser_Unsec)"
$DomainPass_Unsec = 'password'
$DomainPass = $DomainPass_Unsec | ConvertTo-SecureString -asPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential($DomainUser,$DomainPass)

#endregion Credentials
#region Prompts

$PromptAuto = "Type 'y' to run this script automatically, type 'n' for more options."
$PromptName = "Renaming the computer $hostname to $Global:Name_PC, do you wish to continue?"
$PromptDomain = "Joining Domain at  $($DomainName), do you wish to continue?"
$Go = ' Proceed to next step.'

#endregion Prompts
#endregion Variable Definitions
#region Main

#region General_Functions

#Automation Checkpoint
function Query_Auto ( [String]$userprompt) {
#Check if the automation checkpoint has been triggered.
 switch($Automation){
    0{$userselect = Read-Host "$userprompt"}
    1{$userselect ='y'}
    }
    # If automation checkpoint has NOT been triggered, prompt user until 'y' or 'n' has been entered.
     while('y','n' -notcontains $userselect){
     $userselect = Read-Host "$userprompt"
}
return $userselect
}

function Error_Text([string]$ErrorMessage, $ErrorType){
switch($ErrorType){
    #Error Codes
    0{White-host "Unspecified Error" -Foregroundcolor Red -BackgroundColor White}
    1{Write-host "file $($ErrorMessage) not found.)" -ForegroundColor Red -BackgroundColor White}
    2{Write-Host "Deployment Logs not found." -ForegroundColor Red -BackgroundColor White}
    3{Write-Host "Serialnumber $($ErrorMessage) not discovered in CSV sheet."-ForegroundColor Red -BackgroundColor White}
    4{Write-Host "Path $($ErrorMessage) not found." -ForegroundColor Red -BackgroundColor White}
    5{Write-Host "PC Name $($ErrorMessage) is incorrect. Machine is already enrolled to the domain. Unable to process changes." -ForegroundColor Red -BackgroundColor Yellow}
    10{Write-Host "Please verify that you have a connection to $($ErrorMessage)"-ForegroundColor Red -BackgroundColor Yellow}
    11{Write-Host "There is no connection between $($ErrorMessage) and $DomainName" -ForegroundColor Red -BackgroundColor Yellow}
    #General Messages
    50{Write-Host "File $($ErrorMessage) Discovered." -ForegroundColor Yellow -BackgroundColor DarkCyan}
    51{Write-Host "Network Location $($ErrorMessage) Discovered"-ForegroundColor Yellow -BackgroundColor DarkCyan}
    52{Write-Host "Deployment Logs at $($ErrorMessage) Discovered...`nReading Contents..." -ForegroundColor Yellow -BackgroundColor DarkCyan}
    53{Write-Host "Timezone is currently set to $($ErrorMessage). Setting timezone to $($Global:TimeZ)" -ForegroundColor Yellow -BackgroundColor DarkCyan}
    54{Write-Host "Timezone is now set to $($ErrorMessage)." -ForegroundColor Yellow -BackgroundColor DarkCyan}
    55{Write-Host "Injecting Domain Users into Local Groups!" -ForegroundColor Yellow -BackgroundColor DarkCyan}
    60{Write-Host "Name ($($ErrorMessage)) matches value on file, Proceeding to next step.'" -ForegroundColor Yellow -BackgroundColor DarkCyan}
    61{Write-Host "Process is complete!" -ForegroundColor Yellow -BackgroundColor DarkCyan}
    62{Write-Host "Computer is already joined to $($ErrorMessage)!" -ForegroundColor Yellow -BackgroundColor DarkCyan}
    63{Write-Host "Computer Description is already set to $($Global:Name_User)!" -ForegroundColor Yellow -BackgroundColor DarkCyan}
    64{Write-Host "Setting Computer Description as $($Global:Name_User)!" -ForegroundColor Yellow -BackgroundColor DarkCyan}
    65{} 
    66{White-Host "$($hostname) will be changed to $($Global:Name_PC)!" -ForegroundColor Yellow -BackgroundColor DarkCyan}
    67{Write-Host "$($hostname) has sucessfully connected to $($DomainName)!" -ForegroundColor Yellow -BackgroundColor DarkCyan}
    68{}
    69{}
    70{Write-Host "Configuration is complete!" -ForegroundColor Yellow -BackgroundColor DarkCyan} 
    #Developer Messages
    98{Write-Host "DEBUG MODE ENABLED" -ForegroundColor Red -BackgroundColor Yellow}
    99{Write-Host "DEBUG MODE ENABLED, SKIPPING $($ErrorMessage)" -ForegroundColor Red -BackgroundColor Yellow
    pause}
    100{Write-Host "Global Variable Result: `n Order#:$($Global:Order) `n PC Name:$($Global:Name_PC) `n Username $($Global:Name_User) `n Timezone $($Global:TimeZ) `n"}
    101{Write-Host "END OF SEQUENCE" -ForegroundColor Red -BackgroundColor Yellow}
    }
    if($ErrorType -le 9){
    write-host "Aborting Config Operation!" -ForegroundColor Red -BackgroundColor White
    pause
    exit
    }
    if($ErrorType -In 66..69){ApplyRestart}
    if($ErrorType -In 98..110){pause}
}

#Restarts Machine.
function ApplyRestart{
Write-Host 'Restarting this machine to reflect changes.' -ForegroundColor Yellow -BackgroundColor DarkCyan
shutdown -r -t 10
pause
}
#endregion General_Functions
#region DisplayInformation

#Displays General Information of Machine
function Display_Name {
Write-Host " Computer Name: $hostname `n"
Write-Host " Domain: $DomainCurrent `n"
pause
}

function Display_Log{

Push-Location C:\

$DeployLogLocation = "\Windows\Temp\DeploymentLogs\Results.xml"
$DeployLogCheck = Test-Path -Path $DeployLogLocation
    if ($DeployLogCheck -eq $true){
    Error_Text $DeployLogLocation 52
    Get-Content $DeployLogLocation
    pause
    }else{
    Error_Text $DeployLogLocation 2
    pause
    #exit
    }
Pop-Location
}

#endregion DisplayInformation
#region PC_ID assign

function Name_Check_PC {
    Write-Host "Current Computer Name: $hostname"
    Write-Host "Computer Name on file: $Global:Name_PC"
        if ($hostname -ne $Global:Name_PC){
            #Go to Automation Check.
            $confirm2 = ifAuto [String]$PromptName
            if((gwmi win32_computersystem).partofdomain -eq $false){
                if($confirm2 -eq 'y'){
                    switch ($Debug){
                    '0'{ Write-Host 'Applying Changes'
                        Rename-Computer -NewName $Global:Name_PC
                        #Restart Checkpoint
                        if ($Automation -eq 1){Error_Text "" 66}
                        else{Error_Text ""61}}
                    '1'{Error_Text "RENAME" 99}  
                    }
                }
            elseif($confirm2 -eq 'n') {exit}     
            }else{Error_Text $hostname 5}
    }else{Error_Text $hostname 60}
}

function Name_Check_Desc{
$Name_Desc =Get-WmiObject -class Win32_OperatingSystem
    if($Name_Desc.Description -ne $Global:Name_User){
    Error_Text "" 64
    $Name_Desc.Description = $Global:Name_User
    $Name_Desc.put()
    Error_Text "" 61
    }else{Error_Text "" 63}

}

function Time_Set{
$Zone_Def = $null
$Zone_Cur = Get-TimeZone
    switch($Global:TimeZ){
        'EST'{$Zone_Def = "Eastern Standard Time"}
        'CST'{$Zone_Def = "Central Standard Time"}
        'MST'{$Zone_Def = "Mountain Standard Time"}
        'PST'{$Zone_Def = "Pacific Standard Time"}
        'HST'{$Zone_Def = "Hawaiian Standard Time"}
    }
   if($Zone_Cur -ne $Zone_Def){
   Error_Text $Zone_Def 53
   Set-TimeZone -Name $Zone_Def
   Error_Text $Zone_Def 54
   }else{Error_Text "" 55}
}
#endregion PC_ID Assign
#region DomainSequence

 #Check if Domain is Live.
 function Domain_Check {
    $pingcheck = 0
    $ifDomain = 0
        do{
        if (Test-Connection -ComputerName $DomainName -Quiet -Count 1){
        Error_Text $DomainName 51
        $pingcheck =6
        $ifDomain = 1
        }
        else{
        Error_Text $hostname 11
        $pingcheck ++
        start-sleep -s 1
        }
     }while ( $pingcheck -le 5)
     if ($ifDomain -ne 1){Error_Text $DomainName 10}
        return $ifDomain
 }
 # Applies License Key
    function ApplyKey {
        slmgr-ato
  }
   # Join Domain
function Domain_Join{
if  ($DomainName -ne $DomainCurrent){
    #Go to Automation Check
    $confirm4 = Query_Auto [String]$PromptDomain
    $DomainConnect = Domain_Check
        if(($confirm4 -eq 'y') -and ($DomainConnect -eq 1)){
            switch($Debug)
            {
                '0'{Write-Host 'Applying Changes'
                    Add-Computer -DomainName $DomainName -Credential $Credentials
                    #Restart Checkpoint
                        if ($Automation -eq 1){Error_Text "" 67}
                        else{Error_Text "" 61}}
                '1'{Error_Text "DOMAIN JOIN" 99}
            }
        }
        elseif($DomainConnect -eq 0){
            $DomRecheck = Read-Host " Please press a key to attempt again, or type 'q' to quit."
            if ($DomRecheck -ne 'q'){Domain_Join}
            else{exit}
            }

      else{pause
      exit}
      }else{Error_Text $DomainName 62}

}
   
#endregion DomainSequence
#region Symantec
function Sym_Update{
Push-Location C:\
    $Sym_Path = "PROGRAM FILES (X86)\Symantec\Symantec Endpoint Protection"
    $Sym_File = "SepLiveUpdate.exe"
    $Sym_Full = "$($Sym_Path)\$($Sym_File)"
    $Sym_Test = test-path $Sym_Path
    if($Debug -eq 1){Get-Location}
    pause
    Push-Location "$Sym_Path"
        if($Sym_Test -match "True"){
        Error_Text $Sym_File 50
        Start-Process -FilePath $Sym_File      
        Pop-Location
    if($Debug -eq 1){Get-Location}
Error_Text "" 61
}else{Error_Text $Sym_Path 4}
Pop-Location
}


#endregion Symantec
#region AnyConnect

# Source www.cze.cz

# This script is tested with "Cisco AnyConnect Secure Mobility Client version 3.0.5080"

# Run using %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File "C:\CiscoVPNAutoLogin.ps1"



# VPN connection details
Function Any_Start{
[string]$CiscoVPNHost = "ravpn.PSAV.com"
[string]$vpncliAbsolutePath = 'C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe'
[string]$vpnuiAbsolutePath  = 'C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe'
#****************************************************************************

#**** Please do not modify code below unless you know what you are doing ****

#****************************************************************************

Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop

# Set foreground window function
# This function is called in VPNConnect
Add-Type @'
 
  using System;

  using System.Runtime.InteropServices;

  public class Win {

     [DllImport("user32.dll")]

     [return: MarshalAs(UnmanagedType.Bool)]

     public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
'@ -ErrorAction Stop

# quickly start VPN
# This function is called later in the code

Function VPNConnect{

    Start-Process -FilePath $vpncliAbsolutePath -ArgumentList "connect $CiscoVPNHost"

    $counter = 0; $h = 0;

    while($counter++ -lt 1000 -and $h -eq 0)

    {

        sleep -m 10

        $h = (Get-Process vpncli).MainWindowHandle

    }

    #if it takes more than 10 seconds then display message

    if($h -eq 0){echo "Could not start VPNUI it takes too long."}

    else{[void] [Win]::SetForegroundWindow($h)}

}

# Terminate all vpnui processes.
Get-Process | ForEach-Object {if($_.ProcessName.ToLower() -eq "vpnui")
{$Id = $_.Id; Stop-Process $Id; echo "Process vpnui with id: $Id was stopped"}}
# Terminate all vpncli processes.
Get-Process | ForEach-Object {if($_.ProcessName.ToLower() -eq "vpncli")
{$Id = $_.Id; Stop-Process $Id; echo "Process vpncli with id: $Id was stopped"}}
# Disconnect from VPN
write-host "Trying to terminate remaining vpn connections"
start-Process -FilePath $vpncliAbsolutePath -ArgumentList 'disconnect' -wait
#Connect to VPN
write-host "Connecting to VPN address '$CiscoVPNHost' as user '$Login'."

VPNConnect
# Write login and password
[System.Windows.Forms.SendKeys]::SendWait("1{Enter}")
[System.Windows.Forms.SendKeys]::SendWait("$DomainUser_Unsec{Enter}")
[System.Windows.Forms.SendKeys]::SendWait("$DomainPass_Unsec{Enter}")
# Start vpnui
start-Process -FilePath $vpnuiAbsolutePath
# Wait for keydown
write-host "Press any key to continue ..."
try{$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")}catch{}
}
#endregion AnyConnect
#region LocalGroup
function GroupPop{
Error_Text "" 55
Add-LocalGroupMember -Group "Network Configuration Operators" -Member "BigCompany.BigCity.com\Domain Users", "International.BigCity.com\Domain Users"
Add-LocalGroupMember -Group "Power Users" -Member "BigCompany.BigCity.com\Domain Users", "International.BigCity.com\Domain Users"
Error_Text "" 61
gpupdate /force
}
#endregion LocalGroup
#region UserInterface


#Task Sequence
function TaskList{
Display_Name
Display_Log
Name_Check_PC
Name_Check_Desc
Domain_Join
Gpupdate /Force
Time_Set
Sym_Update
Any_Start
GroupPop

if($Debug -eq 0){Error_Text "" 70}
if($Debug -eq 1){Error_Text "" 101}
}

# Menu for manual or automatic application.
function FullSequence{

Variable_CSVPop
#Debug Prompt
if($Debug -eq 1){Error_Text "" 98
#Global Variable Test
Error_Text "" 100
}

#Automation Check
$confirm1 = Read-Host "$PromptAuto"
while ('y','n' -notcontains $confirm1){
$confirm1 = Read-Host "$PromptAuto"
        }
        #Go to Task Sequence
    if ($confirm1 -eq 'y'){ 
    $Automation = 1
     TaskList
    }
    #Go to Manual Options
    if ($confirm1 -eq 'n'){
        do{
        cls
        Write-Host "Here are the following options that you can choose from: `n View Info [1] `n Change Key [2] `n Set Domain[3]"
        $selectionQuery = Read-Host "Please enter a number to make your selection, or press q to terminate"
            switch ($selectionQuery){
                '1'{ Write-Host 'View Information'
                pause
                cls
                Display_Name
                Display_Log
                }'2'{ Write-Host ''
                pause
                cls
                #Not Implemented
                }'3'{ Write-Host 'Join Domain'
                pause
                cls
                JoinDomain
                }'q'{
                Write-Host 'Program will now terminate'
                pause
                exit}
            }
        pause
        }until ($selectionQuery -eq 'q')
    }
}
if ($debug -eq 0){cls}
FullSequence
#endregion UserInterface


#endregion Main
