@{
    ShouldProcess    = @{
        SetDefaultNavigationFile = 'Setting as default path for GoPs'
        NewNavigationFile        = 'Creating new navigation database'
        AddNavigationEntry       = 'Adding: {0} -> {1}' 
        RemoveNavigationEntry    = 'Removing from database'
    }

    TerminatingError = @{
        AddNavEntryDuplicate = 'Navigation entry contains duplicate {0}: {1}'
        AddNavTokenDuplicate = 'Navigation entry contains duplicate Token: {0}'
        StackDepthExceeded   = '{0} exceeds directory stack depth!'
        NavFileInvalid       = '{0}: not a valid nav file!' 
    }

    Warning          = @{
        BadJumpPath = 'JumpPath {0} does not currently exist!' 
    }

    Verbose          = @{
        BadJumpPathValidated = 'Did not create entry; Validate is True and {0} does not exist.'
    } 
}