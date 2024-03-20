@{
    RootModule        = 'runner.utilities.psm1'
    
    # Version of the module. Use this to track when the module was updated.
    ModuleVersion     = '0.0.1'
    
    Description       = 'Runner Utilities'
    Author            = 'Shinchan Nohara'
    FunctionsToExport = @(
        'Get-Script'
    )
    RequiredModules   = @(        
    )
    PrivateData       = @{
    }
}