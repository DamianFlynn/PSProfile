## GLOBAL VARIABLES ############################################################

$ProfilePath = $PROFILE.Substring(0,$PROFILE.IndexOf('\Microsoft.'))
if (! ( [Environment]::GetEnvironmentVariable("PSModulePath", "User") ) ) {
   [Environment]::SetEnvironmentVariable("PSModulePath", $ProfilePath + "\Modules", "User")
}

$ProfileSettingsPath = $PROFILE.Substring(0,$PROFILE.IndexOf('\Microsoft.')) + "\settings"
$ProfileTranscriptsPath = $PROFILE.Substring(0,$PROFILE.IndexOf('\Microsoft.')) + "\transcripts"

## CREDENTIALS ################################################################

function Load-myCredentials {
	#Enable Profile Settings Folder

	if (!(test-path $ProfileSettingsPath)) {
		write-output ("Create folders to store settings to")
		mkdir $ProfileSettingsPath | out-null
	}

	If (!(test-path $ProfileSettingsPath\ps_creds_O365.xml)) {
		write-output "Please provide your Office 365 Credentials"
		Get-Credential dpfadmin@lionbridge.onmicrosoft.com | Export-Clixml $ProfileSettingsPath\ps_creds_O365.xml
	}
	$CredsXML = Import-Clixml $ProfileSettingsPath\ps_creds_O365.xml
	$global:MSOLCreds = new-object -typename System.Management.Automation.PSCredential -argumentlist $CredsXML.UserName,$CredsXML.Password


	If (!(test-path $ProfileSettingsPath\ps_creds_OnPrem.xml)) {
		Write-Output "Please provide your On-Premise Administrator Credentials"
		Get-Credential dpfadmin@lionbridge.com | Export-Clixml $ProfileSettingsPath\ps_creds_OnPrem.xml
	}
	$CredsXML = Import-Clixml $ProfileSettingsPath\ps_creds_OnPrem.xml
	$global:OnPremCreds = new-object -typename System.Management.Automation.PSCredential -argumentlist $CredsXML.UserName,$CredsXML.Password
}

## HISTORY ####################################################################

Function Load-myHistory {
	Register-EngineEvent PowerShell.Exiting -Action { Get-History | Export-Clixml $ProfileSettingsPath\.ps_history } | out-null
	if (Test-path $ProfileSettingsPath\.ps_history) { Import-Clixml $ProfileSettingsPath\.ps_history | Add-History }
}

## TRANSCRIPTS ################################################################

function Save-Transcript {
	if (!(test-path $ProfileTranscriptsPath)) {
		write-output ("Create folders to store transcripts to")
		mkdir $ProfileTranscriptsPath | out-null
	}

	$global:TRANSCRIPT = "$ProfileTranscriptsPath\PSLOG_{0:dd-MM-yyyy}.txt" -f (Get-Date)
	Start-Transcript -Append
}

## MODULES ####################################################################



