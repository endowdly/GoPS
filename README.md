# GoPS

This is pretty straight forward file system jumper.

Store often-visited paths as tokens and jump to them easily with the `go` command.
Things like `go gd` and `go home` or `go ~` are now easily possible.

The user can save their jumppaths to file with the `Export-NavigationDatabase` command.

GoPS now includes simple internal stack managment.
Any function that alters the path will store visited locations in two different stacks: one storing all paths visited, and the other storing a path stack similar to the Provider stack accessible with `Get-`, `Push-` and `Pop-Location`.
The internal path stack will allow users to easily recall which paths were visited that can be popped with the `back` command.
Call `Get-GoPSStack` to view stack.
User can call `back` repeatedly to pop backwards one directory at a time, or use a numeric argument to jump backwards several directories.

In a similiar utility level, users can call `last` to jump back and forth between the last visited directory.
The last path visited is _not_ stored on the stack, so it will not disrupt `back` moves.
The jumps to last are recorded in the complete jump history.

The user can call `Get-JumpHistory` to see all paths visited with a GoPS command.

Another new addition is a small port of Up, a command written for unix shells by Shannon Moeller.
I had helped port it to the fish shell and I've used that code to write a working solution for PowerShell.
Up is insanley useful and will bring up the path tree instead of spamming `cd ..`.
This instance of `up` is fully integrated with GoPS and its locations get stored on the path stack and history.

GoPS has been updated to **version 2.0**.
The major difference is now most Token and JumpPath management is handled internally (in memory) with data classes.
**GoPS no longer automatically reads/writes to a file.**
Use `Update-NavigationDatabase` to read a set of JumpPaths and Tokens in from a file.
Use `Export-NavigationDatabase` to write your current set of JumpPaths and Tokens to a file.

## Managing the data file

The file is stored as a simple, flat csv.
It defaults to `$HOME/.gops`.
The files default location can be set on module load or with a function.
This default location is not persistant and only lasts with the sesson.
The user can, but should not, manually edit this file.
It is better to let PowerShell validate the paths.

### Default file location

`Import-Module GoPS -ArgumentList <string>  # This changes the default location for the module on load`
`Set-DefaultNavigationFile -Path <string>  # This changes the default location for the module after load`

### Create a new file

`New-NavigationFile [-Path <string>]  # This uses the default location if none is given`

### Change the file

`Export-NavigationDatabase [-Path <string>]  # Exports whatever is in getgo to the path provided or default location`

### Import from the file

`Update-NavigationDatabase [-Path <string>]  # Reads from the file and replaces the database in memory`

## Managing the database

You do not need to load or export to a file to manage a database.
However, the database only lasts for you session and its data is not persistant.
Use `Export-NavigationDatabase` to save your JumpPaths.

### Adding entries

`Add-NavigationEntry [-Token] <string> [-Path] <string>`
`addgo <string> <string>`

### Getting entries

`Get-NavigationEntry [[-Token] <string[]>]`
`getgo [<string[]>]`

It's important to note that `getgo` accepts remaining objects for tokens.
Things like `getgo this that theOther` are possible.
Wildcard tokens are accepted.
Features tab completion for current tokens.
If you don't give `getgo` arguments, it'll just return the current contents of the database.

### Removing entires

`Remove-NavigationEntry [[-Token] <string[]>]`
`rmgo [<string[]>]`

`rmgo` functions very similiarly to `getgo`.

### Jumping

Ah, the important stuff.

### Going foward

`Invoke-GoPS [[-Path] <string>]  # Path can be -Token too`
`go [<string>]`

`go` jumps to tokens, but will also goto valid paths.
It accept tab completion for current tokens, so you will have to type a qualified path.
NOTE: jumping to a path seems to be slightly bugged right now.
It probably has to do with my implemenation of using DirectoryInfo as a validator.

### Going back

`Invoke-Back [[-n] <int>]`
`back [<int>]`

`Invoke-Last`
`last`

### Going up

`Invoke-Up [[-Value] <Object>]  # accepts wildcard strings, or numbers`
`up <object>`

Similar to `back` and `last`, but only goes up a directory tree.

## Install

Clone this repository, unzip, and install into your `ModulePath`.
