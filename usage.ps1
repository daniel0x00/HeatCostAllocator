#############################################
# This script retrieves Heat Cost Allocators (HCA) meters (doprimo-3 devices) consumption data for heating radiators of a user account on ista Nederland B.V. HCA portal.
# The script logs in to the portal, retrieves the user addresses, and then retrieves the consumption data for each day in the specified date range.
# The output is saved to a CSV file for the whole billing period, on a day-by-day basis and meter-by-meter.
# The advantage of this script is that it can be used to retrieve the consumption data as a day-by-day basis, which is not possible on the official portal; thus enabling automation and data analysis.
#
# Use it as your own risk and responsibility. No liability is assumed for any damages or losses caused by the use of this script.
#############################################

# Import ps1 files. It assumes that the files are in the same folder as this script.
. ./New-HCASession.ps1
. ./Get-HCAUser.ps1
. ./Get-HCAConsumption.ps1
# Use full path to these files if you're scheduling the execution of this script in a task scheduler:
#. 'D:\HeatCostAllocator\New-HCASession.ps1'
#. 'D:\HeatCostAllocator\Get-HCAUser.ps1'
#. 'D:\HeatCostAllocator\Get-HCAConsumption.ps1'

#############################################
##### Change the following variables to match your account and the desired date range:

### Login data for $LoginUrl portal:
$Username           = '<your_username>'     # Typically the username is an email address.
$Password           = '<your_password>'
### Output folder:
$currentPath        = (Get-Location).Path
#$currentPath        = 'D:\HCAReadings'

#############################################
$todayDate          = Get-Date
$dailyFileName      = 'DailyBasis_ExportedAt_'+$todayDate.ToString("yyyy-MM-dd") + "_HCAReadings.csv"
$fullFileName       = 'FullPeriodBasis_ExportedAt_'+$todayDate.ToString("yyyy-MM-dd") + "_HCAReadings.csv"
$dailyFilePath      = [System.IO.Path]::Combine($currentPath, $dailyFileName)
$fullFilePath       = [System.IO.Path]::Combine($currentPath, $fullFileName)
$requestedAtTimestamp = Get-Date -UFormat %s
#############################################

#############################################
##### URLs:
### Do not change these URLs unless you know they've changed.
### These are valid for ista Nederland B.V.
$LoginUrl           = 'https://mijn.ista.nl/home/index'
$UserUrl            = 'https://mijn.ista.nl/api/Values/UserValues'
$ConsumptionUrl     = 'https://mijn.ista.nl/api/Values/ConsumptionValues'

#####
#############################################

# Login to the HCA portal and retrieve the user addresses:
$Cuids = New-HCASession -LoginUrl $LoginUrl -Username $Username -Password $Password | Get-HCAUser -UserUrl $UserUrl

# All valid periods for the account:
$Periods = $Cuids.User.Cus | ForEach-Object { $_.curConsumption | ForEach-Object { $_.BillingPeriods | Select-Object @{n='BillingPeriodYear';e={$_.y}}, @{n='SinceDate';e={$_.s.ToString('yyyy-MM-dd')}}, @{n='EndDate';e={$_.e.ToString('yyyy-MM-dd')}} } }

#####
## Generate full-period consumption data:
## Ideally run this script every Tuesday to ensure that the readings we get on a FullPeriod bases match the ones shown on the portal.
#####
$dailyData = @()
$fullData = @()

