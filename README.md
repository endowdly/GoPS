# GoPS

This is pretty straight forward file system jumper.

A suite of commands make navigating the file system on the command-line easy.
Bookmark-like Entry objects allow jumping to directories, so things like `go home` or `go ~` are easily possible!
Hopping back and forth between two working directories is a single command away.
Exploring the jump history is streamlined and easier to navigate.

A configurable, intuitive module with helpful commands allow:

- Easily retrieving and saving entries to/from files
- Easily searching for bookmark entries in memory or in files
- Jumping to bookmark entires in memory or in files
- Viewing and jumping into your directory history
- Customizing the commands that make it all happen in a simple configuration file

## Getting Started

### Installing with PowerShellGet

The most straightfoward way!

```powershell
Install-Module -Name GoPS
``` 

### Installing with scoop

```powershell
# Name the bucket whatever you'd like
scoop bucket add endowdly https://github.com/endowdly/endo-scoop/
scoop install gops
```

### Installing manually with git

```powershell
# Go to a user-level module directory
cd ($env:PSModulePath -split ';')[0]   # usually works 

# Clone the repo with git
git clone https://github.com/endowdly/GoPS.git

```

### Import

```powershell
Import-Module GoPS
```

On first import, you should see a warning.
If the default file location is fine, you can simply run `New-NavigationFile` to create a file with a default bookmark, `home`.

## Managing the data file

The data file is stored as a simple, flat csv.
It defaults to `$HOME/.gops`.
The file's default location is normally set in the config file, `GoPS.Config.psd1`.
If the config file is missing or removed manually, the file's default location is set on module load.

The user can, but should not, manually edit this file.
It is better to let PowerShell validate the paths.

### Default file location

Persistent!

```powershell
# In GoPS.Config.psd1
@{
    CommandAlias = @{ <# <hashtable> #> }
    DefaultNavigationFile = '<string>' # change this!
}
```

Not persistent -- only lasts for each session!

```powershell
# If there is no config or you delete it!
Import-Module GoPS -ArgumentList <string>  # This changes the default location for the module on load

Set-DefaultNavigationFile -Path <string>  # This changes the default location for the module after load
```

### Create a new file

```powershell
New-NavigationFile [-Path <string>]  # This uses the default location if none is given
```

### Change the file

```powershell
Export-NavigationDatabase [-Path <string>]  # Exports whatever is in getgo to the path provided or default location
```

### Import from the file

```powershell
Update-NavigationDatabase [-Path <string>]  # Replaces the database with data from the path given or the default location
```

## Managing the database

You do not need to load or export to a file to manage a database.
However, the database only lasts for the session and its data is not persistent.
Use `Export-NavigationEntry` to save your bookmark Entries.

### Adding entries

```powershell
Add-NavigationEntry [-Token] <string> [-Path] <string>
```

### Getting entries

```powershell
Get-NavigationEntry [[-Token] <string[]>]
```

It's important to note that `Get-NavigationEntry` accepts remaining arguments for tokens.
Things like `Get-NavigationEntry this that theOther` are possible.
Wildcard tokens are accepted.
Features tab completion for current tokens.
If you don't give `Get-NavigationEntry` arguments, it'll just return the current contents of the database.

### Removing entries

```powershell
Remove-NavigationEntry [[-Token] <string[]>]
rmgo [<string[]>]
```

`Remove-NavigationEntry` functions like `Get-NavigationEntry`.

### Jumping

Ah, the important stuff.

### Going forward

```powershell
Invoke-GoPS [[-Path] <string>]  # Path can be -Token too
```

`Invoke-GoPS` jumps to tokens, but will also go to valid paths.
It accepts tab completion for current tokens.

### Going back

```powershell
Invoke-Back [[-n] <int>]

Invoke-Last
```

You can jump back into the stack of places visited with GoPS functions with `Invoke-Back`.
You can jump back and forth between the last visited with `Invoke-Last`.

`Invoke-Back` will pop the GoPS stack and reduce the stack by the number of directories popped.
The directory will remain in the JumpHistory.
`Invoke-Last`, notably, does not push directories it jumps between onto the GoPS stack.
It does however, affect the history.

### Going up

```powershell
Invoke-Up [[-Value] <Object>]  # accepts wildcard strings, or numbers
```

Similar to `back` and `last`, but only goes up a directory tree.
Tab completion works here, giving you all the parent directories.

## Configuring command aliases

There currently is no way to set module aliases on the command-line with a module function.
That feature is coming, but for now you can edit a simple config file!
The advantage to this simple file is your changes are persistent!

Pop open the `GoPS.Config.psd1` file in Notepad or Visual Studio Code.
You should see this:

```powershell
@{
    
    CommandAlias = @{
        # Command                   = Alias
        'Add-NavigationEntry'       = 'addgo'
        'Export-NavigationEntry'    = ''
        'Get-DefaultNavigationFile' = ''
        'Get-GoPSStack'             = '' 
        'Get-JumpHistory'           = '' 
        'Get-NavigationEntry'       = 'getgo' 
        'Invoke-Back'               = 'back'
        'Invoke-GoPS'               = 'go'
        'Invoke-Last'               = 'last'
        'Invoke-Up'                 = 'up'
        'New-NavigationFile'        = '' 
        'Remove-NavigationEntry'    = 'rmgo' 
        'Set-DefaultNavigationFile' = ''
        'Update-NavigationDatabase' = ''
    }

    DefaultNavigationFile = '~/.gops' 
}
```

I hope that is straight-forward.
Change the alias to whatever you want for whichever command you see.
When you load the module, your user set alias will be available for you to use.
If you've loaded the module and then changed the file, reload the module with: `Import-Module GoPS -Force`.

This should allow users to deconflict command conflicts, like if you used `go` for go-lang.
For example, the user can use `jump` or `j` for `Invoke-GoPS` instead by simply changing the value!

## Advanced

I have three different nav files (for some reason).
Let us imagine they are named `.gops`, `.gops1`, and `.gops2`.
I want to find an obscure git repo I made.
I know it is name xanadu at the end, and I don't know which file it is in.
When I find it, I want to jump to it!

```powershell
Join-Path ~ .gops* |
    Get-ChildItem |
    Convert-Path |
    Get-NavigationEntry *xan* |
    Invoke-GoPS 

# Yeah, this works (⌐■_■)
```

I want to add a bookmark Entry but also export it to a different navigation file.
Assume .gops2 exists already (if it doesn't `New-NavigationFile ...`).

```powershell
# Remember! This overwrites the file! 
Add-NavigationEntry offside '~/Google Drive/SomeRep/' | Export-NavigationEntry -Path ~/.gops2 
```

I think an append feature should be implemented for this, don't you?
Cool, because I did that in 2.2.1!

## Finding the module

If you need help finding the module because scoop tucks it away...

```powershell
Get-Module GoPS | Select-Object Path | Split-Path | Set-Location
```