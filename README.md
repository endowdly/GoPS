# GoPS

This is pretty straight forward file system jumper.
It uses a database file (that is also loaded into session memory) to jump around with shortcut tokens.  
Database files can be entered explicity for each command, but to ease use, the default file path can also be set.
**Features tab completion for tokens**.

## Usage

Jumper

``` plaintext
Invoke-GoPS [[-Path] <String>] [-DatabasePath <String>] [-Back] [-BackDepth <Int32>] [<CommonParameters>]

Back [[-i] <Int>]
```

Manage Database

``` plaintext
Add-NavigationEnty [-Path <String>] [[-JumpPath] <String>] [[-Token] <String>] [-Validate] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]

Get-NavigationEntry [-Path <String>] [[-Token] <String[]>] [-JumpPathOnly] [<CommonParameters>]

Remove-NavigationEntry [-Path <String>] [[-Token] <String[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

Manage the database file

``` plaintext
New-NavigationFile [[-Path] <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]

Set-DefaultNavigationFile [[-Path] <string>] [-WhatIf] [-Confirm]  [<CommonParameters>]

Get-DefaultNavigationFile
```

Aliases

``` plaintext
CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Alias           AddGo -> Add-NavigationEnty                        0.0        GoPS
Alias           GetGo -> Get-NavigationEntry                       0.0        GoPS
Alias           Go -> Invoke-GoPS                                  0.0        GoPS
Alias           RmGo -> Remove-NavigationEntry                     0.0        GoPS

```

Examples
``` powershell
# Jump around
Go home
Go -Back 2
back
back 3

# Manage database
AddGo home $home
AddGo do* $home/Documents
GetGo home this that
GetGo -ValueOnly
GetGo here | RmGo
RmGo home

# Manage Files
# On module import, set the default path
Import-Module GoPS -Argument $YourDefaultPath

# Otherwise
New-NavigationFile $ADifferentPath
Set-DefaultNavigationFile $ADifferentPath
Get-DefaultNavigationFile
```

## Install

Clone this repository, unzip, and insall into your `ModulePath`.