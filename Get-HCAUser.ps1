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
        $RequestParameters = @{
            Uri = $UserUrl
            Method = 'Post'  
            WebSession = $WebSession
            Body = '{"JWT":"token","LANG":"en-US"}' -replace 'token', $JWTToken
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
        $ReturnObject | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession
        $ReturnObject | Add-Member -Type NoteProperty -Name JWTToken -Value $JWTToken
        $ReturnObject | Add-Member -Type NoteProperty -Name User -Value $Request

        $ReturnObject

    }
    end { }
}