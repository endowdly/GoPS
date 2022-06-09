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
    # This is the default navigation file path to be used if a config file is missing. Default: $HOME/.navdb
    $DefaultNavigationFile = "$HOME/.gops"
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
$ConfigFile = @{
    BindingVariable = 'Config'
    BaseDirectory = $PSScriptRoot
    FileName = $ModuleRoot + '.Config.psd1'
}


# Try to import the resource file
try {
    Import-LocalizedData @ResourceFile 
}
catch {
    # Uh-oh. The module is likely broken if this file cannot be found.
    Import-LocalizedData @ResourceFile -UICulture en-US
}

data ConfigProperties {
    'DefaultNavigationFile'
    'CommandAlias' 
}

data CommandAliasProperties {
    'Add-NavigationEntry'
    'Export-NavigationEntry'
    'Get-DefaultNavigationFile'
    'Get-GoPSStack'
    'Get-JumpHistory'
    'Get-NavigationEntry'
    'Invoke-Back'
    'Invoke-GoPS'
    'Invoke-Last'
    'Invoke-Up'
    'New-NavigationFile'
    'Remove-NavigationEntry'
    'Set-DefaultNavigationFile'
    'Update-NavigationDatabase'
}

data DefaultConfig -SupportedCommand Get-Variable {
    @{ 
        DefaultNavigationFile = Get-Variable DefaultNavigationFile -ValueOnly
        CommandAlias = @{} 
    }
}

