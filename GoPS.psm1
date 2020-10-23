using namespace System.Collections.Generic

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
    # This parameter exists in lieu of a config file.   
    $DefaultPath = "$HOME/.gops"
)

<#
 
                                
   -_-/          ,              
  (_ /          ||              
 (_ --_   _-_  =||= \\ \\ -_-_  
   --_ ) || \\  ||  || || || \\ 
  _/  )) ||/    ||  || || || || 
 (_-_-   \\,/   \\, \\/\\ ||-'  
                          |/    
                          '     
 
#>
#region Setup ------------------------------------------------------------------

$ErrorActionPreference = 'Stop' 
$ModuleRoot = Split-Path $PSScriptRoot -Leaf
$ResourceFile = @{ 
    BindingVariable = 'Message'
    BaseDirectory = $PSScriptRoot
    FileName = $ModuleRoot + '.Resources.psd1'
}

# Try to import the resource file
try {
    Import-LocalizedData @ResourceFile 
}
catch {
    # Uh-oh. The module is likely broken if this file cannot be found.
    Import-LocalizedData @ResourceFile -UICulture en-US
}



#endregion

<#
 
                                           
   ,- _~. ,,                               
  (' /|   ||   _                           
 ((  ||   ||  < \,  _-_,  _-_,  _-_   _-_, 
 ((  ||   ||  /-|| ||_.  ||_.  || \\ ||_.  
  ( / |   || (( ||  ~ ||  ~ || ||/    ~ || 
   -____- \\  \/\\ ,-_-  ,-_-  \\,/  ,-_-  
                                           
                                           
 
#>
#region Classes ----------------------------------------------------------------

class Entry {
    [string] $Token
    [string] $Path 
    [bool] $IsValid
}


class Database { 
    [List[Entry]] $EntryList 
    [HashSet[string]] $TokenSet
}


#endregion 

<#
 
                                      
 _-_-            ,,                   
   /,            ||                   
   || __    _-_  || -_-_   _-_  ,._-_ 
  ~||-  -  || \\ || || \\ || \\  ||   
   ||===|| ||/   || || || ||/    ||   
  ( \_, |  \\,/  \\ ||-'  \\,/   \\,  
        `           |/                
                    '                 
 
#>
#region helper -----------------------------------------------------------------

function New-Entry {
    [CmdletBinding()]

    param(
        # Token Name.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Token
        ,
        # Path Name.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Path 
    )

    $o = $Path -as [System.IO.DirectoryInfo]

    [Entry] @{
        Token = $Token
        Path = $Path
        IsValid = $o.Exists
    }
}


function New-Database {
    [Database] @{
        EntryList = @()
        TokenSet = @()
    }
}


# filter Add-Entry ($x) {
#     if ($_.TokenSet.Add($x.Token)) {
#         [void] $_.EntryList.Add($x)
        
#         $_ 
#     } 
#     else {
#         Write-Warning ($Message.Warning.AddEntry -f $x.Token)
#     }
# }

filter Add-Entry ($x) {
    if ($x.TokenSet.Add($_.Token)) {
        [void] $x.EntryList.Add($_)
    } 
    else {
        Write-Warning ($Message.Warning.AddEntry -f $_.Token)
    }
}
filter ConvertFrom-Database {
    $_.EntryList.ToArray()
}


function Get-ValidJumpPaths {
    $f = { $_.IsValid }

    $input.Where($f)
}

#endregion

<#
 
                                            
 _-_,         ,                          ,, 
   //        ||                      _   || 
   || \\/\\ =||=  _-_  ,._-_ \\/\\  < \, || 
  ~|| || ||  ||  || \\  ||   || ||  /-|| || 
   || || ||  ||  ||/    ||   || || (( || || 
 _-_, \\ \\  \\, \\,/   \\,  \\ \\  \/\\ \\ 
                                            
                                            
 
#>
#region Internal ---------------------------------------------------------------

function Import-NavigationFile ($s) {
    $x = New-Database 
    $xs = (Import-Csv $s) -as [Entry[]]

    $xs | Add-Entry $x

    $x 
}
#endregion

<#
 
     __ ,                                                         
   ,-| ~           ,        ,,                                    
  ('||/__,   _    ||        ||                      '         _   
 (( |||  |  < \, =||=  _-_  ||/\  _-_   _-_  -_-_  \\ \\/\\  / \\ 
 (( |||==|  /-||  ||  || \\ ||_< || \\ || \\ || \\ || || || || || 
  ( / |  , (( ||  ||  ||/   || | ||/   ||/   || || || || || || || 
   -____/   \/\\  \\, \\,/  \\,\ \\,/  \\,/  ||-'  \\ \\ \\ \\_-| 
                                             |/              /  \ 
                                             '              '----`
 
#> 
#region gatekeeping ------------------------------------------------------------

function Assert-Path ($s) {
    <#
    .Description
      Halt on Test-Path failure.
      Takes a filepath.
      string -> unit
    #> 

    if (!(Test-Path $s)) {
        throw ($Message.TerminatingError.NavFileInvalid -f $s)
    }

    $true
}

#endregion


# Module variables go here
Set-Variable GoPS -Value @{
    DefaultPath = $DefaultPath
    Database = New-Database
}

<#
 
                                 
 -__ /\\        ,,    ,,         
   ||  \\       ||    ||  '      
  /||__|| \\ \\ ||/|, || \\  _-_ 
  \||__|| || || || || || || ||   
   ||  |, || || || |' || || ||   
 _-||-_/  \\/\\ \\/   \\ \\ \\,/ 
   ||                            
                                 
 
#>
#region Public -----------------------------------------------------------------

function New-NavigationFile {
    <#
    .Synopsis
      Creates a new navigation database file.
    .Description
      Creates a Home entry and exports to a CSV file. 
      Will not overwrite an existing file unless the -Force parameter is passed.
    .Example
      PS> New-NavigationFile -Path [FilePath]
        Creates a new file at the given FilePath if it does not already exist.
    .Example
      PS> New-NavigationFile -Path [FilePath] -Force
        Wipes the file at the Path and creates a new blank database. 
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # Specifies a path to database file. Default: $HOME/.navdb
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $GoPS.DefaultPath
        , 
        # Forces creation of a new file.
        [switch] $Force
    )
    
    $NoClobber = !$Force
    $x = New-Database

    if ($PSCmdlet.ShouldProcess($Path, $Message.ShouldProcess.NewNavigationFile)) {
        New-Entry Home $HOME |
            Add-Entry $x 

        $x |
            ConvertFrom-Database |
            Export-Csv -Path $Path -NoClobber:$NoClobber -NoTypeInformation

        Write-Verbose ($Message.Verbose.NewNavigationFile -f $Path)
    } 
}


function Get-DefaultNavigationFile {
    <#
    .Description
      Returns the default path of the navigation file currently set.
      unit -> PathInfo
    #>

    Resolve-Path $GoPS.DefaultPath
}


function Set-DefaultNavigationFile {
    <#
    .Synopsis
      Sets the default navigation file path.
    .Description
      Sets the default navigation file path for GoPS.
      The default path is set on module load.
      If no parameter is sent on module load, default path defaults to .gops in the user's home path.
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # Specifies a path to database file.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)] 
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $GoPS.DefaultPath
    )
    
    if ($PSCmdlet.ShouldProcess($Path, $Message.ShouldProcess.SetDefaultNavigationFile)) {
        if ($Path -eq $GoPS.DefaultPath) {
            return
        }

        $GoPS.DefaultPath = $Path

        Write-Verbose ($Message.Verbose.SetDefaultNavigationFile -f $Path)
    }
}


function Export-NavigationDatabase {
    <#
    .Synopsis
      Exports the NavigationDatabase in memory to a Navigation File.
    .Description
      Exports the Navigation Database in memory to a Navigation File.
      If the Path is not given, defaults to the Default Navigation File.
    .Example
      PS> Export-NavigationDatabase
        Exports the current Navigation Database to the default navigation file. 
    .Example
      PS> [Database] | Export-NavigationDatabase
        Exports a given Navigation Database to the default navigation file. 
    .Example
      PS> Export-NavigationDatabase -InputObject [Database]
        Exports a given Navigation Database to the default navigation file. 
    .Example
      PS> [Database] | Export-NavigationDatabase -Path [FilePath]
        Exports a given Navigation Database to the [FilePath]
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # The database to export. Default: Current database in memory
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Database] $InputObject = $GoPS.Database
        ,
        # Specifies a path to one or more locations.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [Alias('PSPath')]
        [string] $Path = $GoPS.DefaultPath
    )

    if ($PSCmdlet.ShouldProcess($Path, $Message.ShouldProcess.ExportNavigationDatabase)) {
        $InputObject |
            ConvertFrom-Database | 
            Export-Csv -Path $Path -NoTypeInformation
    }
}


function Update-NavigationDatabase {
    <#
    .Synopsis
      Updates the navigation database in memory contents of a navigation file.
    .Description 
    .Example 
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # The navigation file to import from.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [Alias('PSPath')]
        [string] $Path = $GoPS.DefaultPath
    )

    
    if ($PSCmdlet.ShouldProcess($Path, $Message.ShouldProcess.UpdateNavigationDatabase)) { 
        $GoPS.Database = Import-NavigationFile $Path
    }
}


function Add-NavigationEntry {
    <#
    .Description
      Adds a token and jump path to the database.
    #>

    [CmdletBinding()]
    [Alias('AddGo')]

    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $GoPS.DefaultPath
        ,
        # Token or shortcut to use.
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Shortcut')]
        [string] $Token
        ,
        # Jump path.
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [string] $JumpPath = $PWD
    )

    $isValidPath = Test-Path $JumpPath

    if (!$isValidPath) {
        Write-Warning ($Message.Warning.BadJumpPath -f $JumpPath) 
    }

    New-Entry -Token $Token -Path $JumpPath |
        Add-Entry $GoPS.Database 

    $GoPS.Database | ConvertFrom-Database 
}


function Get-NavigationEntry {
    <#
    .Description
      Returns navigation entries in the database.
    #>

    [CmdletBinding()]
    [Alias('GetGo')]
    
    param( 
        # Specifies a path to a database file.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $GoPS.DefaultPath
        ,
        # The tokens to fetch from the database.
        [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
        [string[]] $Token = '*'
        ,
        # Returns the jump path only.
        [Alias('PathOnly', 'ValueOnly')]
        [switch] $JumpPathOnly
    )

    $x = $GoPS.Database | ConvertFrom-Database
    $f = {
       $_.Token -like $Token
    } 
    $y = $x.Where($f)
    
    ($y, $y.Path)[$JumpPathOnly.IsPresent]
}


function Remove-NavigationEntry {
    <#
    .Synopsis
      Removes entry from navigation database.
    #>

    [CmdletBinding()]
    [Alias('RmGo')]

    param(
        # The tokens to remove from the database.
        [Parameter(Position = 0,
            ValueFromPipeline,
            ValueFromRemainingArguments,
            ValueFromPipelineByPropertyName)]
        [string[]] $Token 
        ,
        [switch] $PassThru
    )

    $x = $GoPS.Database 
    $y = Get-NavigationEntry $Token

    if (!$y) {
        return 

        if ($PassThru.IsPresent) {
            $x | ConvertFrom-Database
        }
    }

    [void] $x.EntryList.Remove($y)
    [void] $x.TokenSet.Remove($Token)

    if ($PassThru.IsPresent) { 
        $x | ConvertFrom-Database
    }
}


function Invoke-GoPS {
    <#
    .Synopsis
      Jumps to a token.
    #>
    [Alias('Go')]
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [Alias('Token')]
        [string] $Path,

        # If a previous location is available on the stack, goes back one location.
        [switch] $Back,
        
        # If back is indicated, will try to go back into the stack at this depth.
        [int] $BackDepth = 1
    )

    $stackCount = (Get-Location -Stack).Count

    if ($Back -and ($BackDepth -le $stackCount)) { 
        do {
            Pop-Location
            $BackDepth--
        } until ($BackDepth -eq 0)

        return
    }

    if ($Back -and ($BackDepth -gt $stackCount)) {
        Write-Error ($Message.TerminatingError.StackDepthExceeded -f $BackDepth) -ErrorAction Stop
    }

    $x = Get-NavigationEntry $Path

    if ($x.IsValid) {
        Push-Location $x.Path
    }
    elseif (-not $PSBoundParameters.ContainsKey('Path')) {
        Push-Location $pwd
    }
    else {
        if (Test-Path $Path) {
            Push-Location $Path
        }
    }
}


function Invoke-Back {
    [Alias('Back')]
    param(
        [int] $n = 1
    )

    Invoke-GoPS -Back -BackDepth $n
}


#endregion

<#
 
                                       
   ,- _~,                           ,  
  (' /| / ,                        ||  
 ((  ||/= \\ /` -_-_   /'\\ ,._-_ =||= 
 ((  ||    \\   || \\ || ||  ||    ||  
  ( / |    /\\  || || || ||  ||    ||  
   -____- /  \; ||-'  \\,/   \\,   \\, 
                |/                     
                '                      
 
#>
#region Export -----------------------------------------------------------------

$Functions = @(
    'Get-DefaultNavigationFile'
    'Set-DefaultNavigationFile'
    'New-NavigationFile'
    'Add-NavigationEntry'
    'Get-NavigationEntry'
    'Remove-NavigationEntry'
    'Invoke-GoPS'
    'Invoke-Back'
    'Export-NavigationDatabase'
    'Update-NavigationDatabase'
    # 'Import-NavigationFile'
)

$Aliases = @(
    'go'
    'back'
    'addgo'
    'rmgo'
    'getgo'
)

Update-NavigationDatabase
Export-ModuleMember -Function $Functions -Alias $Aliases

#endregion
