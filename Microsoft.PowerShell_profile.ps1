## GLOBAL VARIABLES ############################################################

$ProfilePath = $PROFILE.Substring(0,$PROFILE.IndexOf('\Microsoft.'))
if (! ( [Environment]::GetEnvironmentVariable("PSModulePath", "User") ) ) {
   [Environment]::SetEnvironmentVariable("PSModulePath", $ProfilePath + "\Modules", "User")
}

$ProfileSettingsPath = $PROFILE.Substring(0,$PROFILE.IndexOf('\Microsoft.')) + "\settings"
$ProfileTranscriptsPath = $PROFILE.Substring(0,$PROFILE.IndexOf('\Microsoft.')) + "\transcripts"


## MODULES ####################################################################



## SUPPORT FUNCTIONS ##########################################################


function elevate-process
{
	$file, [string]$arguments = $args;
	$psi = new-object System.Diagnostics.ProcessStartInfo $file;
	$psi.Arguments = $arguments;
	$psi.Verb = "runas";
	$psi.WorkingDirectory = get-location;
	[System.Diagnostics.Process]::Start($psi);
}

function Write-ColorOutput
{
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
	clear-host
	write-output "  "
	write-output "   ██╗ ██╗ ██████╗  █████╗ ███╗   ███╗██╗ █████╗ ███╗   ██╗        ███████╗██╗  ██╗   ██╗███╗   ██╗███╗   ██╗"
	write-output "  ████████╗██╔══██╗██╔══██╗████╗ ████║██║██╔══██╗████╗  ██║        ██╔════╝██║  ╚██╗ ██╔╝████╗  ██║████╗  ██║"
	write-output "  ╚██╔═██╔╝██║  ██║███████║██╔████╔██║██║███████║██╔██╗ ██║        █████╗  ██║   ╚████╔╝ ██╔██╗ ██║██╔██╗ ██║"
	write-output "  ████████╗██║  ██║██╔══██║██║╚██╔╝██║██║██╔══██║██║╚██╗██║        ██╔══╝  ██║    ╚██╔╝  ██║╚██╗██║██║╚██╗██║"
	write-output "  ╚██╔═██╔╝██████╔╝██║  ██║██║ ╚═╝ ██║██║██║  ██║██║ ╚████║███████╗██║     ███████╗██║   ██║ ╚████║██║ ╚████║"
	write-output "   ╚═╝ ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝     ╚══════╝╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═══╝"
	write-output "  "
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


Register-PSPackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

## DEFINE PROMPT #############################################################

function Import-PSModule {
    param(
        [string]$Name,
        [string]$Version
    )

    $module = Get-Module -ListAvailable -Name $Name 
    if ($module) {
        Write-Host "Module $Name exists"
        if ($module.name -eq "pester" -and $module.Version.ToString() -lt $Version)
        {
            $pester = "c:\Program Files\WindowsPowerShell\Modules\Pester"
            takeown /F $pester /A /R
            icacls $pester /reset
            icacls $pester /grant Administrators:'F' /inheritance:d /T
            Remove-Item -Path $pester -Recurse -Force -Confirm:$false
            Install-Module -name pester -MinimumVersion $Version
        }
        import-module -name $Name
    } 
    else {
        Write-Host "Module $Name does not exist, Installing.."
        if ($Version)
        {
            Install-Module -Name $Name -MinimumVersion $version -Force -Confirm:$False
        } else {
            Install-Module -Name $Name -Force -Confirm:$False
        }
    }
}

import-psmodule -name posh-git
Import-psModule -Name Get-ChildItemColor
Import-psModule -Name oh-my-posh
Import-PSModule -Name pester -Version "4.3.0"
Import-PSModule -Name az ## the asSK module is not yet compatiable [https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps?view=azps-1.3.0]
#Import-PSModule -Name azSK
Import-Module -Name az.Blueprint

Set-Theme agnoster

## SET SOME ALIASES ##########################################################

set-alias edit-profile "code $profile"
set-alias sudo         elevate-process
#Set-Alias l Get-ChildItemColor -Option AllScope
#Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope

## DISPLAY BANNER ############################################################

git config --global user.name "Damian Flynn"
git config --global user.email info@damianflynn.com

#cd ~
Display-Banner
$hostname = Hostname
$time = Get-Date

$consoleInfo = "PowerShell " + $PSVersionTable.PSVersion + " hosted on " + $hostName + ", running Windows Build " + $PSVersionTable.BuildVersion + " using CLR " + $PSVersionTable.CLRVersion
Write-ColorOutput -Message $consoleInfo -ForegroundColor Yellow
Write-Host "Session Started on $($time.ToLongDateString()) " -foregroundColor Yellow -NoNewLine
Write-Host "$([char]9829) " -foregroundColor Red

write-output " "