function Install-MSOnlineModules {

    # Check if the Modules are Currently Installed
    $Installed = Get-WmiObject -class Win32_Product | sort-object name | select name, version, vendor

    # Microsoft Online Services (Sign-In Assistant)
    if ($Installed.Name -notcontains "Microsoft Online Services Sign-in Assistant") {

        #  Not Installed - Check we have the Installers Locally..
        $DownloadUrl = "http://download.microsoft.com/download/5/0/1/5017D39B-8E29-48C8-91A8-8D0E4968E6D4/en/msoidcli_64.msi"
        $destination = "$($env:Home)\Documents\WindowsPowerShell\Installs\MSOnline"

        if (!(Test-Path "$destination\msoidcli_64.msi")) {
            #  Not Currently Local - Download the modules
            Write-Output "Downloading: Microsoft Online Services Module"
            if (!(Test-Path "$destination")) {mkdir $destination }
            Start-BitsTransfer -Source $DownloadUrl -Description "Microsoft Online services" -Destination $destination -DisplayName "Microsoft Online Services"
        }
        Write-Output "Installing: Microsoft Online Services Module"

        Start-Process -Wait -FilePath msiexec.exe -ArgumentList "/i $destination\$(Split-Path $DownloadUrl -Leaf) /quiet /passive"
    }

    # Azure Active Directory
    if ($Installed.Name -notcontains "Windows Azure Active Directory Module for Windows PowerShell") {

        #  Not Installed - Check we have the Installers Locally..
        $DownloadUrl = "http://go.microsoft.com/fwlink/p/?linkid=236297"
        $destination = "$($env:Home)\Documents\WindowsPowerShell\Installs\AzureAD"

        if (!(Test-Path "$destination\AdministrationConfig-en.msi")) {
            #  Not Currently Local - Download the modules
            Write-Output "Downloading: Windows Azure Active Directory Module"
            if (!(Test-Path "$destination")) {mkdir $destination }
            Start-BitsTransfer -Source $DownloadUrl -Description "Microsoft Online services" -Destination $destination -DisplayName "Windows Azure Active Directory"
        }
        Write-Output "Installing: Windows Azure Active Directory Module"
        Start-Process -Wait -FilePath msiexec.exe -ArgumentList "/i $destination\$(Split-Path $DownloadUrl -Leaf) /quiet /passive"
    }


    # Azure PowerShell
    if ($Installed.Name -notcontains "*Microsoft Azure PowerShell*" ) {

        #  Not Installed - Check we have the Installers Locally..
        $DownloadURL = 'https://github.com/Azure/azure-powershell/releases/download/0.9.4-June2015/azure-powershell.0.9.4.msi'
        $destination = "$($env:Home)\Documents\WindowsPowerShell\Installs\Azure"

        if (!(Test-Path "$destination\azure-powershell.0.9.4.msi")) {
            #  Not Currently Local - Download the modules
            Write-Output "Downloading: Windows Azure PowerShell Module"
            if (!(Test-Path "$destination")) {mkdir $destination }
            Start-BitsTransfer -Source $DownloadURL -Description "Windows Azure Powershell" -Destination $destination -DisplayName "Windows Azure PowerShell"
        }
        Write-Output "Installing: Windows Azure PowerShell Module"
        Start-Process -Wait -FilePath msiexec.exe -ArgumentList "/i $destination\$(Split-Path $DownloadUrl -Leaf) /quiet /passive"
    }

}

## SUPPORT FUNCTIONS ##########################################################

function Check-LocalVersion
{
    $gitLocalRev = git rev-parse HEAD
    $gitLocalBranch = (git symbolic-ref -q HEAD).Replace("refs/heads/","")
    $gitRemoteRev = git rev-parse --verify --quite "@{upstream}"
    $gitDifferences = git rev-list --left-right "@{upstream}"...HEAD

    Write-Host ("Running $($GitStatus.Branch) branch")
}

function elevate-process
{
	$file, [string]$arguments = $args;
	$psi = new-object System.Diagnostics.ProcessStartInfo $file;
	$psi.Arguments = $arguments;
	$psi.Verb = "runas";
	$psi.WorkingDirectory = get-location;
	[System.Diagnostics.Process]::Start($psi);
}

