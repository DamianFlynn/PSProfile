## SUPPORT FUNCTIONS ##########################################################

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
}

## DEFINE PROMPT #############################################################

Set-Theme agnoster

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
