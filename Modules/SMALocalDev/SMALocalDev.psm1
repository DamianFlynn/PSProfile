$Script:LocalSMAVariableLastUpdate = @{}
$Script:LocalSMAVariables = @{}
$Script:SessionCredentials = @{}
$env:LocalSMAVariableWarn = Select-FirstValid -Value $env:LocalSMAVariableWarn, $true -FilterScript { $_ -ne $null }

<#
.SYNOPSIS
    Gets the most recent list item in a SharePoint list whose name contains
    $ListNameLike.

.PARAMETER ListNameLike
    A fragment of the list name to query. If no lists match this name (or multiple lists do)
    an exception will be thrown.

.PARAMETER SPFarm
    The SharePoint farm to query. Defaults to 'd.solutions.generalmills.com'.

.PARAMETER SPSite
    The SharePoint site to query. Defaults to  'gcloud'.

.PARAMETER UseSsl
    Whether or not to use SSL when querying SharePoint. Defaults to false.
#>
function Get-MostRecentSPListItem
{
    param(
        [Parameter(Mandatory=$True)]  [String] $ListNameLike,
        [Parameter(Mandatory=$False)] [String] $SPFarm = 'd.solutions.generalmills.com',
        [Parameter(Mandatory=$False)] [String] $SPSite = 'gcloud',
        [Parameter(Mandatory=$False)] [Switch] $UseSsl = $False
    )
    $Lists = (Get-SPList -SPFarm $SPFarm -SPSite $SPSite -UseSSl:$UseSsl | Where-Object { $_ -like "$ListNameLike" })
    if(@($Lists).Count -gt 1)
    {
        throw "Found too many lists like ${ListNameLike}: $($Lists -join ', ')"
    }
    elseif(@($Lists).Count -eq 0)
    {
        throw "No lists found with names like $ListNameLike."
    }
    $ListName = @($Lists)[0]
    Write-Verbose -Message "Determined SharePoint list name $ListName"
    $Item = (Get-SPListItem -SPFarm $SPFarm -SPSite $SPSite -SPList $ListName -UseSsl:$UseSsl)[-1]
    if(-not $Item)
    {
        throw "Could not find any list items in $ListName"
    }
    Write-Verbose -Message "Got list item $($Item.Id)"
    return $Item
}

<#
.SYNOPSIS
    Returns a scriptblock that, when dot-sourced, will import a workflow and all its dependencies.

.DESCRIPTION
    Import-Workflow is a helper function to resolve dependencies of a given workflow. It must be
    invoked with a very specific syntax in order to import workflows into your current session.
    See the example.

    Import-Workflow only considers scripts whose full paths contain '\Dev\' in accordance with
    GMI convention. See Find-DeclaredCommand to modify this behavior if it is undesired.

.PARAMETER WorkflowName
    The name of the workflow to import.

.PARAMETER Path
    The path containing all ps1 files to search for workflow dependencies.

.EXAMPLE
    PS > . (Import-Workflow Test-Workflow)
#>
function Import-Workflow {
    param(
        [Parameter(Mandatory=$True)]  [String] $WorkflowName,
        [Parameter(Mandatory=$False)] [String] $Path = $env:SMARunbookPath
    )

    # TODO: Make $CompileStack a more appropriate data structure.
    # We're not really using the stack functionality at all. In fact,
    # it was buggy. :-(
    $CompileStack = New-Object -TypeName 'System.Collections.Stack'
    $TokenizeStack = New-Object -TypeName 'System.Collections.Stack'
    $DeclaredCommands = Find-DeclaredCommand -Path $Path
    $BaseWorkflowPath = $DeclaredCommands[$WorkflowName]
    $Stacked = @{$BaseWorkflowPath = $True}
    $TokenizeStack.Push($BaseWorkflowPath)
    $CompileStack.Push($BaseWorkflowPath)
    while ($TokenizeStack.Count -gt 0) {
        $ScriptPath = $TokenizeStack.Pop()
        $Tokens = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $ScriptPath), [ref] $null)
        $NeededCommands = ($Tokens | Where-Object -FilterScript { $_.Type -eq 'Command' }).Content
        foreach ($Command in $NeededCommands) {
            $NeededScriptPath = $DeclaredCommands[$Command]
            # If $NeededScriptPath is $null, we didn't find it when we searched declared
            # commands in the runbook path. We'll assume that is okay and that the command
            # is provided by some other means (e.g. a module import)
            if (($NeededScriptPath -ne $null) -and (-not $Stacked[$NeededScriptPath])) {
                $TokenizeStack.Push($NeededScriptPath)
                $CompileStack.Push($NeededScriptPath)
                $Stacked[$NeededScriptPath] = $True
            }
        }
    }
    $WorkflowDefinitions = ($CompileStack | foreach { (Get-Content -Path $_) }) -join "`n"
    $ScriptBlock = [ScriptBlock]::Create($WorkflowDefinitions)
    return $ScriptBlock
}

