@{
    ShouldProcess    = @{
        ExportNavigationEntry    = 'Exporting navigation entry to target'
        SetDefaultNavigationFile = 'Setting as default path for GoPS'
        UpdateNavigationDatabase = 'Update navigation database from target'
        NewNavigationFile        = 'Creating new navigation file'
        AddNavigationEntry       = 'Adding Entry with Token {0} for target'
    }

    Error            = @{
        AddEntry = 'Cannot add duplicate token; token already exists -> {0}'
    }

    TerminatingError = @{
        StackDepthExceeded = '{0} exceeds directory stack depth of {1}!'
        NavFileInvalid     = 'Invalid NavFile Path -> {0}'
        NotANumber         = '{0} is not a number!'
        NotAPositiveNumber = '{0} is not a positive number!'
        InvalidConfig = 'Not valid config properties -> {0}. Valid properties are: {1}'
        InvalidCommandAlias = @'
Not valid config CommandAlias -> {0}.
Valid properties are:
{1}
'@
    }

    Warning          = @{
        BadJumpPath              = 'JumpPath does not currently exist -> {0}'
        NoNavFile                = 'There is no NavFile at {0}. You should run ''New-NavigationFile'' :)'
        ExportNavigationDatabase = 'Export-NavigationDatabase is deprecated. Use Export-NavigationEntry instead.'
        ConfigFileNotFound = 'Config file not found; using default module config!'
    } 

    Verbose          = @{
        SetDefaultNavigationFile = 'Set default NavFile Path -> {0}'
        NewNavigationFile        = 'New NavFile created -> {0}'
    } 
}