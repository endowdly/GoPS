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

#region Setup ------------------------------------------------------------------
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

#region Classes ----------------------------------------------------------------
<#
 
                                           
   ,- _~. ,,                               
  (' /|   ||   _                           
 ((  ||   ||  < \,  _-_,  _-_,  _-_   _-_, 
 ((  ||   ||  /-|| ||_.  ||_.  || \\ ||_.  
  ( / |   || (( ||  ~ ||  ~ || ||/    ~ || 
   -____- \\  \/\\ ,-_-  ,-_-  \\,/  ,-_-  
                                           
                                           
 
#>


class Entry {
    [string] $Token
    [string] $Path 
    [bool] $IsValid
}


class Database { 
    [List[Entry]] $EntryList 
    [HashSet[string]] $TokenSet
}

# A nice, human-readable Entry list
class JumpStack {
    [int] $Jump
    [string] $Name
    [string] $FullName
}


#endregion 

#region helper -----------------------------------------------------------------
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


function New-Entry {
    # .Description
    # Creates a new Entry object.
    # string -> string -> Entry

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
    # .Description 
    # Creates a new Database object.
    # () -> Database

    [Database] @{
        EntryList = @()
        TokenSet = @()
    }
}


filter Add-Entry ($x) {
    # .Description 
    # Adds a piped Entry to a Database object.
    # This modifies the Database object.
    # seq<Entry> -> Database -> () 

    if ($x.TokenSet.Add($_.Token)) {
        [void] $x.EntryList.Add($_)
    } 
    else {
        Write-Error ($Message.Error.AddEntry -f $_.Token)
    }
}


filter ConvertFrom-Database {
    # .Description
    # Converts a Database object to an Entry array.
    # Database -> Entry[]

    $_.EntryList.ToArray()
}


function New-JumpStack {
    # .Description
    # Creates a new JumpStack object from a piped DirectoryInfo object.
    # seq<DirectoryInfo> -> JumpStack

    begin { 
        $c = 1
    }

    process { 
        [JumpStack] @{
            Jump = $c
            Name = $_.Name
            FullName = $_.FullName
        }

        $c++
    }
}

#endregion

#region Internal ---------------------------------------------------------------
<#
 
                                            
 _-_,         ,                          ,, 
   //        ||                      _   || 
   || \\/\\ =||=  _-_  ,._-_ \\/\\  < \, || 
  ~|| || ||  ||  || \\  ||   || ||  /-|| || 
   || || ||  ||  ||/    ||   || || (( || || 
 _-_, \\ \\  \\, \\,/   \\,  \\ \\  \/\\ \\ 
                                            
                                            
 
#>


function Import-NavigationFile ($s) {
    # .Description
    # Imports the data from a navigation file and returns the Database object.
    # If no file is at the given path, returns a friendly information string and returns an empty Database object.
    # string -> Database

    if (!(Test-Path $s)) {
        Write-Warning ($Message.Information.NoNavFile -f $s)

        return New-Database 
    }

    $x = New-Database 
    $xs = (Import-Csv $s) -as [Entry[]]

    $xs | Add-Entry $x

    $x 
}


function Push-Path ($s) {
    # .Description
    # If the given path is a valid directory, does 2 things:
    # 1. Pushes the current path onto module PathStack
    # 2. Changes the path to the given path, recording the path onto the provider path stack 
    # string -> ()


    $s1 = Convert-Path $s 
    $x = [System.IO.DirectoryInfo] $s1

    if ($x.Exists) {
        $GoPS.PathStack.Push($GoPS.LastPath)

        Push-Location $x.FullName -StackName GoPS
    } 
}


# Module variables go here
$GoPS = @{
    DefaultPath = $DefaultPath
    Database    = New-Database
    LastPath    = $PWD.Path
    PathStack   = [Stack[System.IO.DirectoryInfo]] @()
}


#endregion


#region gatekeeping ------------------------------------------------------------
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

function Assert-Path ($s) {
    # .Description
    # Halt on Test-Path failure.
    # string -> ()

    if (!(Test-Path $s)) {
        throw ($Message.TerminatingError.NavFileInvalid -f $s)
    }

    $true
}

#endregion



#region Public -----------------------------------------------------------------
<#
 
                                 
 -__ /\\        ,,    ,,         
   ||  \\       ||    ||  '      
  /||__|| \\ \\ ||/|, || \\  _-_ 
  \||__|| || || || || || || ||   
   ||  |, || || || |' || || ||   
 _-||-_/  \\/\\ \\/   \\ \\ \\,/ 
   ||                            
                                 
 
#>

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
        # Specifies a path to database file. Default: Module DefaultPath
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
    .Synopsis 
      Returns the default path of the navigation file currently set.
    .Description
      Returns the default path of the navigation file currently set.
      () -> PathInfo
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
        # Specifies a path to database file. Default: Module DefaultPath
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
        # Specifies a path to database file. Default: Module DefaultPath
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
      Updates the navigation database in memory to the contents of a navigation file.
    .Description 
      Updates the navigation database in memory to the contents of a navigation file.
    .Example 
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # Specifies a path to database file. Default: Module DefaultPath
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
    .Example
      PS> addgo jump C:\Users\me\jump
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
        ,
        [switch] $Silent
    )

    process {
        $isValidPath = Test-Path $JumpPath

        if (!$isValidPath) {
            Write-Warning ($Message.Warning.BadJumpPath -f $JumpPath) 
        }

        <# Done: IO.DirectoryInfo objects will not validate incomplete, unqualified paths @endowdly
            'Help' IO.DirectoryInfo validate these paths
            We don't want invalid paths to be ignored, so only change valid ones
        #> 
        $JumpPath = ($JumpPath, (Convert-Path $JumpPath))[$isValidPath]

        New-Entry -Token $Token -Path $JumpPath |
            Add-Entry $GoPS.Database 
    }

    end {
        
        if ($Silent.IsPresent) {
            return
        }

        $GoPS.Database | ConvertFrom-Database 
    }
}


function Get-NavigationEntry {
    <#
    .Description
      Returns navigation entries in the database.
    .Example 
      PS> getgo this that theOther

      Returns the jumppaths for the tokens 'this', 'that', and 'theOther'.
    .Example
       PS> getgo git* 

      Returns all the jumpaths starting with git
    .Example
      PS> getgo -jumppathonly

      Returns a list of all the fullpaths for each jump path in the databse.
    #>

    [CmdletBinding()]
    [Alias('GetGo')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    
    param( 
        # Specifies a path to a database file. Default: Module DefaultPath
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $GoPS.DefaultPath
        ,
        # The tokens to fetch from the database. Default: '*'
        [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
        [ArgumentCompleter({ (Get-NavigationEntry).Token })]
        [string[]] $Token = '*'
        ,
        # Returns the jump path only.
        [Alias('PathOnly', 'ValueOnly')]
        [switch] $JumpPathOnly
    )

    begin {
        $x = $GoPS.Database | ConvertFrom-Database
        $f = {
            $currentToken = $_

            $x.Where($g)
        }
        $g = {
            $_.Token -like $currentToken
        } 
    }

    process {
        $y = $Token.Foreach($f) 
        ($y, $y.Path)[$JumpPathOnly.IsPresent]
    }
}


function Remove-NavigationEntry {
    <#
    .Synopsis
      Removes entry from navigation database.
    .Example
      PS> rmgo this that theOther

      Removes the tokens 'this', 'that', and 'theOther' from the Database.
    #>

    [CmdletBinding()]
    [Alias('RmGo')]

    param(
        # The tokens to remove from the database.
        [Parameter(Position = 0,
            ValueFromPipeline,
            ValueFromRemainingArguments,
            ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({ (Get-NavigationEntry).Token })]
        [string[]] $Token 
        ,
        [switch] $Silent
    ) 

    begin {
        $f = {
            $x = Get-NavigationEntry $_

            if ($null -ne $x) { 
                [void] $GoPS.Database.EntryList.Remove($x)
                [void] $GoPS.Database.TokenSet.Remove($_)
            }
        }
    }

    process {
        $x = $Token.ForEach($f)
    }

    end {

        if ($Silent.IsPresent) { 
            return
        }

        $GoPS.Database | ConvertFrom-Database
    }
}


function Invoke-GoPS {
    <#
    .Synopsis
      Jumps to a token.
    .Description
      Invoke-GoPS is the primary use point for the module.

      Because Invoke-GoPS handles jumping to paths stored in the Database, Invoke-GoPS can also ease other console navigation.
      Each jump or directory visited with the 'go' command is stored in an internal Path Stack.
      This stack allows to user to quickly jump back a number of directories with the Back function. 
      Using the -Last switch will allow the user to jump back and forth to the last visited directory.
      This location is not popped off the stack and not recorded in the stack. 

      Back and Last are provided in the module as convenience functions.
    .Example
      PS> go home
    .Link
      Invoke-Back
    .Link
      Invoke-Last
    .Inputs 
      string
    .Outputs 
      void
    .Notes 
      string -> ()
      int -> ()
    #>

    [Alias('Go')]
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({ (Get-NavigationEntry).Token })]
        [AllowNull()]
        [Alias('Token')]
        [string] $Path,

        # If a previous location is available on the stack, goes back one location.
        [switch] $Back
        ,
        # Goes to the last visited location.
        [switch] $Last
        ,
        # If back is indicated, will try to go back into the stack at this depth.
        [int] $BackDepth = 1
    )

    $stackCount = $GoPS.PathStack.Count
    $lastPath = $GoPS.lastPath
    $GoPS.LastPath = $pwd.Path

    # $stackCount = (Get-Location -Stack).Count

    if ($Last) {
        Push-Location $lastPath -StackName GoPS
        
        return 
    }

    if ($Back -and ($BackDepth -le $stackCount)) { 
        do {
            Push-Location $GoPS.PathStack.Pop().FullName -StackName GoPS
            $BackDepth--
        } until ($BackDepth -eq 0)

        return
    }

    if ($Back -and ($BackDepth -gt $stackCount)) {
        Write-Error ($Message.TerminatingError.StackDepthExceeded -f $BackDepth, $stackCount) -ErrorAction Stop
    }

    $x = Get-NavigationEntry $Path

    if ($x.IsValid) {
        Push-Path $x.Path
    }
    else {
        Push-Path $Path
    }
}


function Invoke-Back {
    <# 
    .Description
      Calls Invoke-GoPS with the -Back switch enabled. 
      Back only works with paths reach with GoPS.
    .Link
      Invoke-GoPS
    .Link
      Get-GoPSStack
    #>

    # The number of back jumps to make.
    [Alias('Back')]
    param(
        [int] $n = 1
    )

    Invoke-GoPS -Back -BackDepth $n
}


function Invoke-Last {
    <# 
    .Description
      Calls Invoke-GoPS with the -Last switch enabled. 
      Last only works with paths reached with GoPS.
    .Link
      Invoke-GoPS
    .Link
      Get-GoPSStack
    #>

    [Alias('Last')]
    param ()

    Invoke-GoPS -Last
}


function Get-GoPSStack {
    <#
    .Description
      Displays the current contents of the module Path Stack.
      () -> JumpStack[]
    #>

    $GoPS.PathStack | New-JumpStack
}


function Get-JumpHistory {
    <#
    .Synopsis
      Displays the entire path history of the GoPS module (from load).
    .Description
      Displays the entire path history of the GoPS module (from load).
      Unlike the GoPS Path Stack (Get-GoPSStack), last and back commands are recorded.
    #>

    (Get-Location -StackName GoPS).ToArray() |
        ForEach-Object Path |
        ForEach-Object { $_ -as [System.IO.DirectoryInfo] } | 
        New-JumpStack
}


function Invoke-Up {
    <#
    .Synopsis
      Traverse up in a path tree easily, accepts paths, wildcard strings, or integers.
    .Description
      Traverse up in a path tree easily, accepts paths, wildcard strings, or integers.
      Accepts integers as the number of directories to move up.
      Accepts paths to move up to a matching path in a parent directory.
      Accepts wildcard strings as the same.
      Derived from up by Shannon Moeller and endowdly's work on the fish port. 
    .Example
      PS> Up 2 
  
      Moves up 2 parent directories.
    .Example
      PS> up  
  
      Moves up 2 parent directories.
    .Example
      PS> Up Us*

      Moves up to the C:\User directory (if it is the first match in the path tree) 
    .Notes
      obj -> ()
    #>

    [Alias('up')]
    param($Value)
    
    <# Note
      PWD is returned as a PathInfo object.
      It is normally safely consumed but all -Location Cmdlets.
      However, the internal function Push-Path cannot handle PathInfo objects.
      So, get the strings. #> 
    
    $ProviderPathRoot = Convert-Path /
    function UpDir ($Parent, $Target) {

        if ($Parent -eq $ProviderPathRoot) { 
            return $Target
        }

        $p = Split-Path $Parent
        $a = Split-Path $p -Leaf
        $b = $Target

        if (!$a -or !$b) {
             return $PWD.Path
        }

        if ($a -like $b) {
            return $p
        }

        UpDir $p $Target
    }

    function UpNum ($Parent, $Index) {
        if ($null -eq $Parent -or $null -eq $Index) {
            return $PWD.Path
        }

        if ($Index -le 0) {
            return $PWD.Path
        }

        do {
            $Parent = Split-Path $Parent
            $Index--
        } while ($Index -gt 0)
        
        $Parent
    }

    $Up = Convert-Path .. 

    switch ($Value) {
        $null {
            Push-Path $Up
            break
        }

        { $_ -is [int] } {
            $temp = UpNum $PWD $Value

            if (Test-Path $temp) {
                Push-Path $temp
            }

            break
        }

        default { 
            if (Test-Path $Value) {
                Push-Path $Value

                break
            }

            $temp = UpDir $PWD.Path $Value

            if (Test-Path $temp) {
                Push-Path $temp

                break
            }

            Write-Host @"
usage: up [ dir | num ]
pwd: $PWD"
"@
        }
    } 
}
#endregion

#region Export -----------------------------------------------------------------
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

$Functions = @(
    'Get-DefaultNavigationFile'
    'Set-DefaultNavigationFile'
    'New-NavigationFile'
    'Add-NavigationEntry'
    'Get-NavigationEntry'
    'Remove-NavigationEntry'
    'Invoke-GoPS'
    'Invoke-Back'
    'Invoke-Last'
    'Export-NavigationDatabase'
    'Update-NavigationDatabase'
    # 'Import-NavigationFile'

    'Get-GoPSStack'
    'Get-JumpHistory'
    'Get-Token'

    'Invoke-Up'
)

$Aliases = @(
    'go'
    'back'
    'last'
    'addgo'
    'rmgo'
    'getgo'

    'up'
)

Update-NavigationDatabase
Export-ModuleMember -Function $Functions -Alias $Aliases

#endregion