# Try to import the config file
try {
    Import-LocalizedData @ConfigFile 

    $xs = [HashSet[string]] [string[]] $Config.Keys
    $ys = [HashSet[string]] $ConfigProperties

    if (!$xs.IsSubsetOf($ys)) {
        [void] $xs.ExceptWith($ys)

        throw ($Message.TerminatingError.InvalidConfig -f ($xs -join ', '), ($ConfigProperties -join ', '))
    }

    if ($Config.ContainsKey('CommandAlias')) {
        $xs = [HashSet[string]] [string[]] $Config.CommandAlias.Keys
        $ys = [HashSet[string]] $CommandAliasProperties

        if (!$xs.IsSubsetOf($ys)) {
            [void] $xs.ExceptWith($ys)

            throw ($Message.TerminatingError.InvalidCommandAlias -f
                ($xs -join ', '),                
                ($CommandAliasProperties -join "`n"))
        }
    }
}
catch [System.Management.Automation.ItemNotFoundException] {
    Write-Warning $Message.Warning.ConfigFileNotFound 

    $Config = $DefaultConfig
}
catch { 
    
    throw $_.Exception
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

function Invoke-Ternary {
    <#
    .Description
      A nice internal ternary function.
      Helps improve script readability by removing the need to use PowerShell array logic for trivial if-else
      expressions. 
      Array logic ternary expressions can be confusing syntax for PowerShell beginners.

      Array ternary logic example: ('false case', 'true case')[$conditional]

      bool -> scriptblock -> scriptblock -> () #>

    param (
        # The conditional statement. Must evaluate to a boolean.
        [bool] $Conditional
        ,
        # A scriptblock to invoke when the conditional parameter evaluates to True.
        [scriptblock] $OnTrue
        ,
        # A scriptblock to invoke when the conditional parameter evaluates to False.
        [scriptblock] $OnFalse
    )

    if ($Conditional) {
        & $OnTrue
    }
    else {
        & $OnFalse
    } 
}


function New-Entry { 
    <#
    .Description
      Creates a new Entry object.
      string -> string -> Entry #>

    [CmdletBinding()]  # Makes variables easier to get from pipeline

    param (
        # Token Name.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Token
        ,
        # Path Name.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Path 
    )

    $x = $Path -as [System.IO.DirectoryInfo]

    [Entry] @{
        Token   = $Token
        Path    = $Path
        IsValid = $x.Exists
    }
}


function New-Database { 
    <#
    .Description 
      Creates a new Database object.
      () -> Database #>

    [Database] @{
        EntryList = @()
        TokenSet  = @()
    }
}


filter Add-Entry ($x) {
    <#
    .Description 
      Adds a piped Entry to a Database object if the Entry does not have a duplicate Token property.
      If the Token property of the Entrty object already exists in the Database, the Entry is ignored.
      A successful operation modifies the Database object.
      A failed operation emits an error.
      seq<Entry> -> Database -> () #> 

    if ($x.TokenSet.Add($_.Token)) {
        [void] $x.EntryList.Add($_)
    } 
    else {
        Write-Error ($Message.Error.AddEntry -f $_.Token)
    }
}


filter ConvertFrom-Database {
    <#
    .Description
      Converts a Database object to an Entry array.
      Database -> Entry[] #>

    $_.EntryList.ToArray()
}


function New-JumpStack {
    <#
    .Description
      Creates a new JumpStack object from a piped DirectoryInfo object.
      seq<DirectoryInfo> -> seq<JumpStack> #>

    begin { 
        $c = 1
    }

    process { 
        [JumpStack] @{
            Jump = $c++
            Name = $_.Name
            FullName = $_.FullName
        }
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


# Todo: Make this a public cmdlet @endowdly
function Import-NavigationFile ($s) {
    <#
    .Description
      Imports the data from a navigation file and returns the Database object.
      If no file is at the given path, emits a friendly information string and returns an empty Database object.
      string -> Database #>

    if (!(Test-Path $s)) {
        Write-Warning ($Message.Warning.NoNavFile -f $s)

        return New-Database 
    }

    $x = New-Database 

    [Entry[]] (Import-Csv $s) |
        Add-Entry $x

    $x 
}


function Push-Path ($s) {
    <#
    .Description
      If the given path is a valid directory:
        - Pushes the current path onto module PathStack
        - Sets the path to the valid directory
        - Records the new path onto the provider PathStack 
      Does nothing otherwise.
      string -> () #>


    $s1 = Convert-Path $s 
    $x = [System.IO.DirectoryInfo] $s1

    if ($x.Exists) {
        $GoPS.PathStack.Push($GoPS.LastPath)

        Push-Location $x.FullName -StackName GoPS
    } 
}


$setAlias = {
    if ($_.Value -eq '') {
        return
    }

    Set-Alias -Value $_.Key -Name $_.Value -Scope Script
}


# Module variables go here
$GoPS = @{
    DefaultPath = $Config.DefaultNavigationFile
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
    <#
    .Description
      Throw on Test-Path failure.
      string -> () #>

    if (!(Test-Path $s)) {
        throw ($Message.TerminatingError.NavFileInvalid -f $s)
    }

    $true
}


function Assert-PositiveNumber ($d) {
    <#
    .Description
      Throw if d is not a positive number. #>

    if ($d -lt 0) {
        throw ($Message.TerminatingError.NotAPositiveNumber -f $d)
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


# Todo: Change output to FileInfo @endowdly @low
function New-NavigationFile {
    <#
    .Synopsis
      Creates a new navigation database file.
    .Description
      Creates a home Entry and exports to a CSV file. 
      This is considered a 'bare' navigation file.
      Will not overwrite an existing file unless the Force switch is used.

      The home Entry is simply the user's Home directory, derived from the Home automatic variable.

      A navigation file is a CSV file that flat-packs Entry objects.
    .Example
      New-NavigationFile 

      Creates a new navigation file at the DefaultPath, which is normally '~/.gops', if it does not exist.
    .Example
      New-NavigationFile -Path $FilePath

      Assuming FilePath is a valid location and does not exist, creates a new navigation file. 
    .Example
      New-NavigationFile -Force

      Overwrites the navigation file, if it exists, at the DefaultPath with a bare navigation file.
    .Example
      Join-Path $HOME .gops2 | New-NavigationFile -Force

      Overwrites the navigation file, if it exists, at the input passed by `Join-Path`.
    .Inputs
      System.String 
    .Notes 
      string -> bool -> () 
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # Specifies a path to database file. Default: Module DefaultPath
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string] $Path = $GoPS.DefaultPath
        , 
        # Forces creation of a new navigation file. 
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
    .Example
      Get-DefaultNavigationFile

      The only way to use it.
    .Link 
      Set-DefaultNavigationFile
    .Outputs
      System.Management.Automation.PathInfo
    .Notes 
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
    .Example
      Set-DefaultNavigationFile $FilePath

      Sets the default navigation filelocation to FilePath, if it exists.
    .Example
      $FilePath | Set-DefaultNavigationFile

      Sets the default navigation filelocation to FilePath, if it exists.
    .Link 
      Get-DefaultNavigationFile
    .Inputs
      System.String
    .Notes
      string -> ()
    #>

    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'Low')]

    param (
        # Specifies a path to database file. 
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)] 
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path
    )

    process { 
    
        if ($PSCmdlet.ShouldProcess($Path, $Message.ShouldProcess.SetDefaultNavigationFile)) {
            if ($Path -eq $GoPS.DefaultPath) {
                return
            }

            $GoPS.DefaultPath = $Path

            Write-Verbose ($Message.Verbose.SetDefaultNavigationFile -f $Path)
        }
    }
}