$Cuids | Foreach-Object {
    $WebSession = $_.WebSession
    $JWTToken   = $_.JWTToken
    $User       = $_.User
    
    # Full periods data:
    $Periods | ForEach-Object {
        $BillingPeriodYear = $_.BillingPeriodYear
        $SinceDate = $_.SinceDate
        $EndDate = $_.EndDate

        $periodData = Get-HCAConsumption -ConsumptionUrl $ConsumptionUrl -BillingPeriodYear $BillingPeriodYear -SinceDate $SinceDate -EndDate $EndDate -WebSession $WebSession -JWTToken $JWTToken -User $User

        $fullData += $periodData | Select-Object `
                        @{n='RequestedAtTimestamp';e={ $requestedAtTimestamp }}, `                                                                                              # Represents today's datetime in unix format.    
                        @{n='CurEndTimestamp';e={ [datetime]::ParseExact($_.CurEnd, 'dd-MM-yyyy', $null).ToUniversalTime().Subtract([datetime]::UnixEpoch).TotalSeconds }}, `   # Represents the consumption data timestamp in unix format. Force it to be the first column so it can be used by Splunk as the event timestamp.    
                        @{n='CurEndDatetime';e={ [datetime]::ParseExact($_.CurEnd, 'dd-MM-yyyy', $null) }}, `                                                                   # Represents the consumption data in datetime format. For sorting purposes in pwsh.
                        @{n='RequestedBillingPeriodYear';e={ $BillingPeriodYear }}, `
                        @{n='Period';e={ 'Full' }}, `
                        MeterId,
                        MeterNr,
                        BillingPeriodId,
                        RadNr,
                        Position,
                        TransferLoss,
                        Multiply,
                        Reduction,
                        CalcFactor,
                        BsDate,
                        EsDate,
                        BeginValue,
                        EndValue,
                        CValue,
                        CCValue,
                        CCDValue,       # This value CAN be used for calculating the consumption, as the math is for Multiply, Reduction and CalcFactor is the same as shown in the portal -using the whole billing period aggregated data-.
                        DecPos,
                        SValR,
                        EvalR,
                        serviceId,
                        Order,
                        ArtNr,
                        DisplayName,
                        Address,
                        Zip,
                        Cuid,
                        CurStart,
                        CurEnd,
                        TotalNow        # This is the total consumption for the period for ALL meters within the CurStart and CurEnd fields. It is a repeated value for all meters, so do NOT sum it up.
    }

    # Daily data:
    $Periods | ForEach-Object {
        $BillingPeriodYear = $_.BillingPeriodYear
        $SinceDate = $_.SinceDate
        $EndDate = $_.EndDate
        
        $currentDate    = [datetime]::ParseExact($SinceDate, 'yyyy-MM-dd', $null)
        $endDate        = [datetime]::ParseExact($EndDate, 'yyyy-MM-dd', $null)
        if ($endDate -gt $todayDate) { $endDate = $todayDate } 

        #####
        ## Generate daily-basis consumption data:
        #####
        while ($currentDate -le $endDate) {

            $Since = $currentDate.AddDays(-2)
            $Until = $currentDate.AddDays(-1)

            # Get the consumption data for the date range:
            $dayData = Get-HCAConsumption -ConsumptionUrl $ConsumptionUrl -BillingPeriodYear $BillingPeriodYear -SinceDate ($Since.ToString("yyyy-MM-dd")) -EndDate ($Until.ToString("yyyy-MM-dd")) -WebSession $WebSession -JWTToken $JWTToken -User $User

            # Add the output to the outputs array:
            $dailyData += $dayData | Select-Object `
                                        @{n='RequestedAtTimestamp';e={ $requestedAtTimestamp }}, `                                                                                              # Represents today's datetime in unix format.    
                                        @{n='CurEndTimestamp';e={ [datetime]::ParseExact($_.CurEnd, 'dd-MM-yyyy', $null).ToUniversalTime().Subtract([datetime]::UnixEpoch).TotalSeconds }}, `   # Represents the consumption data timestamp in unix format. Force it to be the first column so it can be used by Splunk as the event timestamp.    
                                        @{n='CurEndDatetime';e={ [datetime]::ParseExact($_.CurEnd, 'dd-MM-yyyy', $null) }}, `                                                                   # Represents the consumption data in datetime format. For sorting purposes in pwsh.
                                        @{n='RequestedBillingPeriodYear';e={ $BillingPeriodYear }}, `
                                        @{n='Period';e={ 'Daily' }}, `
                                        MeterId,
                                        MeterNr,
                                        BillingPeriodId,
                                        RadNr,
                                        Position,
                                        TransferLoss,
                                        Multiply,
                                        Reduction,
                                        CalcFactor,
                                        BsDate,
                                        EsDate,
                                        BeginValue,
                                        EndValue,
                                        CValue,
                                        CCValue,
                                        CCDValue,       # This value CANNOT BE USED for calculating the consumption as a daily basis, as the math is for Multiply, Reduction and CalcFactor will be different when the data is aggregated for the whole billing period.
                                        DecPos,
                                        SValR,
                                        EvalR,
                                        serviceId,
                                        Order,
                                        ArtNr,
                                        DisplayName,
                                        Address,
                                        Zip,
                                        Cuid,
                                        CurStart,
                                        CurEnd,
                                        TotalNow        # This is the total consumption for the period for ALL meters within the CurStart and CurEnd fields. It is a repeated value for all meters, so do NOT sum it up.

            # Increment the date by one day
            $currentDate = $currentDate.AddDays(1)
        }
    }
    
}

#####
# Export both files as CSV:
#####
$dailyData  | Sort-Object Cuid, CurEndTimestamp, RadNr
            | Export-Csv -Path $dailyFilePath -NoTypeInformation -Delimiter ';'                   

$fullData   | Sort-Object Cuid, CurEndTimestamp, RadNr
            | Export-Csv -Path $fullFilePath -NoTypeInformation -Delimiter ';'   

##### Export custom period data:
# # run ./usage.ps1 first.
# # then run:
# $WebSession     = $Cuids[0].WebSession
# $JWTToken       = $Cuids[0].JWTToken
# $User           = $Cuids[0].User 
# $customPeriod   = Get-HCAConsumption -ConsumptionUrl $ConsumptionUrl -BillingPeriodYear '2025' -SinceDate '2024-07-01' -EndDate '2025-06-30' -WebSession $WebSession -JWTToken $JWTToken -User $User 
# $customPeriod | Select-Object BillingPeriodId, RadNr, Position, MeterNr, BsDate, EsDate, BeginValue, EndValue, CValue, CalcFactor, CCValue, Reduction, CCDValue | Sort-Object RadNr | Format-Table *