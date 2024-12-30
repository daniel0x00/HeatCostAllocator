function Get-HCAUser {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $UserUrl,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $JWTToken
    )

    begin { }
    process {
        
    }
    end { }
}