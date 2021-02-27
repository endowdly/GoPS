# GoPS

This is pretty straight forward file system jumper.

Store often-visited paths as tokens and jump to them easily with the `go` command.
Things like `go gd` and `go home` or `go ~` are now easily possible.

The user can save their tokens and paths to a file with the `Export-NavigationDatabase` command.

GoPS now includes simple internal stack management.
Any GoPS function that alters the path will store visited locations in two different collections: one storing all paths visited, and the other storing a path stack.
The internal path stack will allow users to recall which paths were visited.
They can be popped with the `back` command.
Call `Get-GoPSStack` to view the path stack.
User can call `back` repeatedly to pop backwards one directory at a time, or use a numeric argument to jump backwards several directories at once.

On a similar utility level, call `last` to jump back and forth between the last visited directory.
The last path visited is _not_ stored on the stack, so it will not disrupt `back` moves.
The jumps to last are recorded in the complete jump history.

The user can call `Get-JumpHistory` to see all paths visited with a GoPS command.

Another new addition is a small port of `up`, a command written for Unix shells by Shannon Moeller.
I had helped port it to the fish shell and I've used that code to write a working solution for PowerShell.
Up is insanely useful to avoid spamming `cd ..`.
This instance of `up` is integrated with GoPS and its locations get stored on the path stack and history.

GoPS has been updated to **version 2.0**.
The major difference is now most Token and JumpPath management is handled internally (in memory) with data classes.
**GoPS no longer automatically reads/writes to a file.**
Use `Update-NavigationDatabase` to read a set of JumpPaths and Tokens in from a file.
Use `Export-NavigationDatabase` to write your current set of JumpPaths and Tokens to a file.

## Managing the data file

The data file is stored as a simple, flat csv.
It defaults to `$HOME/.gops`.
The file's default location can be set on module load or with a function.
This default location is not persistent and only lasts with the session.
The user can, but should not, manually edit this file.
It is better to let PowerShell validate the paths.

### Default file location

```powershell
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
Update-NavigationDatabase [-Path <string>]  # Replaces the data base with data from the path given or the default location
```

## Managing the database

You do not need to load or export to a file to manage a database.
However, the database only lasts for the session and its data is not persistent.
Use `Export-NavigationDatabase` to save your JumpPaths.

### Adding entries

```powershell
Add-NavigationEntry [-Token] <string> [-Path] <string>
addgo <string> <string>
```

### Getting entries

```powershell
Get-NavigationEntry [[-Token] <string[]>]
getgo [<string[]>]
```

It's important to note that `getgo` accepts remaining arguments for tokens.
Things like `getgo this that theOther` are possible.
Wildcard tokens are accepted.
Features tab completion for current tokens.
If you don't give `getgo` arguments, it'll just return the current contents of the database.

### Removing entires

```powershell
Remove-NavigationEntry [[-Token] <string[]>]
rmgo [<string[]>]
```

`rmgo` functions like `getgo`.

### Jumping

Ah, the important stuff.

### Going forward

```powershell
Invoke-GoPS [[-Path] <string>]  # Path can be -Token too
go [<string>]
```

`go` jumps to tokens, but will also go to valid paths.
It accept tab completion for current tokens, so you will have to type a qualified path.
NOTE: jumping to a path seems to be slightly bugged right now.
It probably has to do with my implementation of using DirectoryInfo as a validator.
If you're having trouble, use fully-qualified paths for now.

### Going back

```powershell
Invoke-Back [[-n] <int>]
back [<int>]

Invoke-Last
last
```

### Going up

```powershell
Invoke-Up [[-Value] <Object>]  # accepts wildcard strings, or numbers
up <object>
```

Similar to `back` and `last`, but only goes up a directory tree.

## Install

<!-- markdownlint-disable MD029 -->

1. Go to a User-level `ModulePath`

```powershell
cd ($env:PSModulePath -split ';')[0]   # usually works
```

2. Clone this repository: `git clone https://github.com/endowdly/GoPS.git`
