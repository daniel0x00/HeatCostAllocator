function Get-HCAConsumption {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $ConsumptionUrl,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $JWTToken,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Cuid,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidatePattern("^(19|20)\d{2}$")]
        [string] $BillingPeriodYear = (Get-Date).Year.ToString(),

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidatePattern("^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$")]
        [string] $SinceDate = (Get-Date).AddDays(-2).ToString("yyyy-MM-dd"),

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidatePattern("^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$")]
        [string] $EndDate = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
    )

    begin { }
    process {
        
    }
    end { }
}