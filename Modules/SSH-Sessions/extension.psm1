function ssh {
	param([Parameter(Mandatory=$true)][string] $ComputerName,
          [Parameter(Mandatory=$true)][string]   $User,
          [string] $Pass = 'Default'
    )
	
	New-SshSession -ComputerName $ComputerName -Username $User -Password $Pass
	Enter-SshSession -ComputerName $ComputerName
	Remove-SshSession -ComputerName $ComputerName
}