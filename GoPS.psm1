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
    [ValidateScript({ (Test-Path $_) -or $( throw "${_}: not a valid nav file!" ) })]
    $DefaultPath = "$HOME/.navdb"
)


#region Shared ----------------------------------------------------------------------------------------------------
<#
 
       _                        _ 
   ___| |__   __ _ _ __ ___  __| |
  / __| '_ \ / _` | '__/ _ \/ _` |
  \__ \ | | | (_| | | |  __/ (_| |
  |___/_| |_|\__,_|_|  \___|\__,_|
                                  
 
#>

# Creates a new shortcut object for ease of database read & write.
# obj -> obj -> obj
function ShortcutObj ($JumpPath, $Token) {
    [pscustomobject] @{
        JumpPath = $JumpPath -as [System.String]
        Token = $Token -as [System.String]
    }
}


# Collect incoming objects.
# obj -> obj[]
function Collect {
    $x = [System.Collections.ArrayList]::new()

    foreach ($obj in $input) {
        [void] $x.Add($obj)
    }

    $x.ToArray()
}


# Add an object to our db.
# obj -> string -> unit
function ToNavDb ($s) {
    $input | Export-Csv -Path $s -NoTypeInformation                        
} 


# Create a new database list.
# unit -> unit
function NewDb {
    $script:Db = [System.Collections.ArrayList]::new()
}


# Update the database list with the file contents
# unit -> unit
function UpdateDb ($s = $DefaultPath) {
    if (Test-Path $s) { 
        $script:Db = [System.Collections.ArrayList]::new((Import-Csv $s))
    }
}


# Add an entry to the database list.
# obj -> unit
filter AddToDb {
    [void] $script:Db.Add($_)
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

Import-LocalizedData @Import -ErrorAction SilentlyContinue

# Fallback to en-US culture 
if (-not (Test-Path variable:\Messages)) {
    Import-LocalizedData @Import -UICulture en-US -ErrorAction Stop
}

UpdateDb

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
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies a path to database file. Default: $HOME/.navdb
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ (Test-Path $_) -or $( throw "${_}: not a valid nav file!" ) })]
        [string]
        $Path = $DefaultPath
    )
    
    end {
        if ($PSCmdlet.ShouldProcess($Path, 'Setting as default path for GoPs')) {
            $script:DefaultPath = $Path 
        }
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
        [ValidateScript({ (Test-Path $_) -or $( throw "${_}: not a valid nav file!" ) })]
        [string]
        $Path = $DefaultPath,

        # Forces creation of a new file.
        [switch]
        $Force
    )
    
    begin { 
        $noClobber = !$Force
        function NewNavFile { 
            NewDb 
            
            ShortCutObj |
                AddToDb |
                Collect |
                Export-Csv -Path $Path -NoTypeInformation -NoClobber:$noClobber 
        }
    }
    
    end {
        if ($PSCmdlet.ShouldProcess($Path, 'Creating new navigation database')) {
            NewNavFile
        }
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
        [ValidateScript({ (Test-Path $_) -or $( throw "${_}: not a valid nav file!" ) })]
        [string]
        $Path = $DefaultPath,

        # Jump Path.
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $JumpPath = $pwd,

        # Shortcut to use.
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Shortcut')]
        [string] 
        $Token,

        # Validate the Jump Path.
        [switch]
        $Validate,

        # Pass the database object through.
        [switch]
        $PassThru
    )

    begin {
        # Warns if a jump path does not exist.
        # Exits if user also Validates.
        # unit -> unit 
        function ValidateJumpPath {
            $isJumpPath = Test-Path $JumpPath

            if (-not $isJumpPath) {
                Write-Warning ($Messages.BadJumpPath -f $JumpPath) 
            } 

            if ($Validate -and -not $isJumpPath) {
                exit 1 
            }
        }
        

        # Only pass an object if one of its properties has a value.
        # obj -> obj?
        filter FilterNullObj {
            foreach ($p in $_.PSObject.Properties.Value) {
                if (-not [string]::IsNullOrEmpty($p)) {
                    return $_
                }
            }
        }
        

        # Check for dupes and bounce if one is found
        # obj -> unit
        function ExitOnDuplicates ($obj) {
            # Check for dupes and bounce if one is found.
            $isDuplicateToken = $obj.Token.Contains($Token)

            if ($isDuplicateToken) {
                Write-Error ($Messages.AddNavTokenDuplicate -f $Token) -ErrorAction Stop
            } 
        }
    }

    process {
        ValidateJumpPath

        if ($null -ne $Db) {
            ExitOnDuplicates $Db
        } 

        # Xeq 
        if ($PSCmdlet.ShouldProcess($Path, "Adding: $Token -> $JumpPath")) {
            $newShortCut = ShortcutObj $JumpPath $Token
            
            $newShortCut | AddToDb

            $Db.ToArray() |
                FilterNullObj |
                Collect | 
                ToNavDb $Path 

            if ($PassThru) {
               $newShortCut 
            } 
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
        [ValidateScript({ (Test-Path $_) -or $( throw "${_}: not a valid nav file!" ) })]
        [string]
        $Path = $DefaultPath,

        # The tokens to fetch from the database.
        [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments, ValueFromPipelineByPropertyName)]
        [string[]]
        $Token = '*',

        # Returns the jump path only.
        [Alias('PathOnly', 'ValueOnly')]
        [switch]
        $JumpPathOnly
    )
    
    begin { 
        $dbContent = 
            if ($PSBoundParameters.ContainsKey('Path')) {
                Import-Csv -Path $Path 
            }
            else {
                $Db 
            }
        $getToken = {
            $s = $_
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
       [ValidateScript({ (Test-Path $_) -or $( throw "${_}: not a valid nav file!" ) })]
       [string]
       $Path = $DefaultPath,

       # The tokens to remove from the database.
       [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments, ValueFromPipelineByPropertyName)]
       [string[]]
       $Token 
    )
    
    begin {
        $dbContent = Import-Csv -Path $Path 
        $getRemainingToken = {
            $s = $_
            $dbContent.Where{ $_.Token -notlike $s }
        }
    }
    
    process {
        if ($PSCmdlet.ShouldProcess(($Token -join ", "), 'Removing from database')) {
            $Token.Foreach($getRemainingToken) |
                Collect |
                ToNavDb $Path 
        } 
    }
    
    end {
        UpdateDb $Path
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
        [string]
        $Path,

        # Database file to load info from.
        [Parameter()]
        [ValidateScript({ (Test-Path $_) -or $( throw "${_}: not a valid nav file!" ) })]
        [string]
        $DatabasePath = $DefaultPath,

        # If a previous location is available on the stack, goes back one location.
        [switch]
        $Back,
        
        # If back is indicated, will try to go back into the stack at this depth.
        [int]
        $BackDepth = 1
    )

    begin {
        

        $dbContent = 
            if ($PSBoundParameters.ContainsKey('DatabasePath')) {
                Import-Csv -Path $DatabasePath 
            }
            else {
                $Db 
            }

        
        function GetJumpPath {
            $dbContent.Where{ $Path -like $_.Token }.JumpPath
        }

        filter Jump {
            if (Test-Path $_) {
                Push-Location $_
            }
            else {
                Write-Warning ($Messages.BadJumpPath -f $_)
            }

            return
        }
    }

    end {
        if ($Back -and ($BackDepth -le (Get-Location -Stack).Count)) {

            do {
                Pop-Location
                $BackDepth--
            } until ($BackDepth -eq 0) 

            return
        }
        if ($Back -and ($BackDepth -gt (Get-Location -Stack).Count)) {
            Write-Error ($Messages.StackDepthExceeded -f $BackDepth) -ErrorAction Stop
        }

        $jp = GetJumpPath

        if ($null -ne $jp) {
            $jp | Jump
        }
        else {
            $Path | Jump
        }
    }
}

#endregion

<#
 
   _____                       _   
  | ____|_  ___ __   ___  _ __| |_ 
  |  _| \ \/ / '_ \ / _ \| '__| __|
  | |___ >  <| |_) | (_) | |  | |_ 
  |_____/_/\_\ .__/ \___/|_|   \__|
             |_|                   
 
#>

$Exports = @(
    'Get-DefaultNavigationFile'
    'Set-DefaultNavigationFile'
    'New-NavigationFile'
    'Add-NavigationEnty'
    'Get-NavigationEntry'
    'Remove-NavigationEntry'
    'Invoke-GoPS'
)

Export-ModuleMember -Function $Exports -Alias 'AddGo', 'GetGo', 'RmGo', 'Go'
