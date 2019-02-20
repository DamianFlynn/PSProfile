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
    param([string]$Name)

    if (Get-Module -ListAvailable -Name $Name) {
        Write-Host "Module $Name exists"
        import-module -name $Name
    } 
    else {
        Write-Host "Module $Name does not exist, Installing.."
        Install-Module -Name $Name -Force -Confirm:$False
    }
}

Import-PSModule -name posh-git
Import-PSModule -Name Get-ChildItemColor
Import-PSModule -Name oh-my-posh

Set-Theme agnoster

## SET SOME ALIASES ##########################################################

set-alias edit-profile "code $profile"
set-alias sudo         elevate-process
#Set-Alias l Get-ChildItemColor -Option AllScope
#Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope

## DISPLAY BANNER ############################################################

git config --global user.name "Damian Flynn"
git config --global user.email info@damianflynn.com

cd ~
Display-Banner
$hostname = Hostname
$time = Get-Date

$consoleInfo = "PowerShell " + $PSVersionTable.PSVersion + " hosted on " + $hostName + ", running Windows Build " + $PSVersionTable.BuildVersion + " using CLR " + $PSVersionTable.CLRVersion
Write-ColorOutput -Message $consoleInfo -ForegroundColor Yellow
Write-Host "Session Started on $($time.ToLongDateString()) " -foregroundColor Yellow -NoNewLine
Write-Host "$([char]9829) " -foregroundColor Red

write-output " "
