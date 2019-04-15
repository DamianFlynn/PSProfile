## GLOBAL VARIABLES ############################################################

$ProfilePath = $PROFILE.Substring(0, $PROFILE.IndexOf('\Microsoft.'))
if (! ( [Environment]::GetEnvironmentVariable("PSModulePath", "User") ) ) {
  [Environment]::SetEnvironmentVariable("PSModulePath", $ProfilePath + "\Modules", "User")
}

$ProfileSettingsPath = $PROFILE.Substring(0, $PROFILE.IndexOf('\Microsoft.')) + "\settings"
$ProfileTranscriptsPath = $PROFILE.Substring(0, $PROFILE.IndexOf('\Microsoft.')) + "\transcripts"


## MODULES ####################################################################



## SUPPORT FUNCTIONS ##########################################################


function elevate-process {
  $file, [string]$arguments = $args;
  $psi = New-Object System.Diagnostics.ProcessStartInfo $file;
  $psi.Arguments = $arguments;
  $psi.Verb = "runas";
  $psi.WorkingDirectory = Get-Location;
  [System.Diagnostics.Process]::Start($psi);
}

function Write-ColorOutput {
  param (
    [string]$message,
    [string]$ForegroundColor = $host.UI.RawUI.ForegroundColor
  )

  # save the current color
  $currentForegroundColor = $host.UI.RawUI.ForegroundColor

  # set the new color
  $host.UI.RawUI.ForegroundColor = $ForegroundColor

  Write-Output $message

  # restore the original color
  $host.UI.RawUI.ForegroundColor = $currentForegroundColor
}


function Display-Banner {
  Clear-Host
  Write-Output "  "
  Write-Output "   ██╗ ██╗ ██████╗  █████╗ ███╗   ███╗██╗ █████╗ ███╗   ██╗        ███████╗██╗  ██╗   ██╗███╗   ██╗███╗   ██╗"
  Write-Output "  ████████╗██╔══██╗██╔══██╗████╗ ████║██║██╔══██╗████╗  ██║        ██╔════╝██║  ╚██╗ ██╔╝████╗  ██║████╗  ██║"
  Write-Output "  ╚██╔═██╔╝██║  ██║███████║██╔████╔██║██║███████║██╔██╗ ██║        █████╗  ██║   ╚████╔╝ ██╔██╗ ██║██╔██╗ ██║"
  Write-Output "  ████████╗██║  ██║██╔══██║██║╚██╔╝██║██║██╔══██║██║╚██╗██║        ██╔══╝  ██║    ╚██╔╝  ██║╚██╗██║██║╚██╗██║"
  Write-Output "  ╚██╔═██╔╝██████╔╝██║  ██║██║ ╚═╝ ██║██║██║  ██║██║ ╚████║███████╗██║     ███████╗██║   ██║ ╚████║██║ ╚████║"
  Write-Output "   ╚═╝ ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝     ╚══════╝╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═══╝"
  Write-Output "  "
}


## REGISTER PROVIDERS #########################################################

Display-Banner

$consoleInfo = "Please Wait... Checking and Installing Modules and Providers"
Write-ColorOutput -Message $consoleInfo -ForegroundColor Yellow

function Register-PSPackageProvider {
  param(
    [string]$Name,
    [string]$MinimumVersion
  )

  if (Get-PackageProvider -ListAvailable -Name $Name) {
    $info = Get-PackageProvider -Name $Name
    Write-Host "Package Provider $Name, version $($info.version) registered"
  } 
  else {
    Write-Host "Package Provier $Name is not registered, Installing.."
    Install-PackageProvider -Name $Name -MinimumVersion $MinimumVersion -Force -Confirm:$False
  }
}

# Skipping as this will be refactored to use the same collection logic for speed
#Register-PSPackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

## DEFINE PROMPT #############################################################

$moduleList = Get-Module -ListAvailable

function Import-PSModule {
  param(
    [string]$Name,
    [string]$Version
  )

  ## Check if the named module is in the collection of installed modules
  $index = ([Collections.Generic.List[Object]]($moduleList)).FindIndex( { $args[0].Name -eq $name } )

  ## 
  if ($index -ne -1) {
    Write-Host "Module $Name exists"
    if ($module.name -eq "pester" -and $module.Version.ToString() -lt $Version) {
      $pester = "c:\Program Files\WindowsPowerShell\Modules\Pester"
      takeown.exe /F $pester /A /R
      icacls.exe $pester /reset
      icacls.exe $pester /grant Administrators:'F' /inheritance:d /T
      Remove-Item -Path $pester -Recurse -Force -Confirm:$false
      Install-Module -name pester -MinimumVersion $Version
    }
    Import-Module -name $Name
  } 
  else {
    If ($Host.Name -eq 'Visual Studio Code Host') {
      Write-Host "Module $Name does not exist, Installing.."
      if ($Version) {
        Install-Module -Name $Name -MinimumVersion $version -Force -Confirm:$False
      }
      else {
        Install-Module -Name $Name -Force -Confirm:$False
      }
    }
    else {
      Write-Host "Running Inside VSCode Skipping Module Installation"
    }
  }
}


import-psmodule -name posh-git
Import-psModule -Name Get-ChildItemColor
Import-psModule -Name oh-my-posh
Import-PSModule -Name pester -Version "4.3.0"
Import-PSModule -Name az 
## the asSK module is not yet compatiable [https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps?view=azps-1.3.0]
#Import-PSModule -Name azSK
#Import-Module -Name az.Blueprint


Set-Theme agnoster

## SET SOME ALIASES ##########################################################


Set-Alias sudo         elevate-process
#Set-Alias l Get-ChildItemColor -Option AllScope
#Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope

## DISPLAY BANNER ############################################################

git.exe config --global user.name "Damian Flynn"
git.exe config --global user.email info@damianflynn.com

#cd ~
Display-Banner
$hostname = HOSTNAME.EXE
$time = Get-Date

$consoleInfo = "PowerShell " + $PSVersionTable.PSVersion + " hosted on " + $hostName + ", running Windows Build " + $PSVersionTable.BuildVersion + " using CLR " + $PSVersionTable.CLRVersion
Write-ColorOutput -Message $consoleInfo -ForegroundColor Yellow
Write-Host "Session Started on $($time.ToLongDateString()) " -foregroundColor Yellow -NoNewLine
Write-Host "$([char]9829) " -foregroundColor Red

Write-Output " "
