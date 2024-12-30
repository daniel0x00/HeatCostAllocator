function New-HCASession {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $LoginUrl,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $ConsumptionUrl,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Username,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Password
    )

    begin { }
    process {

        ##
        # First request gets the Action URL:
        $FirstRequestParameters = @{
            Uri = $LoginUrl
            Method = 'Get'
            Headers = @{
                "Accept" = "text/xml"
                "Sec-Fetch-Site" = "same-origin"
                "Sec-Fetch-Mode" = "navigate"
                "Sec-Fetch-Dest" = "document"
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246"
            }
        }

        $FirstRequest = Invoke-WebRequest @FirstRequestParameters -SessionVariable LoginSession -ErrorAction Stop -SkipCertificateCheck 

        $FormAction = [string](([regex]::Match($FirstRequest.Content,'<(form|FORM)[^>]*\s(action|ACTION)="(?<form_action>[^"]+)"')).groups["form_action"].value)
        Write-Verbose "[New-HCASession] First request form action: $FormAction" 
        #
        ##

        
        ##
        # Second request sends the username:
        $LoginParameters = @{
            Uri = $FormAction
            Method = 'Post'
            Body = "username=$Username"
            WebSession = $LoginSession
            ContentType = 'application/x-www-form-urlencoded;charset=UTF-8'
            Headers = @{
                "Accept" = "text/xml"
                "Sec-Fetch-Site" = "same-origin"
                "Sec-Fetch-Mode" = "navigate"
                "Sec-Fetch-Dest" = "document"
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246"
            }
        }

        $SecondRequest = Invoke-WebRequest @LoginParameters -ErrorAction Stop -SkipCertificateCheck 

        $FormAction = [string](([regex]::Match($SecondRequest.Content,'<(form|FORM)[^>]*\s(action|ACTION)="(?<form_action>[^"]+)"')).groups["form_action"].value)
        Write-Verbose "[New-HCASession] Second request form action: $FormAction" 
        #
        ##


        ##
        # Third request sends the password:
        $LoginParameters = @{
            Uri = $FormAction
            Method = 'Post'
            Body = "password=$Password"
            WebSession = $LoginSession
            ContentType = 'application/x-www-form-urlencoded;charset=UTF-8'
            Headers = @{
                "Accept" = "text/xml"
                "Sec-Fetch-Site" = "same-origin"
                "Sec-Fetch-Mode" = "navigate"
                "Sec-Fetch-Dest" = "document"
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246"
            }
        }

        $ThirdRequest = Invoke-WebRequest @LoginParameters -ErrorAction Stop -SkipCertificateCheck 

        ## Login data: 
        $oidc_url = [string](([regex]::Match($ThirdRequest.Content,'<FORM[^>]*\sACTION="(?<oidc_url>[^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).groups["oidc_url"].value)
        $oidc_code = [string](([regex]::Match($ThirdRequest.Content,'<INPUT TYPE="HIDDEN" NAME="code" VALUE="(?<oidc_code>[^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).groups["oidc_code"].value)
        $oidc_iss = [string](([regex]::Match($ThirdRequest.Content,'<INPUT TYPE="HIDDEN" NAME="iss" VALUE="(?<oidc_iss>[^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).groups["oidc_iss"].value)
        $oidc_state = [string](([regex]::Match($ThirdRequest.Content,'<INPUT TYPE="HIDDEN" NAME="state" VALUE="(?<oidc_state>[^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).groups["oidc_state"].value)
        $oidc_session_state = [string](([regex]::Match($ThirdRequest.Content,'<INPUT TYPE="HIDDEN" NAME="session_state" VALUE="(?<oidc_session_state>[^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).groups["oidc_session_state"].value)
        Write-Verbose "[New-HCASession] Third request oidc_url: $oidc_url" 
        Write-Verbose "[New-HCASession] Third request oidc_code: $oidc_code" 
        Write-Verbose "[New-HCASession] Third request oidc_iss: $oidc_iss" 
        Write-Verbose "[New-HCASession] Third request oidc_state: $oidc_state" 
        Write-Verbose "[New-HCASession] Third request oidc_session_state: $oidc_session_state" 
        #
        ##

        ##
        # Fourth request follows the OIDC URL:
        ##
        $LoginParameters = @{
            Uri = $oidc_url
            Method = 'Post'
            WebSession = $LoginSession
            Body = "code=$oidc_code&iss=$oidc_iss&state=$oidc_state&session_state=$oidc_session_state"
            ContentType = 'application/x-www-form-urlencoded;charset=UTF-8'
            Headers = @{
                "Accept" = "text/xml"
                "Sec-Fetch-Site" = "cross-site"
                "Sec-Fetch-Mode" = "navigate"
                "Sec-Fetch-Dest" = "document"
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246"
            }
        }

        $FourthRequest = Invoke-WebRequest @LoginParameters -ErrorAction Stop -SkipCertificateCheck

        ## JWT token:
        $jwt_token = [string](([regex]::Match($FourthRequest.Content,'<input type="hidden" name="__twj_" id="__twj_" value="(?<jwt_token>[^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).groups["jwt_token"].value)

        # Output object:
        $ReturnObject = New-Object System.Object
        $ReturnObject | Add-Member -Type NoteProperty -Name LoginUrl -Value ($FourthRequest.BaseResponse.ResponseUri.AbsoluteUri ?? $FourthRequest.BaseResponse.RequestMessage.RequestUri.AbsoluteUri)
        $ReturnObject | Add-Member -Type NoteProperty -Name ConsumptionUrl -Value $ConsumptionUrl
        $ReturnObject | Add-Member -Type NoteProperty -Name WebSession -Value $LoginSession
        $ReturnObject | Add-Member -Type NoteProperty -Name JWTToken -Value $jwt_token

        $ReturnObject

    }
    end { }
}