# Review: Consider an Append switch parameter to add to a file @endowdly @low
function Export-NavigationEntry {
    <#
    .Synopsis
      Export an Entry object to a navigation file.
    .Description
      Export an Entry object to a navigation file.
      If a path is not given, defaults to the default navigation file.

      If no Entry objects are provided, exports the objects currently loaded in memory.
    .Example
      Export-NavigationEntry

      Will export the Entry objects in memory to the default navigation file path, if it exists.
    .Example
      Export-NavigationEntry -Path $FilePath

      Will export the Entry objects in memory to the path at FilePath, if it exists.
    .Example
      Get-NavigationEntry this that | Export-NavigationEntry 

      Will export the Entry objects with Token properties 'this' and 'that' to the default navifation file.
    .Example
      Get-NavigationEntry this that | Export-NavigationEntry -Path $FilePath

      Will export the Entry objects with Token properties 'this' and 'that' to the path at FilePath, if it exists.
    .Link
      Add-NavigationEntry
    .Link
      Get-NavigationEntry
    .Link
      Remove-NavigationEntry
    .Inputs
      Entry[]
    .Notes
      Entry[] -> string? -> ()
    #>

    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'Medium')]
    [Alias('Export-NavigationDatabase')]  # ! Deprecated

    param(
        # The Entry objects to export. Default: Entry objects in loaded Database
        [Parameter(ValueFromPipeline)]
        [Entry[]] $InputObject = $GoPS.Database.EntryList.ToArray()
        ,
        # Specifies a path to database file. Default: Module DefaultPath
        [Parameter(Position = 0)]
        [ValidateScript({ Assert-Path $_ })]
        [Alias('PSPath')]
        [string] $Path = $GoPS.DefaultPath
        ,
        [switch] $Append
    )

    begin {
        if ($MyInvocation.InvocationName -eq 'Export-NavigationDatabase') {
            Write-Warning $Message.Warning.ExportNavigationDatabase
        }
    }

    process { 
        <# * Why ForEach is not used on each incoming array:
            Inteded behavior is for the navigation file to be wholly replaced by the incoming Entry array.
            If you use ForEach on the array, you may only export the last Entry object in the array.
            I would rather only export the last array passed. #>

        if ($PSCmdlet.ShouldProcess($Path, $Message.ShouldProcess.ExportNavigationEntry)) {
            $InputObject |
                Export-Csv -Path $Path -NoTypeInformation -Append:$Append
        }
    }
}


# Review: Consider an Append switch parameter @endowdly @low
function Update-NavigationDatabase {
    <#
    .Synopsis
      Update the Database in memory with the contents of a navigation file.
    .Description 
      Update the Database in memory with the contents of a navigation file.
    .Example 
      Update-NavigationDatabase

      Will change the internal Database object to the Entry array contained in the default file, if valid.
    .Example 
      Update-NavigationDatabase -Path $FilePath

      Will change the internal Database object to the Entry array contained in the file at FilePath, if valid.
    .Example 
      Join-Path $Home .gops2 | Update-NavigationDatabase 

      Will change the internal Database object to the Entry array contained in the incoming path, if valid. 
    .Inputs
      System.String 
    .Notes 
      string -> ()

      The noun is correct. It is a little odd as the rest of its close functions deal with Entry objects.
      However, this is the only function provided that allws the user to affect the internal Database object.
    #>

    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'Low')]

    param(
        # Specifies a path to database file. Default: Module DefaultPath
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [Alias('PSPath')]
        [string[]] $Path = $GoPS.DefaultPath
    )

    begin {
        $ls = [List[Entry]] @() 
        # adds each item to a specified list
        $f = { 
            $ls, $null = $args
            [void] $ls.Add($_)
        } 

        # string -> Entry[]
        $g = {
            Import-NavigationFile $_ | ConvertFrom-Database
        }

        $x = New-Database
    }

    process { 
        if ($PSCmdlet.ShouldProcess($Path, $Message.ShouldProcess.UpdateNavigationDatabase)) { 
            $Path.ForEach($g).ForEach($f, $ls) 
        }
    }
    end { 
        $ls | Add-Entry $x
        
        $GoPS.Database = $x
    }
}


