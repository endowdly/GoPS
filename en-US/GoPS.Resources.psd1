@{
    ShouldProcess    = @{
        ExportNavigationEntry    = 'Exporting navigation entry -> {0}'
        SetDefaultNavigationFile = 'Setting as default path for GoPS'
        UpdateNavigationDatabase = 'Update navigation database with file -> {0}'
        NewNavigationFile        = 'Creating new navigation database'
    }

    Error            = @{
        AddEntry = 'Cannot add duplicate token; token already exists -> {0}'
    }

    TerminatingError = @{
        StackDepthExceeded = '{0} exceeds directory stack depth of {1}!'
        NavFileInvalid     = 'Invalid NavFile Path -> {0}'
    }

    Warning          = @{
        BadJumpPath              = 'JumpPath does not currently exist -> {0}'
        NoNavFile                = 'There is no NavFile at {0}. You should run ''New-NavigationFile'' :)'
        ExportNavigationDatabase = 'Export-NavigationDatabase is deprecated. Use Export-NavigationEntry instead.'
    } 

    Verbose          = @{
        SetDefaultNavigationFile = 'Set default NavFile Path -> {0}'
        NewNavigationFile        = 'New NavFile created -> {0}'
    } 
}