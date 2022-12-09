#author: Richard Easton
#description: Function Template with Mandatory parameters
#usage: get-somethingelse -somethingelse1 "Hello World!" -Computename $env:ComputerName -verbose 
#       Wrapping the workhorse part of the function in the $PSCmdlet.ShouldProcess if statement 
#       gives you access to -Whatif -Verbose -Debug etc etc (Common functions).
#
#       Try removing the -Computername $env:computername to see what happens ;)


function get-somethingelse {
  [cmdletbinding(SupportsShouldProcess)]
  param
  (
    # add parameter that is mandatory
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$somethingelse1,
    
    # add parameters for computername (mandatory) and credentials:
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $ComputerName,
    
    [PSCredential]
    $somethingelse2
  )
    if ($PSCmdlet.ShouldProcess($computername, $workspaceId)) {
        write-host "$somethingelse1: from $ComputerName"
    }
}

#example
get-somethingelse -somethingelse1 "hello world" -ComputerName $env:COMPUTERNAME -verbose | Out-Null