<#
.SYNOPSIS
    Returns a dictionary mapping the name of a PowerShell command to the file containing its
    definition.

.DESCRIPTION
    Find-DeclaredCommand searches $Path for .ps1 files. Each .ps1 is tokenized in order to
    determine what functions and workflows are defined in it. This information is used to
    return a dictionary mapping the command name to the file in which it is defined.

    Find-DeclaredCommand only considers scripts whose full paths contain '\Dev\' in accordance
    with GMI convention.

.PARAMETER Path
    The path to search for command definitions.
#>
function Find-DeclaredCommand
{
    param(
        [Parameter(Mandatory=$True)] [String] $Path,
        [Parameter(Mandatory=$False)] [AllowNull()] [String] $Branch = $null
    )

    $RunbookPaths = Get-BranchFile -Path $Path -Include '*.ps1' -Branch (Get-WorkingBranch -Branch $Branch)
    $DeclaredCommandMap = @{}
    foreach ($Path in $RunbookPaths) {
        $Tokens = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $Path), [ref] $null)
        $PreviousCommand = $null
        $DeclaredCommands = ($Tokens | Where-Object -FilterScript {
            ($_.Type -eq 'CommandArgument') -and ($PreviousCommand.Content -in ('function', 'workflow'))
            $PreviousCommand = $_
        }).Content
        foreach ($DeclaredCommand in $DeclaredCommands) {
            Write-Debug -Message "Found command $DeclaredCommand in $Path"
            $DeclaredCommandMap[$DeclaredCommand] = $Path
        }
    }
    return $DeclaredCommandMap
}

<#
.SYNOPSIS
    Returns a list of files which are part of a "development" branch in version control.

.PARAMETER Path
    The path to search for files.

.PARAMETER Include
    Gets only the specified items. See the help of Get-ChildItem's Include parameter for
    more information. 
#>
function Get-BranchFile
{
    param(
        [Parameter(Mandatory=$True)]  [String] $Path,
        [Parameter(Mandatory=$True)]  [String[]] $Include = '*',
        [Parameter(Mandatory=$False)] [String] $Branch,
        [Parameter(Mandatory=$False)] [System.DateTime] $ChangedSince = 0
    )

    return (Get-ChildItem -Path $Path -Include $Include -Recurse |
        Where-Object { ($_.FullName -like "*\$Branch\*") -and ($_.LastWriteTime -gt $ChangedSince) }).FullName
}

function Get-WorkingBranch
{
    param([Parameter(Mandatory=$False)] [AllowNull()] [String] $Branch = $null)
    return Select-FirstValid -Value $Branch, $env:LocalSMABranch, 'Dev'
}

<#
.SYNOPSIS
    Returns the named automation variable, referencing local XML files to find values.

.PARAMETER Name
    The name of the variable to retrieve.
#>
Function Get-AutomationVariable
{
    Param(
        [Parameter(Mandatory=$True)]  [String] $Name,
        [Parameter(Mandatory=$False)] [String] [AllowNull()] $Branch = $null
    )

    $LocalSMAVariableWarn = ConvertTo-Boolean -InputString (Select-FirstValid -Value $env:LocalSMAVariableWarn, 'True' -FilterScript { $_ -ne $null })
    # Check to see if local variables are overridden in the environment - if so, pull directly from SMA.
    if(($env:AutomationVariableEndpoint -ne $null) -and ($env:AutomationVariableEndpoint -notin (Get-LocalAutomationVariableEndpoint)))
    {
        if($LocalSMAVariableWarn)
        {
            Write-Warning -Message "Getting variable [$Name] from endpoint [$env:AutomationVariableEndpoint]"
        }
        # FIXME: Don't hardcode credential name.
        $Var = Get-SMAVariable -Name $Name -WebServiceEndpoint $env:AutomationVariableEndpoint -Credential (Get-SessionCredential -Name 'GENMILLS\M3IS052')
        return $Var
    }

    $Branch = Get-WorkingBranch -Branch $Branch
    if($LocalSMAVariableWarn)
    {
        Write-Warning -Message "Getting variable [$Name] from local XML (branch $Branch)"
    }
    If(Test-UpdateLocalAutomationVariable -Branch $Branch)
    {
        Update-LocalAutomationVariable -Branch $Branch
    }
    If(-not $Script:LocalSMAVariables[$Branch].ContainsKey($Name))
    {
        Write-Warning -Message "Couldn't find variable $Name in branch $Branch" -WarningAction 'Continue'
        Write-Warning -Message 'Do you need to update your local variables? Try running Update-LocalAutomationVariable.'
        Write-Warning -Message 'Are you in the right branch? Try modifying $env:LocalSMABranch.' -WarningAction 'Continue'
        Throw-Exception -Type 'VariableDoesNotExist' -Message "Couldn't find variable $Name in branch $Branch" -Property @{
            'Variable' = $Name;
            'Branch' = $Branch;
        }
    }
    Return $Script:LocalSMAVariables[$Branch][$Name]
}

