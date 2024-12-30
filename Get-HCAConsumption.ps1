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
        [PSObject] $User,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidatePattern("^(19|20)\d{2}$")]
        [string] $BillingPeriodYear = (Get-Date).Year.ToString(),

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidatePattern("^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$")]
        [string] $SinceDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd"),

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidatePattern("^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$")]
        [string] $EndDate = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd"),

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [switch] $PassThru=$false
    )

    begin { $ReturnArray = @() }
    process {
        $DisplayName = $User.DisplayName

        $User.Cus | ForEach-Object {
            
            $Cuid = $_.Cuid
            $Address = $_.Adress
            $Zip = $_.Zip

            Write-Verbose "[Get-HCAConsumption] Processing consumption for CUID: $Cuid"

            $Body = @{
                JWT = $JWTToken
                LANG = "en-US"
                Cuid = $Cuid
                Billingperiod = @{
                    y = $BillingPeriodYear
                    s = $SinceDate
                    e = $EndDate
                }
            } | ConvertTo-Json -Depth 2
    
            $RequestParameters = @{
                Uri = $ConsumptionUrl
                Method = 'Post'  
                WebSession = $WebSession
                Body = $Body
                ContentType = 'application/json'  
                Headers = @{
                    "Accept" = "application/json"
                    "Sec-Fetch-Site" = "same-origin"
                    "Sec-Fetch-Mode" = "navigate"
                    "Sec-Fetch-Dest" = "document"
                    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246"
                }
            }
    
            $Request = Invoke-RestMethod @RequestParameters -ErrorAction Stop -SkipCertificateCheck
    
            # Output object:
            $ReturnObject = New-Object System.Object
            $ReturnObject | Add-Member -Type NoteProperty -Name DisplayName -Value $DisplayName
            $ReturnObject | Add-Member -Type NoteProperty -Name Address -Value $Address
            $ReturnObject | Add-Member -Type NoteProperty -Name Zip -Value $Zip
            $ReturnObject | Add-Member -Type NoteProperty -Name Cuid -Value $Cuid
            $ReturnObject | Add-Member -Type NoteProperty -Name Consumption -Value $Request

            if ($PassThru) {
                $ReturnObject | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession
                $ReturnObject | Add-Member -Type NoteProperty -Name JWTToken -Value $JWTToken
            }
    
            $ReturnArray += $ReturnObject
        }
    }
    end { $ReturnArray }
}