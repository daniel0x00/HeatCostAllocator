#############################################
# This script retrieves Heat Cost Allocators (HCA) meters consumption data for heating radiators of a user account on ista Nederland B.V. HCA portal.
# The script logs in to the portal, retrieves the user addresses, and then retrieves the consumption data for each day in the specified date range.
# The output is saved to a CSV file for the whole billing period, on a day-by-day basis and meter-by-meter.
# The advantage of this script is that it can be used to retrieve the consumption data as a day-by-day basis, which is not possible on the official portal; thus enabling automation and data analysis.
# It's also possible to download more billing periods of the further past, like data from 2 or 3 years ago.
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
### Usually the billing period date range is from YYYY-07-01 until (YYYY+1)-06-30. Example: 2024-07-01 to 2025-06-30, for the billing period year 2024.
$BillingPeriodYear  = '2024'
$startDate          = Get-Date -Year 2024 -Month 07 -Day 01 -Hour 0 -Minute 0 -Second 0
$endDate            = Get-Date -Year 2025 -Month 06 -Day 30 -Hour 0 -Minute 0 -Second 0
$todayDate          = Get-Date
### Output folder:
$currentPath        = (Get-Location).Path
#$currentPath        = 'D:\HCAReadings'
$fileName           = 'BillingPeriodYear_'+$BillingPeriodYear+'_ExportedAt_'+$todayDate.ToString("yyyy-MM-dd") + "_HCAReadings.csv"
$filePath           = [System.IO.Path]::Combine($currentPath, $fileName)
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

# Output:
$output = @()

# Loop through all dates and request the consumption data for each day:
$currentDate = $startDate
$requestedAtTimestamp = Get-Date -UFormat %s
while ($currentDate -le $endDate) {

    $Since = $currentDate.AddDays(-2)
    $Until = $currentDate.AddDays(-1)

    # Get the consumption data for the date range:
    $periodReading = $Cuids | Get-HCAConsumption -ConsumptionUrl $ConsumptionUrl -BillingPeriodYear $BillingPeriodYear -SinceDate ($Since.ToString("yyyy-MM-dd")) -EndDate ($Until.ToString("yyyy-MM-dd"))

    # Add the output to the outputs array:
    $output += $periodReading

    # Increment the date by one day
    $currentDate = $currentDate.AddDays(1)
}

# Explicit define the columns to be exported to the CSV file. This is needed because the `Position` property is not always present in the output.
# Unfortunately, this approach has the disadvantage of having to manually define all the columns to be exported. It will break if the output object has new properties.
$output = $output | Select-Object `
                        @{n='CurEndTimestamp';e={ [datetime]::ParseExact($_.CurEnd, 'dd-MM-yyyy', $null).ToUniversalTime().Subtract([datetime]::UnixEpoch).TotalSeconds }}, `   # Represents the consumption data timestamp in unix format. Force it to be the first column so it can be used by Splunk as the event timestamp.    
                        @{n='RequestedAtTimestamp';e={ $requestedAtTimestamp }}, `                                                                                              # Represents today's datetime in unix format.    
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
                        CCDValue,       # This is the value that is used to calculate the consumption, after the reduction, multiplication, and transfer loss.
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

# Export the data to a CSV file:
$output     | Sort-Object Cuid, CurEndTimestamp, RadNr
            | Export-Csv -Path $filePath -NoTypeInformation -Delimiter ';'                   

