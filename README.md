# HeatCostAllocator
PowerShell script to get readings of Heat Cost Allocators ([doprimo-3 heating meters](https://www.ista.com/uk-2023/technology/heat-cost-allocators/)) operated by ista Nederland B.V. on a per-day and per-meter basis.

## Installation
```bash
git clone https://github.com/daniel0x00/HeatCostAllocator.git
```

## Requirements 
- PowerShell 7 or higher, [available for Windows, MacOS and Linux](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4).

## Usage
- Add your credentials to the [ista Nederland B.V. login portal](https://mijn.ista.nl/home/index) on the `usage.ps1` file, vars `$Username` and `$Password`. ([Don't have an account?](https://mijn.ista.nl/RegisterNewUser)).
- Adjust the billing period in the `usage.ps1` file if needed, on the vars `$BillingPeriodYear`, `$startDate` and `$endDate`.
- By default, the script will get the heating readings broken down by day. However, it is recommended to export once a week: every Monday night. If you schedule the execution of `usage.ps1` in a cron job to every Monday, you will export the whole billing period until the last Sunday.
- Run the script by dot-sourcing it:

```powershell
PS > . .\usage.ps1

# This will create a CSV file with the readings of the radiator's Heat Cost Allocators in your current directory.
# E.g. `BillingPeriodYear_2024_ExportedAt_2024-12-31_HCAReadings.csv`
# You also have available the variable $output which contains the readings as PowerShell object.
```

```powershell
PS > . .\usage.ps1
PS > $output | select -Last 1 | fl

CurEndTimestamp            : 1735513200
RequestedAtTimestamp       : 1735641355
RequestedBillingPeriodYear : 2024
MeterId                    : <redacted>
MeterNr                    : <redacted>
BillingPeriodId            : 2024
RadNr                      : 6
Position                   : Living room
TransferLoss               : 0
Multiply                   : 1
Reduction                  : 35
CalcFactor                 : 0.55
BsDate                     : 29-12-2024
EsDate                     : 30-12-2024
BeginValue                 : 705
EndValue                   : 724.35
CValue                     : 19.35
CCValue                    : 11
CCDValue                   : 7              
DecPos                     : 0
SValR                      : 0
EvalR                      : 92
serviceId                  : 1
Order                      : 1
ArtNr                      : <redacted>
DisplayName                : <redacted>
Address                    : <redacted>
Zip                        : <redacted>
Cuid                       : <redacted>
CurStart                   : 29-12-2024
CurEnd                     : 30-12-2024
TotalNow                   : 30

```