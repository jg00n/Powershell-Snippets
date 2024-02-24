<# Client_Name_1 Check & Apply Name + Apply License Key + Join Domain Script
Written by: Jonathan Goon 
Last Revision Date: 2/21/2019
REDACTED VERSION FOR PRIVACY PURPOSES (8/21/2019)
VERSION 1.1.0
#>

#Elevates Script before continuing
 if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit } 

# Define Variables

$LicenseKey = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
$hostname = hostname
$serialnumber = (gwmi win32_bios).SerialNumber
$DomainName = 'server01.abc'
$DomainUser = "$DomainName\admin.abc" 
$DomainPass = 'ABC123' | ConvertTo-SecureString -asPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential($DomainUser,$DomainPass)
$Automation = 0

# A bunch of autotext variables.
$PromptAuto = "Do you wish to run this operation in full sequence (Change Name, Join Domain, Apply SerialNumber)?"
$PromptName = "Renaming the computer $hostname to SerialNumber $serialnumber, do you wish to continue?"
$PromptKey = "Setting License Key as $($LicenseKey ), do you wish to continue?"
$PromptDomain = "Joining Domain at  $($DomainName ), do you wish to continue?"
$Go = ' Proceed to next step.'

#Automation Checkpoint
function ifAuto ( [String]$userprompt) {
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
#Checks Name  if equal to serialnumber, if not, prompts for application.
function NameCheck {
Write-Host "The computer name is $hostname"
Write-Host "The Serial Number is $serialnumber"
    if ($hostname -ne $serialnumber){

    #Go to Automation Check.
    $confirm2 = ifAuto [String]$PromptName

        if($confirm2 -eq 'y') {
        Write-Host 'Applying Changes'
        Rename-Computer -NewName $serialnumber
        if ($Automation -eq 1){
            Write-Host $Go
            ApplyRestart
            }
        }
        if($confirm2 -eq 'n') {exit}     
    }else{
    Write-Host 'Name is already set to serial number, Proceeding to next step.'
    if ($Automation -eq 1){ApplyKey}
    }
}
# Applies License Key
function ApplyKey {
    #Go to Automation Check
    $confirm3 = ifAuto [String]$PromptKey

            if($confirm3 -eq 'y') {
            Write-Host 'Applying Changes'
            slmgr -ipk $LicenseKey
            if ($Automation -eq 1){
                Write-Host $Go
                JoinDomain
                }
            }
        if($confirm3 -eq 'n') {exit}
 }
 # Join Domain
  function JoinDomain{
  $DomainCurrent = (Get-WmiObject -Class Win32_ComputerSystem).Domain
  if  ($DomainName -ne $DomainCurrent){
    #Go to Automation Check
    $confirm4 = ifAuto [String]$PromptDomain

            if($confirm4 -eq 'y') {
            Write-Host 'Applying Changes'
            Add-Computer -DomainName $DomainName -Credential $Credentials
            if ($Automation -eq 1){
                Write-Host $Go
                ApplyRestart
                }
            }
        if($confirm4 -eq 'n') {exit}
      }
else{
      Write-Host "Computer already exists on $DomainName "
      }
}
#Restarts Machine.
function ApplyRestart{
Write-Host ' Restarting this machine to reflect changes.'
shutdown -r -t 10
pause
}
# Menu for manual or automatic application.
function FullSequence{
$confirm1 = Read-Host "$PromptAuto"
while ('y','n' -notcontains $confirm1){
$confirm1 = Read-Host "$PromptAuto"
        }
        #Go to first step
    if ($confirm1 -eq 'y'){ 
    $Automation = 1
     NameCheck
    }
    #Go to Manual Options
    if ($confirm1 -eq 'n'){
        do{
        cls
        Write-Host "Here are the following options that you can choose from: `n Change Name [1] `n Change Key [2] `n Change Domain[3]"
        $selectionQuery = Read-Host "Please enter a number to make your selection, or press q to terminate"
            switch ($selectionQuery){
                '1'{ Write-Host 'Option 1 has been selected (Apply Name)'
                pause
                cls
                NameCheck
                }'2'{ Write-Host 'Option 2 has been selected (Apply Key)'
                pause
                cls
                ApplyKey
                }'3'{ Write-Host 'Option 3 has been selected (Join Domain)'
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
cls
FullSequence