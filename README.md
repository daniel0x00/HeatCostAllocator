# Heat Cost Allocator (HCA) heating meters readings script
PowerShell script to get readings of Heat Cost Allocators ([doprimo-3 heating meters](https://www.ista.com/uk-2023/technology/heat-cost-allocators/)) operated by `ista Nederland B.V.` on a **per day**, **per billing period** and **per meter** basis.

This is an unofficial script. The official API is not documented and the script is based on reverse-engineering the API calls made by the official portal. Use it as your own risk and responsibility. No liability is assumed for any damages or losses caused by the use of this script.

## Installation
```bash
git clone https://github.com/daniel0x00/HeatCostAllocator.git
```

## Requirements 
- PowerShell 7 or higher, [available for Windows, MacOS and Linux](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4).

## Usage
- Add your credentials to the [ista Nederland B.V. login portal](https://mijn.ista.nl/home/index) on the `usage.ps1` file, vars `$Username` and `$Password`. ([don't have an account?](https://mijn.ista.nl/RegisterNewUser)).
- By default, the script will get the heating readings broken down by day and by the full billing period. It will export 2 `.CSV` files: `DailyBasis_ExportedAt_yyyy-MM-dd_HCAReadings.csv` and `FullPeriodBasis_ExportedAt_yyyy-MM-dd_HCAReadings.csv`. 
- It is recommended to export once a week: **every Thursday night**. If you schedule the execution of `usage.ps1` in a cron job to every Thursday, you will export **both** the readings as a **daily basis** (`DailyBasis` file) as well as the **full billing period** (`FullPeriodBasis` CSV file).
- The `FullPeriodBasis` CSV file will match what is shown in the portal.
- The idea is that you export every week at least once, so you'll accumulate `FullPeriodBasis` CSV files and hence you'll be able to calculate the consumption per radiator, per week. On the official portal you can't do this calculation as you only see the consumption per the full billing period (or until last Sunday since today's day).
- Run the script by dot-sourcing it:

```powershell
PS /> . .\usage.ps1
PS /> $fullData | select -Last 1 | fl

RequestedAtTimestamp       : 1736001228
CurEndTimestamp            : 1656540000
CurEndDatetime             : 6/30/2022 12:00:00 AM
RequestedBillingPeriodYear : 2022
Period                     : Full
MeterId                    : <redacted>
MeterNr                    : <redacted>
BillingPeriodId            : 2021
RadNr                      : 1
Position                   : Kitchen
TransferLoss               : 0
Multiply                   : 1
Reduction                  : 35
CalcFactor                 : 1.05
BsDate                     : 01-07-2021
EsDate                     : 30-06-2022
BeginValue                 : 0
EndValue                   : 1154
CValue                     : 1154
CCValue                    : 1212
CCDValue                   : 788
DecPos                     : 0
SValR                      : 0
EvalR                      : 0
serviceId                  : 1
Order                      : 1
ArtNr                      : <redacted>
DisplayName                : <redacted>
Address                    : <redacted>
Zip                        : <redacted>
Cuid                       : <redacted>
CurStart                   : 01-07-2021
CurEnd                     : 30-06-2022
TotalNow                   : 4293
```

Show consumption per day between two dates (inclusive) and only for radiators that has consumed more than 0 units, with column selection as displayed in the official invoice.
```powershell
PS /> $dailyData | Where-Object {$_.CurEndDatetime -ge '2024-12-01' -and $_.CurEndDatetime -le '2025-01-01' -and $_.CCDValue -gt 0} | Select-Object CurEndDatetime, BillingPeriodId, RadNr, Position, MeterNr, BsDate, EsDate, BeginValue, EndValue, CValue, CalcFactor, CCValue, Reduction, CCDValue | Sort-Object CurEndDatetime, RadNr | Format-Table *

CurEndDatetime         BillingPeriodId RadNr Position      MeterNr BsDate     EsDate     BeginValue EndValue CValue CalcFactor CCValue Reduction CCDValue
--------------         -------------------------- ----- --------      ------- ------     ------     ---------- -------- ------ ---------- ------- --------- --------
12/1/2024 12:00:00 AM  2025                           1 Kitchen     <redacted> 30-11-2024 01-12-2024    258.000  276.000 18.000      1.050  19.000    35.000       12
12/1/2024 12:00:00 AM  2025                           3 Bedroom     <redacted> 30-11-2024 01-12-2024     33.000   42.000  9.000      1.150  10.000    55.000        5
12/1/2024 12:00:00 AM  2025                           4 Bathroom    <redacted> 30-11-2024 01-12-2024    211.000  213.000  2.000      0.600   1.000    35.000        1
12/1/2024 12:00:00 AM  2025                           5 Bedroom     <redacted> 30-11-2024 01-12-2024    422.000  432.000 10.000      1.050  11.000    55.000        5
12/1/2024 12:00:00 AM  2025                           6 Living room <redacted> 30-11-2024 01-12-2024    354.000  377.000 23.000      0.550  13.000    35.000        8
12/2/2024 12:00:00 AM  2025                           1 Kitchen     <redacted> 01-12-2024 02-12-2024    270.000  287.000 17.000      1.050  18.000    35.000       12
12/2/2024 12:00:00 AM  2025                           3 Bedroom     <redacted> 01-12-2024 02-12-2024     39.000   47.000  8.000      1.150   9.000    55.000        4
12/2/2024 12:00:00 AM  2025                           4 Bathroom    <redacted> 01-12-2024 02-12-2024    212.000  214.000  2.000      0.600   1.000    35.000        1
12/2/2024 12:00:00 AM  2025                           5 Bedroom     <redacted> 01-12-2024 02-12-2024    429.000  436.000  7.000      1.050   7.000    55.000        3
12/2/2024 12:00:00 AM  2025                           6 Living room <redacted> 01-12-2024 02-12-2024    369.000  390.000 21.000      0.550  12.000    35.000        8
```

## Column explanation

Unofficial (best-guess effort) explanation of the columns generated by the script.

| Column | Description | Belongs to official API? |
|---|---|---|
| CurEndTimestamp | Represents the time in Unix format of the `CurEnd` date. Output as first column, so a Big Data tool (like Splunk) picks it up as event time. | No. Introduced as a helper column. |
| CurEndDatetime | Represents the time DateTime object. Useful to sort and filter while in PowerShell. | No. Introduced as a helper function. |
| RequestedAtTimestamp | Represents the time at which the request was made to the API. | No. Introduced as a helper column. |
| RequestedBillingPeriodYear | Represents the billing period parameter passed to the API requests. | No. Introduced as a helper column. The API will output `BillingPeriodId` on the response. |
| Period | Represents the period of export. Can be `Daily` -indicating daily readings- or `Full` -indicating full billing period readings-. | No. Introduced as a helper column. |
| BeginValue | Meter reading as it was seen on `BsDate` date. | Yes |
| EndValue | Meter reading as it was seen on `EsDate` date. | Yes |
| CValue | Difference `EndValue`-`BeginValue` | Yes |
| CCDValue | This is the amount of units you're going to be billed for, after the application of `Reduction`, `CalcFactor` and `Multiply`. **IMPORTANT**: this value **CANNOT** be used on the `DailyBasis` export as the calculation will be different than on the `FullPeriod` export. | Yes |
| TransferLoss | Refers to heat transfer losses associated with the measurement process. It accounts for the heat that is lost during the transfer of energy from the radiator to the environment, which might not directly contribute to the actual heating of the room. It can be a set value or a formula. Since my radiators all have a `TransferLoss` of `0`, I cannot determine it's usage. However, I don't think is being used as this column doesn't show up in the official bill. | Yes |
| DecPos | Decimal position, determines the number of decimal places shown in the displayed value. Example: DecPos = 2 means 123.45; DecPos = 0 means 123. | Yes |
| SValR | Scaling value for radiators, adjusts for specific radiator heat output. Typically determined based on radiator type, size, and heat output. Example: Larger radiators → Higher SValR. Unknown usage. Since my radiators all have a `SValR` of `0`, I cannot determine it's usage. | Yes |
| EvalR | Evaluation factor. All my radiadors do have a value of `92`. Unknown usage. | Yes |

## Billing explanation

Unofficial (best-guess effort) explanation on how the billing is calculated:
1. Billing is based on the readings of the **full billing period**.
2. The script will retrieve all billing periods available for your account and will pull the data available of those. Optionally, to get a **list of available billing periods** for your account —which also represents how far back can you go in time in your account—, you can use:
```powershell
(New-HCASession -LoginUrl $LoginUrl -Username $Username -Password $Password | Get-HCAUser -UserUrl $UserUrl).User.Cus | ForEach-Object { $_.curConsumption | ForEach-Object { $_.BillingPeriods | Format-Table * } }
```
```powershell
   y s                    e                         ta
   - -                    -                         --
2025 7/1/2024 12:00:00 AM 6/30/2025 12:00:00 AM 12.600
2024 7/1/2023 12:00:00 AM 6/30/2024 12:00:00 AM 11.600
2023 7/1/2022 12:00:00 AM 6/30/2023 12:00:00 AM 10.300
2022 7/1/2021 12:00:00 AM 6/30/2022 12:00:00 AM 10.800
```
3. You're billed for the Units shown on the `CCDValue` column. This value is calculated as follows:
   - `(EndValue - BeginValue) * CalcFactor * ((100 - Reduction) / 100)`, then rounded to the nearest integer, as value `DecPos` enforces.
4. The `EUR` price of the unit determined by `ista Nedarland B.V.` is not shown on the API response on portal [mijn.ista.nl](https://mijn.ista.nl/home/index). Instead, [debicasso portal](https://debicasso.istanederland.nl/login) (don't have an account? write to debicasso-administratie@ista.nl to get one) is used to see the billing details of your billing period, available by the end of October, section `Mijn dossier`, subject `Afrekening periode : 1-7-xxxx t/m 30-6-xxxx`. My understanding is that the `EUR` price per unit is calculated upon the consumption of your whole building (section #2, `Berekening eenheidsprijzen`, then `Variabele energiekosten 55,00%`), then broken down by radiator (section #3 `Overzicht meterstanden en bepaling van uw verbruik`) and then price per unit is calculated on section #4 `Overzicht van uw kosten`, lines `Variabele energiekosten` and `Overige kosten`; taking the unit prices shown in column `Prijs per eenheid`. Have in mind you also pay a price for the `Vloeroppervlakte` (floor area) of your building: this varies per building.

### Historical heating unit costs
Sharing here the price per unit of variable costs and fixed costs for each billing period, for my building. 

#### Variable energy cost (Variabele energiekosten)
Represents **55% of the bill**. 

Billing year | Billing period | Price per unit | % variation vs previous year |
|---|---|---|---|
| 2022 | 1-7-2021 / 30-6-2022 | 0.422241 EUR | `unknown` |
| 2023 | 1-7-2022 / 30-6-2023 | 0.953447 EUR | **125.80%** |
| 2024 | 1-7-2023 / 30-6-2024 | 1.110027 EUR | **16.42%** |
| 2025 | 1-7-2024 / 30-6-2025 | 0,554998 EUR | **-50.00%** |

#### Fixed energy cost (Vaste energiekosten)
Represents **45% of the bill**. 

Billing year | Billing period | Price per unit | % variation vs previous year |
|---|---|---|---|
| 2022 | 1-7-2021 / 30-6-2022 | 0.076722 EUR | `unknown` |
| 2023 | 1-7-2022 / 30-6-2023 | 0.130516 EUR | **70.12%** |
| 2024 | 1-7-2023 / 30-6-2024 | 0.116517 EUR | **-10.73%** |
| 2025 | 1-7-2024 / 30-6-2025 | 0.077263 EUR | **-33.58%** |