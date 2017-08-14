<#
.SYNOPSIS
    Query haveibeenpwnd.com api for pwn accounts
.DESCRIPTION
    This Cmdlet queries the haveibeenpwnd.com api with the specified accountnames or email addresses and returns rich data.
.EXAMPLE
    PS C:\> Get-AccountBreach MyUser@domain.tld
    Query a single email address.
.EXAMPLE
    PS C:\> Get-AccountBreach MyUser@domain.tld, MyUserAccount
    Query an email address and an user account.
.EXAMPLE
    PS C:\> "MyUser@domain.tld", "MyUserAccount" | Get-AccountBreach
    Query an email address and an user account by pipeline.
.EXAMPLE
    PS C:\> Get-AccountBreach MyUser@domain.tld, MyUserAccount -NoProgress
    Query an email address and an user account, hides progress bar.
.OUTPUTS
    [pscustomobject]
.NOTES
    Feel free to support haveibeenpwned.com for their service.

    If you want to query multiple times, the api needs you to wait 1500ms between each query. If you use pipeline or array-input, the cmdlet pays attention to this fact.
#>
function Get-AccountBreach {
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$AccountName,
        [switch]$NoProgress
    )
    begin {
        # enable TLS 1.2 support
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    process {
        $Num = $AccountName.Count
        $iteration = 0
        foreach ($n in $AccountName) {
            if (!($NoProgress) ) {
                $prog = @{
                    Activity         = "Getting breach info from haveibeenpwned.com API ($iteration/$num)"
                    PercentComplete  = (($iteration * 100 / $Num))
                    CurrentOperation = "Waiting for API, then query $n"
                }
                Write-Progress @prog
            }
            if ($Wait) {
                Start-Sleep -Milliseconds 1500
            }
            try {
                $response = Invoke-RestMethod -Uri "https://haveibeenpwned.com/api/v2/breachedaccount/$n" -Method Get -UserAgent 'powershell'
                $breaches = $response | ForEach-Object {
                    [PSCustomObject]@{
                        Title        = $_.Title
                        Name         = $_.Name
                        Domain       = $_.Domain
                        BreachDate   = $_.BreachDate -as [datetime]
                        AddedDate    = $_.AddedDate -as [datetime]
                        DataClasses  = $_.DataClasses
                        IsVerified   = $_.IsVerified -as [bool]
                        IsFabricated = $_.IsFabricated -as [bool]
                        IsSensitive  = $_.IsSensitive -as [bool]
                        IsActive     = $_.IsActive -as [bool]
                        IsRetired    = $_.IsRetired -as [bool]
                        IsSpamList   = $_.IsSpamList -as [bool]
                        Description  = $_.Description -as [string]
                    }
                }
                $breached = $true
            }
            catch {
                switch ($_.exception.response.statuscode.value__) {
                    404 {
                        $breached = $false
                        $breaches = @()
                    }
                    429 {
                        $waittime = $response."Retry-After"
                        Write-Error "Use Pipeline functionality or array input or wait $waittime"
                        $breached = 'wait'
                    }
                }
            }
            finally {
                [pscustomobject]@{
                    AccountName = $n
                    Breached    = $breached
                    Breaches    = $breaches
                }
            }
            $Wait = $true
            $iteration++
        }
    }
}