function Test-UpdateLocalAutomationVariable
{
    param([Parameter(Mandatory=$True)] [String] $Branch)

    $UpdateInterval = Select-FirstValid -Value ([Math]::Abs($env:LocalSMAVariableUpdateInterval)), 10 `
                                        -FilterScript { $_ -ne $null }
    if($Script:LocalSMAVariables[$Branch] -eq $null)
    {
        return $True
    }
    elseif($UpdateInterval -eq 0)
    {
        return $False
    }
    elseif((Get-Date).AddSeconds(-1 * $UpdateInterval) -gt $Script:LocalSMAVariableLastUpdate[$Branch])
    {
        return $True
    }
    return $False
}

function Update-LocalAutomationVariable
{
    param([Parameter(Mandatory=$False)] [String] $Branch = $null)

    $Branch = Get-WorkingBranch -Branch $Branch
    Write-Verbose -Message "Updating SMA variables for branch $Branch"
    $Script:LocalSMAVariableLastUpdate[$Branch] = Get-Date
    $FilesToProcess = Get-BranchFile -Path $env:SMARunbookPath -Include '*.xml' -Branch $Branch
    Process-SmaXml -Path $FilesToProcess -Branch $Branch
}

<#
.SYNOPSIS
    Processes an XML file, caching any variables it finds.

.PARAMETER Path
    The XML files that should be processed.
#>
Function Process-SmaXml
{
    Param(
        [Parameter(Mandatory=$True)]  [AllowNull()] [String[]] $Path,
        [Parameter(Mandatory=$False)] [AllowNull()] [String]   $Branch = $null
    )
    $TypeMap = @{
        'String'  = [String];
        'Str'     = [String];
        'Integer' = [Int];
        'Int'     = [Int]
    }
    $Branch = Get-WorkingBranch -Branch $Branch
    $Script:LocalSMAVariables[$Branch] = @{}
    ForEach($_Path in $Path)
    {
        Try
        {
            $xml = [XML] (Get-Content -Path $_Path)
        }
        Catch
        {
            Write-Warning -Message "Could not process [$_Path] - variables from that file will not be available" -WarningAction 'Continue'
            Write-Warning -Message "Does [$_Path] contain malformed XML?" -WarningAction 'Continue'
            Write-Exception -Exception $_ -Stream 'Warning'
        }
        ForEach($Variable in $xml.Root.Variables.Variable)
        {
            $VarType = Select-FirstValid -Value $TypeMap[$Variable.Type], $([String])
            $Var = New-Object -TypeName 'PSObject' -Property @{ 'Name' = $Variable.Name; 'Value' = ($Variable.Value -As $VarType)}
            $Script:LocalSMAVariables[$Branch][$Var.Name] = $Var
        }
    }
}

function Get-SessionCredential
{
    param([Parameter(Mandatory=$True)] [String] $Name)

    if(-not $Script:SessionCredentials[$Name])
    {
        $Script:SessionCredentials[$Name] = Get-AutomationPSCredential -Name $Name
    }
    return $Script:SessionCredentials[$Name]
}

function Get-XidEidRequest
{
    param([Parameter(Mandatory=$True)] [String] $AccountRequestGuid)

    $Cred = Get-SessionCredential -Name (Get-AutomationVariable -Name 'XID_EIDRequests-CredName' -Branch 'Release').Value
    $ConnectionString = (Get-AutomationVariable -Name 'XID_EIDRequests-DEXTERNAL_ID_CREATOR-ConnectionString' -Branch 'Release').Value
    $Results = Invoke-Command -ComputerName 'localhost' -Credential $Cred -Authentication 'CredSSP' `
                              -ArgumentList $AccountRequestGuid, $ConnectionString -ScriptBlock {
        $AccountRequestGuid, $ConnectionString = $Args
        Invoke-SqlQuery -query 'SELECT * FROM TACCOUNT_REQUEST WHERE account_request_guid = @AccountRequestGuid' `
                        -parameters @{'@AccountRequestGuid' = $AccountRequestGuid} `
                        -connectionString $ConnectionString
    }
    return $Results
}

#region Code from EmulatedAutomationActivities
workflow Get-AutomationPSCredential {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Name
    )

    $Val = Get-AutomationAsset -Type PSCredential -Name $Name

    if($Val) {
        $SecurePassword = $Val.Password | ConvertTo-SecureString -asPlainText -Force
        $Cred = New-Object -TypeName System.Management.Automation.PSCredential($Val.Username, $SecurePassword)

        $Cred
    }
}
#endregion