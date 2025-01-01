#############################################
# This script retrieves Heat Cost Allocators (HCA) meters consumption data for heating radiators of a user account on ista Nederland B.V. HCA portal.
# The script logs in to the portal, retrieves the user addresses, and then retrieves the consumption data for each day in the specified date range.
# The output is saved to a CSV file for the whole billing period, on a day-by-day basis and meter-by-meter.
# The advantage of this script is that it can be used to retrieve the consumption data as a day-by-day basis, which is not possible on the official portal; thus enabling automation and data analysis.
# It's also possible to download more billing periods of the further past, like data from 2 or 3 years ago.
#
# Note that ista Nederland B.V. only offers the consumption data 'as a weekly basis' and 'cumulative' on their portal, after every week has passed. Data is only available 'from the start of billing period until the last Sunday', as well as aggregated monthly.
# Even though the script connects to their API and retrieves the data on a daily basis, it's not known when the data is sent from the doprimo-3 devices to their servers.
# E.g. The data might be sent by the doprimo-3 devices to ista Nederland B.V. every Tuesday with readings on a per-day basis, and only made available in their API as a daily-basis only thereafter. However, the portal only shows the data 'until last Sunday'. 
# It is therefore recommended to execute this script and export data every Tuesday, to ensure that the data is available for the previous week. 
# Still, you will have the data broken down on a per-day basis, which is better than the 'weekly cumulative basis' as offered on the portal.
#
# Use it as your own risk and responsibility. No liability is assumed for any damages or losses caused by the use of this script.
#############################################

# Import ps1 files. It assumes that the files are in the same folder as this script.
. ./New-HCASession.ps1
. ./Get-HCAUser.ps1
. ./Get-HCAConsumption.ps1

#############################################
##### Change the following variables to match your account and the desired date range:
### Login data for $LoginUrl portal:
$Username           = '<your_username>'     # Typically the username is an email address.
$Password           = '<your_password>'
### Usually the billing period date range is from YYYY-07-01 until (YYYY+1)-06-30. Example: 2024-07-01 to 2025-06-30, for the billing period year 2025.
### To get all available billing periods for your account, read the README.md file.
$BillingPeriodYear  = '2025'
$startDate          = Get-Date -Year 2024 -Month 07 -Day 01 -Hour 0 -Minute 0 -Second 0
$endDate            = Get-Date -Year 2025 -Month 06 -Day 30 -Hour 0 -Minute 0 -Second 0
$todayDate          = Get-Date
### Output folder:
$currentPath        = (Get-Location).Path
#$currentPath        = 'D:\HCAReadings'
$dailyFileName      = 'DailyBasis_BillingPeriodYear_'+$BillingPeriodYear+'_ExportedAt_'+$todayDate.ToString("yyyy-MM-dd") + "_HCAReadings.csv"
$fullFileName       = 'FullPeriodBasis_BillingPeriodYear_'+$BillingPeriodYear+'_ExportedAt_'+$todayDate.ToString("yyyy-MM-dd") + "_HCAReadings.csv"
$dailyFilePath      = [System.IO.Path]::Combine($currentPath, $dailyFileName)
$fullFilePath       = [System.IO.Path]::Combine($currentPath, $fullFileName)
#####
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

# Loop through all dates and request the consumption data for each day:
$currentDate = $startDate
$requestedAtTimestamp = Get-Date -UFormat %s
# Prevents to request dates in the future:
if ($endDate -gt $todayDate) { $endDate = $todayDate } 

#####
## Generate daily-basis consumption data:
#####
$dailyData = @()
while ($currentDate -le $endDate) {

    $Since = $currentDate.AddDays(-2)
    $Until = $currentDate.AddDays(-1)

    # Get the consumption data for the date range:
    $periodReading = $Cuids | Get-HCAConsumption -ConsumptionUrl $ConsumptionUrl -BillingPeriodYear $BillingPeriodYear -SinceDate ($Since.ToString("yyyy-MM-dd")) -EndDate ($Until.ToString("yyyy-MM-dd"))

    # Add the output to the outputs array:
    $dailyData += $periodReading

    # Increment the date by one day
    $currentDate = $currentDate.AddDays(1)
}

#####
## Generate full-period consumption data:
## Ideally run this script every Tuesday to ensure that the readings we get on a FullPeriod bases match the ones shown on the portal.
#####
$fullData = $Cuids | Get-HCAConsumption -ConsumptionUrl $ConsumptionUrl -BillingPeriodYear $BillingPeriodYear -SinceDate ($startDate.ToString("yyyy-MM-dd")) -EndDate ($endDate.AddDays(-1).ToString("yyyy-MM-dd"))

# Explicit define the columns to be exported to the CSV file. This is needed because the `Position` property is not always present in the output.
# Unfortunately, this approach has the disadvantage of having to manually define all the columns to be exported. It will break if the output object has new properties.
$dailyData = $dailyData | Select-Object `
                        @{n='CurEndTimestamp';e={ [datetime]::ParseExact($_.CurEnd, 'dd-MM-yyyy', $null).ToUniversalTime().Subtract([datetime]::UnixEpoch).TotalSeconds }}, `   # Represents the consumption data timestamp in unix format. Force it to be the first column so it can be used by Splunk as the event timestamp.    
                        @{n='RequestedAtTimestamp';e={ $requestedAtTimestamp }}, `                                                                                              # Represents today's datetime in unix format.    
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

$fullData = $fullData | Select-Object `
                        @{n='CurEndTimestamp';e={ [datetime]::ParseExact($_.CurEnd, 'dd-MM-yyyy', $null).ToUniversalTime().Subtract([datetime]::UnixEpoch).TotalSeconds }}, `   # Represents the consumption data timestamp in unix format. Force it to be the first column so it can be used by Splunk as the event timestamp.    
                        @{n='RequestedAtTimestamp';e={ $requestedAtTimestamp }}, `                                                                                              # Represents today's datetime in unix format.    
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

#####
# Export both files as CSV:
#####
$dailyData  | Sort-Object Cuid, CurEndTimestamp, RadNr
            | Export-Csv -Path $dailyFilePath -NoTypeInformation -Delimiter ';'                   

$fullData   | Sort-Object Cuid, CurEndTimestamp, RadNr
            | Export-Csv -Path $fullFilePath -NoTypeInformation -Delimiter ';'   
