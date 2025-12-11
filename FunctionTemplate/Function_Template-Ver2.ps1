function Invoke-SomethingElse {
    <#
    .SYNOPSIS
        Short description of what the function does.
    .DESCRIPTION
        Detailed description including what permissions are needed or dependencies.
    .PARAMETER TargetName
        Description of the first parameter.
    .PARAMETER ComputerName
        The target computer(s). Accepts pipeline input.
    .EXAMPLE
        Invoke-SomethingElse -TargetName "Config1" -ComputerName "Server01" -Verbose
    .EXAMPLE
        "Server01", "Server02" | Invoke-SomethingElse -TargetName "Config1" -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        # Primary input data
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetName,
        
        # Target computers (Accepts Pipeline input)
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,
        
        # Optional Credential
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )

    Begin {
        # Code here runs once before processing any items.
        # Useful for setting up connections or logging variables.
        Write-Verbose "Starting function execution..."
    }

    Process {
        # This block runs once for every item passed via pipeline
        foreach ($Computer in $ComputerName) {
            
            # The 'ShouldProcess' check allows -WhatIf and -Confirm usage
            # It prints: "What if: Performing operation 'TargetName' on target 'Computer'"
            if ($PSCmdlet.ShouldProcess($Computer, "Process item '$TargetName'")) {
                
                try {
                    Write-Verbose "Processing computer: $Computer"
                    
                    # --- YOUR CODE LOGIC HERE ---
                    # Simulate work
                    # Invoke-Command -ComputerName $Computer -ScriptBlock {...}
                    
                    # Return an object (Best practice)
                    [PSCustomObject]@{
                        ComputerName = $Computer
                        Target       = $TargetName
                        Status       = "Success"
                        TimeStamp    = Get-Date
                    }
                }
                catch {
                    Write-Error "Failed to process $Computer. Error: $_"
                }
            }
        }
    }

    End {
        # Code here runs once after all items are processed.
        # Useful for cleanup or final summaries.
        Write-Verbose "Function execution completed."
    }
}