function Add-NavigationEntry {
    <#
    .Synopsis
      Adds an Entry object to the Database.
    .Description
      Adds an Entry object to the Database.

      Think of an Entry object like a bookmark.
      Each has a Token property and a JumpPath property. 
      The Token is the users chosen short name or bookmark name for each JumpPath.
      The JumpPath property is a directory in the file-system they likely visit often.

      The Database is an internal memory collection that validates and stores Entry objects.
      It does not allow Entry objects with duplicate Tokens.
      However, it will allow many Entry objects that point to the same JumpPath. 
      
      JumpPath can point to paths that do not yet exist.

      Returns the Entry object added unless the Silent switch parameter is used.
    .Example
      Add-NavigationEntry -Token docs -Path ~/Documents

      Adds an Entry with the Token property 'docs' pointing to the user's Documents directory.
    .Example
      Add-NavigationEntry -Token here

      Adds an Entry with the Token property 'here' pointing to the current working directory. 
    .Example
      Add-NavigationEntry -Token there -Path $there -Silent

      Adds an Entry with the Token property 'there' pointing to the path at there.
      Does return the Entry object created and added.
    .Link
      Get-NavigationEntry
    .Link
      Remove-NavigationEntry
    .Link
      Export-NavigationEntry
    .Outputs
      Entry

      Returns the Entry object added unless the Silent switch parameter is used.
    .Notes
      string -> string -> bool? -> Entry?
    #>

    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'Low')]
    [OutputType([Entry])]

    param(
        # Token to use.
        [Parameter(
            Position = 0,
            ValueFromPipelineByPropertyName)]
        [Alias(
            'Shortcut',
            'Bookmark')]
        [string] $Token
        ,
        # Jump path. Default: current working directory
        [Parameter(
            Position = 1,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [string] $JumpPath = $PWD
        ,
        # Do not emit the Entry object.
        [switch] $Silent
    )

    process {
        $isValidPath = Test-Path $JumpPath

        if (!$isValidPath) {
            Write-Warning ($Message.Warning.BadJumpPath -f $JumpPath) 
        }

        <# Done: IO.DirectoryInfo objects will not validate incomplete, unqualified paths @endowdly
            We don't want invalid paths to be ignored, so only change valid ones #> 
        $JumpPath = Invoke-Ternary $isValidPath { Convert-Path $JumpPath } { $JumpPath } 
        $msg = $Message.ShouldProcess.AddNavigationEntry -f $Token

        if ($PSCmdlet.ShouldProcess($JumpPath, $msg)) { 
            New-Entry -Token $Token -Path $JumpPath -OutVariable entry |
                Add-Entry $GoPS.Database 
        }
    }

    end { 
        if ($Silent.IsPresent) {
            return
        }

        $entry
    }
}

# Done: Tab-Completion on tokens with partial matching @endowdly
function Get-NavigationEntry {
    <#
    .Synopsis 
      Returns Entry objects filtered by token strings.
    .Description
      Returns Entry objects in the loaded Database or from specified files.

      Accepts path names of navigation files as input or from the Path parameter.
      Path strings can be wildcarded.

      If Path is not used or no input is received, returns Entry objects from the loaded Database object. 

      Filters Entry objects by Token property.
      Filtering strings can be entered by the Token parameter or by remaining arguments.
      Token filtering strings can be wildcarded.
    .Example 
      Get-NavigationEntry -Token 'this', 'that', 'theOther'

      Get Entry objects in the currently loaded Database. 
      Returns Entry objects with Token properties 'this', 'that', or 'theOther' if they exist.
    .Example 
      Get-NavigationEntry this that theOther
    
      Get Entry objects in the currently loaded Database by remaining arguments.
      Returns Entry objects with Token properties 'this', 'that', or 'theOther' if they exist.
    .Example
      Get-NavigationEntry git* 
    
      Get Entry objects in the currently loaded Database by wildcarded Token.
      Returns all Entry objects with Token properties like 'git*' if they exist.
    .Example 
      Get-NavigationEntry -Path ~/.gops2

      Get Entry objects in specific files.
      Returns all Entry objects in the given paths if they are valid navigation files.
    .Example 
      '~/.gops3', '~/.gops2' | Get-NavigationEntry 

      Get Entry objects in specific files from the pipeline.
      Returns all Entry objects in the given paths if they are valid navigation files.
    .Example 
      '~/.gops*' | Get-NavigationEntry

      Get Entry objects in specific files by wildcards from the pipeline
      Returns all Entry objects in the given paths if they are valid navigation files.
    .Example 
      Get-NavigationEntry -Path ~/.gops*

      Get Entry objects in specific files by wildcards.
      Returns all Entry objects in the given paths if they are valid navigation files.
    .Example 
      Get-NavigationEntry -Path ~/.gops* -Token git*

      Get Entry objects in specific files by wildcards filtered by Token.
      Returns all Entry objects in the given paths with Token properties like git* if they are valid navigation files and the Entry objects with the specified Token properties exist.

      Similar for pipelined paths.
    .Link
      Add-NavigationEntry
    .Link
      Remove-NavigationEntry
    .Link
      Export-NavigationEntry
    .Inputs
      System.String[]
    .Outputs
      Entry[], System.String[]

      Returns an Entry array.
      Returns a string array if the JumpPathOnly parameter is used.
    .Notes
      string[] -> string[] -> bool -> Entry[]? 
      string[] -> string[] -> bool -> string[]? 
    #>

    [CmdletBinding()] 
    [OutputType(
        [Entry[]],
        [string[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    
    param( 
        # Specifies a path to a database file. Default: Module DefaultPath
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateScript({ Assert-Path $_ })]
        [string[]] $Path = $GoPS.DefaultPath
        ,
        # The tokens to fetch from the database. Default: '*'
        [Parameter(
            Position = 0,
            ValueFromRemainingArguments)]
        [ArgumentCompleter({ 
            param ($cmdName, $paramName, $wordToComplete)

            (Get-NavigationEntry).Token.Where{ $_ -like "${wordToComplete}*" } })]
        [string[]] $Token = '*'
        ,
        # Returns the jump path only.
        [Alias(
            'PathOnly',
            'ValueOnly')]
        [switch] $JumpPathOnly
    )

    begin {
        $f = {
            $currentToken = $_
            $p = { $_.Token -like $currentToken }

            $x.Where($p)
        }
        $g = {
            process { 
                Convert-Path $_ |
                ForEach-Object {
                    Import-NavigationFile $_ |
                    ConvertFrom-Database |
                    ForEach-Object { [void] $x.Add($_) } }
            } 
        }
        $x = [List[Entry]] @()
        $y = [List[Entry]] @()
    }

    process {
        if ($PSBoundParameters.ContainsKey('Path')) {
            [void] $Path.ForEach($g)
        }
        else {
            $GoPS.Database |
                ConvertFrom-Database | 
                ForEach-Object { $x.Add($_) } 
        } 

        [void] $Token.ForEach($f).ForEach{ $y.Add($_) }
    }

    end { 
        Invoke-Ternary $JumpPathOnly.IsPresent { $y.ToArray().Path } { $y.ToArray() } 
    }
}


# Done: Tab-Completion on tokens with partial matching @endowdly 
function Remove-NavigationEntry {
    <#
    .Synopsis
      Removes an Entry from the navigation database.
    .Description
      Removes an Entry from the navigation database.

      The function accepts Token arguments on the pipeline, from the parameter, and from remaining arguments.
      If a Token property does not exist on any Entry objects, does nothing and continues.

      Unlike Get-NavigationEntry, Remove- does not accept wildcard Tokens.
      This is intentional in order to ensure that incorrect tokens are not removed by accident.
      Remove- does accept Tokens returned from Get-NavigationEntry.

      Returns the remaining Entry array in the database if the Silent parameter switch is not used. 
    .Example
      Remove-NavigationEntry -Token 'this', 'that'

      Removes Entry objects with Tokens this and that, if they exist.
    .Example
      Remove-NavigationEntry this that

      Removes Entry objects with Tokens this and that, if they exist.
    .Example
      Get-NavigationEntry this that | Remove-NavigationEntry 

      Removes Entry objects with Tokens this and that, if they exist.
    .Link
      Get-NavigationEntry
    .Link
      Add-NavigationEntry
    .Link
      Export-NavigationEntry 
    .Notes
      string[] -> bool -> Database?
    #>

    [CmdletBinding()]
    [OutputType([Entry[]])]

    param(
        # The tokens to remove from the Database.
        [Parameter(
            ValueFromPipeline,
            ValueFromRemainingArguments,
            ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({ 
            param ($cmdName, $paramName, $wordToComplete)

            (Get-NavigationEntry).Token.Where{ $_ -like "${wordToComplete}*" } })]
        [string[]] $Token
        , 
        # Do not return a Database object.
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
        $Token.ForEach($f)
    }

    end {
        if ($Silent.IsPresent) { 
            return
        }

        $GoPS.Database.EntryList.ToArray()
    }
}


# Done: Partial matching on tokens and available directories @endowdly
function Invoke-GoPS {
    <#
    .Synopsis
      Jumps to a token.
    .Description
      Invoke-GoPS is the primary use point for the module.

      Because Invoke-GoPS handles jumping to paths stored in the Database, Invoke-GoPS can also ease other console navigation.
      Each jump or directory visited with 'Invoke-GoPS' command is stored in an internal Path Stack.
      This stack allows to user to quickly jump back a number of directories with the Invoke-Back function. 
      Using the -Last switch will allow the user to jump back and forth to the last visited directory.
      This location is not popped off the stack and not recorded in the stack. 

      Back and Last are provided in the module as convenience functions.

      Invoke-GoPS accepts input from Get-NavigationEntry.
    .Example
      Invoke-GoPS home 

      Sets the location to the home Entry and stores locations and jumps in the GoPS history.
    .Example
      Get-NavigationEntry home | Invoke-Gops

      Sets the location to the home Entry and stores locations and jumps in the GoPS history.
    .Example
      Invoke-Gops -Last

      Sets the location to the last visited directory. If there is no previous location, does nothing.
    .Example
      Invoke-Gops -Back 

      Sets the location to the last visited directory jumped to by GoPS. 
      If there is no previous location, emits an error.
    .Link
      Invoke-Back
    .Link
      Invoke-Last
    .Inputs 
      System.String
    .Notes 
      string -> ()
      int -> ()
    #>

    [CmdletBinding()]

    param (
        # The Token to try and jump to.
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({ 
            param ($cmdName, $paramName, $wordToComplete)

            (Get-NavigationEntry).Token + (Get-ChildItem -Directory $wordToComplete* ).Name |
                Where-Object { $_ -like "${wordToComplete}*" } })]
        [Alias('Token')]
        [string] $Path
        ,
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
    .Synopsis
      Jump backwards in the GopSStack. 
    .Description
      Calls Invoke-GoPS with the -Back switch enabled. 
      Back only works with paths reach with GoPS.

      Invoke-Back pops the last directory off the GoPSStack.
    .Example
      Invoke-Back

      Jumps back to the last visited GoPS directory if available.
    .Example
      Invoke-Back 3

      Jumps back to the third last visited GoPS directory if available.
    .Link
      Invoke-GoPS
    .Link
      Get-GoPSStack
    .Notes
      int? -> ()
    #>

    # The number of back jumps to make. 
    param (
        [ValidateScript({ Assert-PositiveNumber $_ })]
        [int] $n = 1
    )

    Invoke-GoPS -Back -BackDepth $n
}


function Invoke-Last {
    <# 
    .Synopsis
      Jump to the last visited directory.
    .Description
      Jump to the last visited directory.

      Calls Invoke-GoPS with the -Last switch enabled. 
      Last only works with paths reached with GoPS.
      
      Does not affect the GoPSStack, but does affect the JumpHistory.
    .Example
      Invoke-Last

      Jumps to the last visited GoPS directory, if available.
    .Link
      Invoke-GoPS
    .Link
      Get-GoPSStack
    .Notes
      () -> ()
    #>

    param ()

    Invoke-GoPS -Last
}


function Get-GoPSStack {
    <#
    .Synopsis
      Displays the current contents of the module PathStack.
    .Description
      Displays the current contents of the module PathStack.

      Any directory change caused by a GoPS function is pushed by the PathStack.
      The stack will pop with Invoke-Back.
    .Example
      Get-GoPSStack

      Returns the GoPSStack.
    .Link
      Invoke-GoPS
    .Link 
      Get-JumpHistory
    .Notes
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
    .Example
      Get-JumpHistory

      Returns the JumpHistory of the GoPS module.
    .Link
      Invoke-GoPS
    .Link
      Get-GoPSStack
    .Notes
      () -> JumpStack[]
    #>

    (Get-Location -StackName GoPS).ToArray() |
        ForEach-Object Path |
        ForEach-Object { $_ -as [System.IO.DirectoryInfo] } | 
        New-JumpStack
}


# Done: Up needs some refactoring -> cmdlet w/ArgCompleter @endowdly
function Invoke-Up {
    <#
    .Synopsis
      Traverse up in a path tree easily, accepts paths, wildcard strings, or integers.
    .Description
      Traverse up in a path tree easily, accepts paths, wildcard strings, or integers.
      Accepts integers as the number of directories to move up.
      Accepts paths to move up to a matching path in a parent directory.
      Accepts wildcard strings as the same.

      Features tab-completion of all parent directories to the provider root.
      Does nothing on invalid input.

      Derived from up by Shannon Moeller and endowdly's work on the fish port. 
    .Example
      Invoke-Up

      Sets the location of the current working directory to the parent directory, if available.
    .Example
      Invoke-Up 3

      Sets the location of the current working directory to the third-level parent directory, if available.
    .Example
      Invoke-Up Use*

      Sets the location of the current working directory to the first parent directory matching Use*, if available.
      In this case, would like set the current location to `C:\Users\`.
    .Notes
      obj -> ()
    #>

    [CmdletBinding()]

    param (
        # This object can be an integer or a string
        [Parameter(Position = 0)]
        [ArgumentCompleter({
            param ($cmdName, $paramName, $wordToComplete, $Ast, $Fbp)

            $here = $p = $pwd
            $root = Convert-Path /
            $ls =
                while ($p -ne $root) {
                    Split-Path $here -OutVariable here |
                    Split-Path -Leaf -OutVariable p 
                }

            $ls.Where{ $_ -like "${wordToComplete}*" } })]
        $Value
    )
    
    <# Note: PWD is returned as a PathInfo object.
      It is normally safely consumed but all -Location Cmdlets.
      However, the internal function Push-Path cannot handle PathInfo objects.
      So, get the strings. #> 
    
    $ProviderPathRoot = Convert-Path /


    function UpDir ($parent, $target) {

        if ($parent -eq $ProviderPathRoot) { 
            return $target
        }

        $p = Split-Path $parent
        $a = Split-Path $p -Leaf
        $b = $target

        if (!$a -or !$b) {
            return $PWD.Path
        }

        if ($a -like $b) {
            return $p
        }

        UpDir $p $target
    }

    function UpNum ($parent, $index) {
        if ($null -eq $parent -or $null -eq $index) {
            return $PWD.Path
        }

        if ($index -le 0) {
           return $PWD.Path
        }

        do {
            $parent = Split-Path $parent
            $index--
        } while ($index -gt 0)
        
        $parent
    }

    $Up = Convert-Path .. 

    switch ($Value) {
        $null {
            Push-Path $Up
            break }

        { $_ -is [int] } {
            $temp = UpNum $PWD $Value

            if (Test-Path $temp) {
                Push-Path $temp
            }

            break }

        default { 
            if (Test-Path $Value) {
                Push-Path $Value

                break
            }

            $temp = UpDir $PWD.Path $Value

            if (Test-Path $temp) {
                Push-Path $temp

                break
            } }
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
    'Export-NavigationEntry'
    'Remove-NavigationEntry'
    'Invoke-GoPS'
    'Invoke-Back'
    'Invoke-Last'
    'Update-NavigationDatabase'
    # 'Import-NavigationFile'

    'Get-GoPSStack'
    'Get-JumpHistory'

    'Invoke-Up'
)

# This calls Set-Alias internally
$Config.CommandAlias.GetEnumerator().ForEach($setAlias)

$Aliases = @(
    ($Config.CommandAlias.Values -ne '')

    'Export-NavigationDatabase'
)

Update-NavigationDatabase
Export-ModuleMember -Function $Functions -Alias $Aliases

#endregion
