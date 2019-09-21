<#
 
   .oooooo.              ooooooooo.    .oooooo..o 
  d8P'  `Y8b             `888   `Y88. d8P'    `Y8 
 888            .ooooo.   888   .d88' Y88bo.      
 888           d88' `88b  888ooo88P'   `"Y8888o.  
 888     ooooo 888   888  888              `"Y88b 
 `88.    .88'  888   888  888         oo     .d8P 
  `Y8bood8P'   `Y8bod8P' o888o        8""88888P'  
                                                  
                                                  
                                                  
 
#>
<# 
.Description 
  Jump and easily manage a database file of jump paths. 
#>

param (
    # This is the default navigation file path to be used in every function. Default: $HOME/.navdb
    $DefaultPath = "$HOME/.navdb"
)

#region Internal ---------------------------------------------------------------
<#
 
   _       _                        _ 
  (_)_ __ | |_ ___ _ __ _ __   __ _| |
  | | '_ \| __/ _ \ '__| '_ \ / _` | |
  | | | | | ||  __/ |  | | | | (_| | |
  |_|_| |_|\__\___|_|  |_| |_|\__,_|_|
                                      
 
#>


function Invoke-Unless { 
    <#
    .Description
      A ruby-like function.
      It is the inverse of if.
      bool -> scriptblock -> unit 
    #>

    [Alias('unless')]
    
    param (
        # A conditional expression.
        $c,

        # A scriptblock to invoke if condition is False.
        $sb
    )

    if (-not $c) {
        & $sb 
    } 
}


function Assert-Path ($s) {
    <#
    .Description
      Halt on Test-Path failure.
      Takes a filepath.
      string -> unit
    #> 

    unless (Test-Path $s) {
        throw ($Messages.TerminatingError.NavFileInvalid -f $s)
    }

    $true
}


function Test-String ($s) {
    <#
    .Synopsis
      Tests if a string is null or empty. 
    .Description
      True if a string is something.
      False if a string is nothing.
      string -> bool
    #>

    -not (
        [string]::IsNullOrEmpty($s) -or
        [string]::IsNullOrWhiteSpace($s)
    )
}


filter Skip-NullObject {
    <#
    .Description
      Only pass an object if one of its properties has a value.
      obj? -> obj
    #>

    foreach ($p in $_.PSObject.Properties.Value) {
        if (Test-String $p) {
            return $_
        }
    }
}

function New-ShortcutObject ($JumpPath, $Token) {
    <#
    .Description
      Creates a new shortcut object for ease of database read & write.
      obj -> obj -> obj
    #>

    [PSCustomObject]@{
        PSTypeName = 'GoPS.Shortcut'
        JumpPath   = $JumpPath
        Token      = $Token
    }
}


function Group-PSItem {
    <#
    .Description
      Collect pipeline objects into an array.
      obj -> obj[]
    #>

    @($input)

    # $ls = New-Object System.Collections.ArrayList 

    # foreach ($obj in $input) {
    #     [void] $ls.Add($obj)
    # }

    # $ls.ToArray()
}


function Export-ObjectTo ($s) {
    <#
    .Description
      Adds an object to a database file.
      obj -> string -> unit 
    #>

    $input | Export-Csv -Path $s -NoTypeInformation                  
} 


function New-Database {
    <#
    .Description
      Create a new database list.
      unit -> unit
    #>

    $script:Database = New-Object System.Collections.ArrayList
}


function Update-Database ($s = $DefaultPath) {
    <#
    .Description
      Update the database list with the file contents.
      unit -> unit
    #>
 
    if (Test-Path $s) { 
        $script:Database = @(Import-Csv $s) -as [System.Collections.ArrayList]
        # New-Database

        # [void] $script:Database.AddRange(@(Import-Csv $s))
    }
}


function Add-EntryToDatabase ($x) {
    <#
    .Description
      Add an entry to the database list.
      obj -> unit
    #>

    [void] $script:Database.Add($x)
}

#endregion

#region Startup ---------------------------------------------------------------------------------------------------
<#

       _             _               
   ___| |_ __ _ _ __| |_ _   _ _ __  
  / __| __/ _` | '__| __| | | | '_ \ 
  \__ \ || (_| | |  | |_| |_| | |_) |
  |___/\__\__,_|_|   \__|\__,_| .__/ 
                              |_|    
 
#>

# Import localization strings based on UICulture
$Import = @{
    BindingVariable = 'Messages'
    BaseDirectory   = $PSScriptRoot
    FileName        = 'GoPS.Resources.psd1'
}

try {
    Import-LocalizedData @Import -ErrorAction Stop
}
catch {
    Import-LocalizedData @Import -UICulture en-US -ErrorAction Stop 
}

Update-Database

#endregion

#region Get-DefaultNavigationFile ---------------------------------------------------------------------------------
<#
 
    ____      _        ____        __             _ _         
   / ___| ___| |_     |  _ \  ___ / _| __ _ _   _| | |_       
  | |  _ / _ \ __|____| | | |/ _ \ |_ / _` | | | | | __|      
  | |_| |  __/ ||_____| |_| |  __/  _| (_| | |_| | | |_ _ _ _ 
   \____|\___|\__|    |____/ \___|_|  \__,_|\__,_|_|\__(_|_|_)
                                                              
 
#>

function Get-DefaultNavigationFile {
    <#
    .Description
      Returns the default path of the navigation file currently set.
      unit -> PathInfo
    #>

    Resolve-Path $script:DefaultPath
}

#endregion

#region Set-DefaultNavigationFile ---------------------------------------------------------------------------------
<#
 
   ____       _        ____        __             _ _         
  / ___|  ___| |_     |  _ \  ___ / _| __ _ _   _| | |_       
  \___ \ / _ \ __|____| | | |/ _ \ |_ / _` | | | | | __|      
   ___) |  __/ ||_____| |_| |  __/  _| (_| | |_| | | |_ _ _ _ 
  |____/ \___|\__|    |____/ \___|_|  \__,_|\__,_|_|\__(_|_|_)
                                                              
 
#>

function Set-DefaultNavigationFile {
    <#
    .Synopsis
      Sets the default navigation file path.
    .Description
      Sets the default navigation file path for GoPS.
      The default path is set on module load.
      If no parameter is sent on module load, default path defaults to .navdb in the user's home path.
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param (
        # Specifies a path to database file.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)] 
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $DefaultPath
    )
    
    end {
        if ($PSCmdlet.ShouldProcess($Path, $Messages.ShouldProcess.SetDefaultNavigationFile)) {
            $script:DefaultPath = $Path 
        }

        Update-Database $Path
    }
}

#endregion

#region New-NavigationFile ----------------------------------------------------------------------------------------
<#
 
   _   _                    _   _             _             _   _             _____ _ _      
  | \ | | _____      __    | \ | | __ ___   _(_) __ _  __ _| |_(_) ___  _ __ |  ___(_) | ___ 
  |  \| |/ _ \ \ /\ / /____|  \| |/ _` \ \ / / |/ _` |/ _` | __| |/ _ \| '_ \| |_  | | |/ _ \
  | |\  |  __/\ V  V /_____| |\  | (_| |\ V /| | (_| | (_| | |_| | (_) | | | |  _| | | |  __/
  |_| \_|\___| \_/\_/      |_| \_|\__,_| \_/ |_|\__, |\__,_|\__|_|\___/|_| |_|_|   |_|_|\___|
                                                |___/                                        
 
#>

function New-NavigationFile {
    <#
    .Synopsis
      Creates a new navigation database file.
    .Description
      Creates a blank entry and exports to a CSV file. 
      Will not overwrite an existing file unless the -Force parameter is passed.
    .Example
      PS> New-NavigationFile -Path [FilePath]
        Creates a new file at the given FilePath if it does not already exist.
    .Example
      PS> New-NavigationFile -Path [FilePath] -Force
        Wipes the file at the Path and creates a new blank database. 
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies a path to database file. Default: $HOME/.navdb
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $DefaultPath,

        # Forces creation of a new file.
        [switch] $Force
    )
    
    $NoClobber = !$Force

    if ($PSCmdlet.ShouldProcess($Path, $Messages.ShouldProcess.NewNavigationFile)) {
        New-ShortcutObject | 
            Export-Csv -Path $Path -NoClobber:$NoClobber -NoTypeInformation

        Update-Database $Path
    }
}

#endregion

#region Add-NavigationEnty ----------------------------------------------------------------------------------------
<#
 
      _       _     _       _   _             _             _   _             _____       _         
     / \   __| | __| |     | \ | | __ ___   _(_) __ _  __ _| |_(_) ___  _ __ | ____|_ __ | |_ _   _ 
    / _ \ / _` |/ _` |_____|  \| |/ _` \ \ / / |/ _` |/ _` | __| |/ _ \| '_ \|  _| | '_ \| __| | | |
   / ___ \ (_| | (_| |_____| |\  | (_| |\ V /| | (_| | (_| | |_| | (_) | | | | |___| | | | |_| |_| |
  /_/   \_\__,_|\__,_|     |_| \_|\__,_| \_/ |_|\__, |\__,_|\__|_|\___/|_| |_|_____|_| |_|\__|\__, |
                                                |___/                                         |___/ 
 
#>

function Add-NavigationEnty {
    <#
    .Synopsis
      Adds a navigation shortcut to the database file.
    .Description
      This cmdlet will add a token or shortcut and its corresponding jump path to the database.
      Duplicate tokens are not allowed, but multiple tokens may map to the same jump path.
      Jump paths do not have to exist, and Add-NavigationEntry will warn the user if one does not.
      By using the -Validate switch, a user can prevent an invalid jump path from being added.

      AddGo is a convenience alias.
    .Example
      PS> Add-NavigationEntry -Token Home -JumpPath $Home
       Adds a map of the token home to the fullpath of the $HOME variable.
    .Example
      PS> Add-NavigationEntry here
       Adds a map of the token here to the current working directory.
    .Example
      PS> Add-NavigationEntry -Token NotYet -JumpPath 'does not exist' -Validate
       Exits early because the jump path is invalid.
    .Example
      PS> AddGo token [resolvablePath]
       Demonstrating most common usage. 
    #>

    [Alias('AddGo')]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies a path to database file.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $DefaultPath,

        # Jump Path.
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [string] $JumpPath = $pwd,

        # Shortcut to use.
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Shortcut')]
        [string] $Token,

        # Validate the Jump Path.
        [switch] $Validate,

        # Pass the database object through.
        [switch] $PassThru
    )

    process {
        $isJumpPath = Test-Path $JumpPath

        unless ($isJumpPath) {
            Write-Warning ($Messages.Warning.BadJumpPath -f $JumpPath) 
        }

        if ($Validate -and -not $isJumpPath) {
            Write-Verbose ($Messages.Verbose.BadJumpPathValidated -f $JumpPath)

            return
        }

        if ($null -ne $Database) {
            $isDuplicateToken = $Database.Token.Contains($Token)

            if ($isDuplicateToken) {
                Write-Error ($Messages.TerminatingError.AddNavTokenDuplicate -f $Token) -ErrorAction Stop
            }
        } 

        # Xeq 
        $newShortCut = New-ShortcutObject $JumpPath $Token
        $shouldProcessMessage = $Messages.ShouldProcess.AddNavigationEntry -f $Token, $Path

        if ($PSCmdlet.ShouldProcess($Path, $shouldProcessMessage)) {
            Add-EntryToDatabase $newShortCut

            $Database.ToArray() |
                Skip-NullObject |
                Group-PSItem |
                Export-ObjectTo $Path 
        } 

        if ($PassThru) {
            $newShortCut 
        } 
    }
}


#endregion

#region Get-NavigationEntry ---------------------------------------------------------------------------------------
<#
 
    ____      _        _   _             _             _   _             _____       _              
   / ___| ___| |_     | \ | | __ ___   _(_) __ _  __ _| |_(_) ___  _ __ | ____|_ __ | |_ _ __ _   _ 
  | |  _ / _ \ __|____|  \| |/ _` \ \ / / |/ _` |/ _` | __| |/ _ \| '_ \|  _| | '_ \| __| '__| | | |
  | |_| |  __/ ||_____| |\  | (_| |\ V /| | (_| | (_| | |_| | (_) | | | | |___| | | | |_| |  | |_| |
   \____|\___|\__|    |_| \_|\__,_| \_/ |_|\__, |\__,_|\__|_|\___/|_| |_|_____|_| |_|\__|_|   \__, |
                                           |___/                                              |___/ 
 
#>

function Get-NavigationEntry {
    <#
    .Synopsis
      Returns navigation entries in the database.
    .Description
      Searches and returns objects that match the passed tokens.
      If no arguments are passed, Get-NavigationEntry will list all tokens.
      Wildcards are accepted.
    .Example
      PS> GetGo [token1 token2 token...]
       Most common usage.
    .Example
      PS> Get-NavigationEntry -Path [path] -Token doc* -JumpPathOnly
       Returns only the paths for objects in the path file that match doc*.
    #>

    [Alias('GetGo')]
    [CmdletBinding()]
    param (
        # Specifies a path to database file.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $DefaultPath,

        # The tokens to fetch from the database.
        [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments, ValueFromPipelineByPropertyName)]
        [string[]] $Token = '*',

        # Returns the jump path only.
        [Alias('PathOnly', 'ValueOnly')]
        [switch] $JumpPathOnly
    )
    
    begin { 
        $dbContent = 
            if ($PSBoundParameters.ContainsKey('Path')) {
                @(Import-Csv -Path $Path)
            }
            else {
                $Database | Skip-NullObject
            }
        $getToken = {
            $s = $_ + '*'
            $dbContent.Where{ $_.Token -like $s }
        }
        $out = {
            if ($JumpPathOnly) {
                $_.JumpPath
            }
            else {
                $_
            } 
        }
    }
    
    process {
        $Token.Foreach($getToken).Foreach($out)
    }
}

#endregion

#region Remove-NavigationEntry -----------------------------------------------------------------------------------
<#
 
   ____                                     _   _             _             _   _                   
  |  _ \ ___ _ __ ___   _____   _____      | \ | | __ ___   _(_) __ _  __ _| |_(_) ___  _ __        
  | |_) / _ \ '_ ` _ \ / _ \ \ / / _ \_____|  \| |/ _` \ \ / / |/ _` |/ _` | __| |/ _ \| '_ \       
  |  _ <  __/ | | | | | (_) \ V /  __/_____| |\  | (_| |\ V /| | (_| | (_| | |_| | (_) | | | |_ _ _ 
  |_| \_\___|_| |_| |_|\___/ \_/ \___|     |_| \_|\__,_| \_/ |_|\__, |\__,_|\__|_|\___/|_| |_(_|_|_)
                                                                |___/                               
 
#>

function Remove-NavigationEntry {
    <#
    .Synopsis
      Removes entry from navigation database.
    .Description
      Can accept piped input from Get-NavigationEntry.
      Removes objects from navigation database that match incoming tokens.
    .Example
      PS> RmGo Home
       Most common usage.
    #>

    [Alias('RmGo')]
    [CmdletBinding(SupportsShouldProcess)]
    param (
       # Specifies a path to database file.
       [Parameter(ValueFromPipelineByPropertyName)]
       [ValidateScript({ Assert-Path $_ })]
       [string] $Path = $DefaultPath,

       # The tokens to remove from the database.
       [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments, ValueFromPipelineByPropertyName)]
       [string[]] $Token 
    )
    
    begin {
        $dbContent = Import-Csv -Path $Path 
        $getRemainingToken = {
            $s = $_ + '*'
            $dbContent.Where{ $_.Token -notlike $s }
        }
        $getTargets = {
            $s = $_ + '*'
            $dbContent.Where{ $_.Token -like $s }
        } 
    }
    
    process {
        $targets = $Token.Foreach($getTargets)

        if ($PSCmdlet.ShouldProcess($targets, $Messages.ShouldProcess.RemoveNavigationEntry)) {
            $Token |
                ForEach-Object $getRemainingToken |
                Group-PSItem |
                Export-ObjectTo $Path
        } 
    }
    
    end {
        Update-Database $Path
    }
}


#endregion

#region Invoke-GoPS -----------------------------------------------------------------------------------------------
<#
 
   ___                 _               ____       ____  ____  
  |_ _|_ ____   _____ | | _____       / ___| ___ |  _ \/ ___| 
   | || '_ \ \ / / _ \| |/ / _ \_____| |  _ / _ \| |_) \___ \ 
   | || | | \ V / (_) |   <  __/_____| |_| | (_) |  __/ ___) |
  |___|_| |_|\_/ \___/|_|\_\___|      \____|\___/|_|   |____/ 
                                                              
 
#>

function Invoke-GoPS {
    <#
    .Synopsis
      Jumps to a token.
    .Description
      Searches the database at path for a matching token.
      Then, Invoke-GoPS will test the jump path and 
    .Example
      PS> Example Code
       Description of Example
    #>
    [Alias('Go')]
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [Alias('Token')]
        [string] $Path,

        # Database file to load info from.
        [Parameter()]
        [ValidateScript({ Assert-Path $_ })]
        [string] $DatabasePath = $DefaultPath,

        # If a previous location is available on the stack, goes back one location.
        [switch] $Back,
        
        # If back is indicated, will try to go back into the stack at this depth.
        [int] $BackDepth = 1
    )

    begin { 
        $dbContent = 
            if ($PSBoundParameters.ContainsKey('DatabasePath')) {
                Import-Csv -Path $DatabasePath 
            }
            else {
                $Database 
            } 
        $stackCount = (Get-Location -Stack).Count
        

        function Jump ($s) {
            if (Test-Path $s) {
                Push-Location $s
            }
            else {
                Write-Warning ($Messages.Warning.BadJumpPath -f $s)
            }
        }
    }

    end {
        if ($Back -and ($BackDepth -le $stackCount)) {

            do {
                Pop-Location
                $BackDepth--
            } until ($BackDepth -eq 0) 

            return
        }

        if ($Back -and ($BackDepth -gt $stackCount)) {
            Write-Error ($Messages.TerminatingError.StackDepthExceeded -f $BackDepth) -ErrorAction Stop
        }

        $jp = $dbContent.Where{ $Path -like $_.Token }.JumpPath

        if ($null -ne $jp) {
            Jump $jp
        }
        elseif (!$Path) {
            Push-Location $pwd 
        }
        else {
            Jump $Path
        }
    }
}


function Invoke-Back {
    <#
    .Synopsis
      Go back n times in the directory stack.
    #>

    [Alias('Back')]

    param (
        [int] $n = 1 
    )

    Invoke-GoPS -Back -BackDepth $n
}

#endregion

$tokenCompletions = {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-NavigationEntry | 
        Where-Object Token -like "$wordToComplete*" | 
        ForEach-Object { 
            New-Object System.Management.Automation.CompletionResult @(
                $_.Token
                $_.Token
                'ParameterValue'
                $_.Token 
            ) 
        }
}

Register-ArgumentCompleter -CommandName Invoke-GoPS -ParameterName Path -ScriptBlock $tokenCompletions
Register-ArgumentCompleter -CommandName Remove-NavigationEntry -ParameterName Token -ScriptBlock $tokenCompletions
Register-ArgumentCompleter -CommandName Get-NavigationEntry -ParameterName Token -ScriptBlock $tokenCompletions

<#
 
   _____                       _   
  | ____|_  ___ __   ___  _ __| |_ 
  |  _| \ \/ / '_ \ / _ \| '__| __|
  | |___ >  <| |_) | (_) | |  | |_ 
  |_____/_/\_\ .__/ \___/|_|   \__|
             |_|                   
 
#>

$Functions = @(
    'Get-DefaultNavigationFile'
    'Set-DefaultNavigationFile'
    'New-NavigationFile'
    'Add-NavigationEnty'
    'Get-NavigationEntry'
    'Remove-NavigationEntry'
    'Invoke-GoPS'
    'Invoke-Back'
)

$Aliases = @(
    'AddGo'
    'GetGo'
    'RmGo'
    'Go'
    'Back'
)


Export-ModuleMember -Function $Functions -Alias $Aliases