function Set-WindowWidth([int]$preferredWidth)
{
	if ($host.name -eq "ConsoleHost") {
		[int]$maxAllowedWindowWidth = $host.ui.rawui.MaxPhysicalWindowSize.Width
		if ($preferredWidth -lt $maxAllowedWindowWidth)
		{
			# first, buffer size has to be set to windowsize or more
			# this operation does not usually fail
			$current=$host.ui.rawui.BufferSize
			$bufferWidth = $current.width
			if ($bufferWidth -lt $preferredWidth)
			{
				$current.width=$preferredWidth
				$host.ui.rawui.BufferSize=$current
			}


			# setting window size. As we are well within max limit, it won't throw exception.
			$current=$host.ui.rawui.WindowSize
			if ($current.width -lt $preferredWidth)
			{
				$current.width=$preferredWidth
				$host.ui.rawui.WindowSize=$current
			}
		}
		$host.ui.rawui.BufferSize.Height = 5000
		$host.ui.rawui.BackgroundColor = "Black"
		clear-host
	}

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

## REMOTE POWERSHELL SESSIONS #################################################

Function Connect-PSSession {
	param (
		[string]$ServerList,
		[string]$PSURI,
		[String]$ConfigurationName
	)

	process {
		$ServerList = ( $ServerList ).Split(",;")
		For ( $i = 0 ; -not $ServerSession -and $i -lt $ServerList.Count ; $i++ )
		{
			$targetServer = $ServerList[$i]
			write-verbose ("Attempting to connect to server $targetServer");
			$ServerSession = New-PSSession  -ConnectionURI     "http://$targetServer/$PSURI" `
										-ConfigurationName $ConfigurationName `
										-ErrorAction       Continue
		}
		If ( -not $ServerSession ) {
			throw "Could not connect a new PSSession to any $PSURI servers."
		} else {
			#  Importing PSSession with Exchange server to use Exchange server commands
			$Import = Import-PSSession -Session $ServerSession -AllowClobber -Verbose:$False
		}

		return $Import
	}
}

$ExchangeServerList = "bil-exc10-02.corpnet.liox.org;bil-exc10-03.corpnet.liox.org"
$SkypeServerList = "bil-exc10-02.corpnet.liox.org;bil-exc10-03.corpnet.liox.org"

#Import-Module ActiveDirectory
#
#Connect-PSSession -ServerList $SkypeServerList -PSURI "OcsPowershell/" -ConfigurationName "Microsoft.Lync"
#Connect-PSSession -ServerList $ExchangeServerList -PSURI "powershell/" -ConfigurationName "Microsoft.Exchange" -verbose
#Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "Computer1,Computer2"

## AZURE CONNECTIONS ##########################################################

Function Connect-MSOL
{
    Try
    {
        Connect-MsolService -Credential $global:MSOLCreds
    }
    Catch
    {
        Write-Host "Couldn't connect to Azure AD. Please speak to your Administrator." -ForegroundColor Red
    }
}

Function Connect-EOL
{
	$global:SessionEOL = New-PSSession -ConfigurationName Microsoft.Exchange `
							 -ConnectionUri "https://outlook.office365.com/powershell-liveid/" `
							 -Credential $MSOLCreds `
							 -Authentication Basic `
							 -AllowRedirection

    Import-PSSession $SessionEOL –AllowClobber

	Register-EngineEvent PowerShell.Exiting -Action { Remove-PSSession $SessionEOL } | out-null

	return $SessionEOL
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

## SET SOME ALIASES ##########################################################

set-Alias npp          "C:\Program Files (x86)\Notepad++\notepad++.exe"
set-alias edit-profile "npp $profile"
set-alias sudo         elevate-process


## DEFINE PROMPT #############################################################

function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE

	if ($GitPromptSettings) {
		# Reset color, which can be messed up by Enable-GitColors
		$Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor
	}

    Write-Host($pwd.ProviderPath) -nonewline

	if ($GitPromptSettings) {
		Write-VcsStatus
	}

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
}

## ENVIRONMENT MODULES ########################################################

Set-WindowWidth -preferredWidth 150
Load-myCredentials
Load-myHistory
Save-Transcript

## DEFINE PROMPT #############################################################

import-module posh-git
import-module posh-gitdir
Enable-GitColors

function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE

	if ($GitPromptSettings) {
		# Reset color, which can be messed up by Enable-GitColors
		$Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor
		$GitPromptSettings.AfterBackgroundColor  = [ConsoleColor]::Black
		$GitPromptSettings.DelimBackgroundColor    = [ConsoleColor]::Black
		$GitPromptSettings.UntrackedBackgroundColor   = [ConsoleColor]::Black
		$GitPromptSettings.BranchAheadBackgroundColor   = [ConsoleColor]::Black
		$GitPromptSettings.BranchBackgroundColor   = [ConsoleColor]::Black
		$GitPromptSettings.BranchBehindAndAheadBackgroundColor   = [ConsoleColor]::Black
		$GitPromptSettings.WorkingBackgroundColor   = [ConsoleColor]::Black
		$GitPromptSettings.BranchBehindBackgroundColor   = [ConsoleColor]::Black
		$GitPromptSettings.BeforeBackgroundColor    = [ConsoleColor]::Black
		$GitPromptSettings.IndexBackgroundColor    = [ConsoleColor]::Black
		$GitPromptSettings.BeforeIndexBackgroundColor   = [ConsoleColor]::Black
	}

    Write-Host($pwd.ProviderPath) -nonewline

	if ($GitPromptSettings) {
		Write-VcsStatus
	}

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
}



## DISPLAY BANNER ############################################################

cd ~
Display-Banner
$hostname = Hostname
$consoleInfo = "PowerShell " + $PSVersionTable.PSVersion + " hosted on " + $hostName + ", running Windows Build " + $PSVersionTable.BuildVersion + " using CLR " + $PSVersionTable.CLRVersion
Write-ColorOutput -Message $consoleInfo -ForegroundColor Yellow
write-output " "
