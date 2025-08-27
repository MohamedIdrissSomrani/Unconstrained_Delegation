<#
.SYNOPSIS
  Check accounts for delegation type (Unconstrained, Constrained, or None)
  and show whether the account is enabled or disabled.

.DESCRIPTION
  This script can:
    - Scan specific accounts provided in a list or inline.
    - Or, with -All, scan all users and computers in AD (with progress bar).
    - Optionally write results to a CSV file with -OutFile.

.PARAMETER InputFile
  Path to a file containing a list of accounts (one per line).

.PARAMETER Accounts
  Array of account names to check.

.PARAMETER All
  Switch to scan all AD users and computers.

.PARAMETER OutFile
  Path to save results (CSV). Optional.

.PARAMETER NoColor
  Disable color output.

.EXAMPLE
  .\Check-Delegation.ps1 -InputFile accounts.txt

.EXAMPLE
  .\Check-Delegation.ps1 -Accounts user1, user2, SERVER01$

.EXAMPLE
  .\Check-Delegation.ps1 -All -OutFile results.csv
#>

param(
  [string]$InputFile,
  [string[]]$Accounts,
  [switch]$All,
  [string]$OutFile,
  [switch]$NoColor
)

if (-not (Get-Command Get-ADUser -ErrorAction SilentlyContinue)) {
  try { Import-Module ActiveDirectory -ErrorAction Stop }
  catch { Write-Error "ActiveDirectory module not available."; exit 1 }
}

# If no args provided, show usage
if (-not $PSBoundParameters.Count) {
  Write-Host "Usage:" -ForegroundColor Cyan
  Write-Host "  .\Check-Delegation.ps1 -InputFile accounts.txt"
  Write-Host "  .\Check-Delegation.ps1 -Accounts user1, user2, SERVER01$"
  Write-Host "  .\Check-Delegation.ps1 -All [-OutFile results.csv]"
  exit
}

$results = @()

# ------------------------------
# MODE 1: Full Scan (-All)
# ------------------------------
if ($All) {
  Write-Host "Scanning all AD users and computers..." -ForegroundColor Cyan

  # Count totals for progress tracking (lightweight count queries)
  $userTotal = (Get-ADUser -Filter * | Measure-Object).Count
  $compTotal = (Get-ADComputer -Filter * | Measure-Object).Count
  $total = $userTotal + $compTotal
  $i = 0

  # Process users (streaming)
  Get-ADUser -Filter * -Properties Enabled,userAccountControl,msDS-AllowedToDelegateTo |
    ForEach-Object {
      $i++
      if ($i % 200 -eq 0) {
        Write-Progress -Activity "Checking Delegation" -Status "Processed $i of $total" -PercentComplete (($i / $total) * 100)
      }

      $delegationType = "None"
      $uac = [int]$_.userAccountControl
      $hasUFD = [bool]($uac -band 0x80000)
      $hasConstrained = ($_.'msDS-AllowedToDelegateTo' -ne $null -and $_.'msDS-AllowedToDelegateTo'.Count -gt 0)

      if ($hasUFD -and -not $hasConstrained) { $delegationType = "Unconstrained" }
      elseif ($hasConstrained) { $delegationType = "Constrained" }

      $results += [pscustomobject]@{
        Account        = $_.samAccountName
        Type           = "User"
        Enabled        = $_.Enabled
        DelegationType = $delegationType
      }
    }

  # Process computers (streaming)
  Get-ADComputer -Filter * -Properties Enabled,userAccountControl,msDS-AllowedToDelegateTo |
    ForEach-Object {
      $i++
      if ($i % 200 -eq 0) {
        Write-Progress -Activity "Checking Delegation" -Status "Processed $i of $total" -PercentComplete (($i / $total) * 100)
      }

      $delegationType = "None"
      $uac = [int]$_.userAccountControl
      $hasUFD = [bool]($uac -band 0x80000)
      $hasConstrained = ($_.'msDS-AllowedToDelegateTo' -ne $null -and $_.'msDS-AllowedToDelegateTo'.Count -gt 0)

      if ($hasUFD -and -not $hasConstrained) { $delegationType = "Unconstrained" }
      elseif ($hasConstrained) { $delegationType = "Constrained" }

      $results += [pscustomobject]@{
        Account        = $_.samAccountName
        Type           = "Computer"
        Enabled        = $_.Enabled
        DelegationType = $delegationType
      }
    }

  Write-Progress -Activity "Checking Delegation" -Completed -Status "Done"
}

# ------------------------------
# MODE 2: Targeted List
# ------------------------------
else {
  # Load accounts from file if provided
  if ($InputFile) {
    if (-not (Test-Path -LiteralPath $InputFile)) { Write-Error "File not found: $InputFile"; exit 1 }
    $Accounts = Get-Content -LiteralPath $InputFile
  }

  if (-not $Accounts) { Write-Error "No accounts provided. Use -InputFile, -Accounts, or -All."; exit 1 }

  # Normalize
  $Accounts = $Accounts | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') } | Select-Object -Unique

  foreach ($acct in $Accounts) {
    try {
      $user = Get-ADUser -Identity $acct -Properties Enabled,userAccountControl,msDS-AllowedToDelegateTo -ErrorAction SilentlyContinue
      if ($user) {
        $delegationType = "None"
        $uac = [int]$user.userAccountControl
        $hasUFD = [bool]($uac -band 0x80000)
        $hasConstrained = ($user.'msDS-AllowedToDelegateTo' -ne $null -and $user.'msDS-AllowedToDelegateTo'.Count -gt 0)

        if ($hasUFD -and -not $hasConstrained) { $delegationType = "Unconstrained" }
        elseif ($hasConstrained) { $delegationType = "Constrained" }

        $results += [pscustomobject]@{
          Account        = $acct
          Type           = "User"
          Enabled        = $user.Enabled
          DelegationType = $delegationType
        }
        continue
      }

      $comp = Get-ADComputer -Identity $acct -Properties Enabled,userAccountControl,msDS-AllowedToDelegateTo -ErrorAction SilentlyContinue
      if ($comp) {
        $delegationType = "None"
        $uac = [int]$comp.userAccountControl
        $hasUFD = [bool]($uac -band 0x80000)
        $hasConstrained = ($comp.'msDS-AllowedToDelegateTo' -ne $null -and $comp.'msDS-AllowedToDelegateTo'.Count -gt 0)

        if ($hasUFD -and -not $hasConstrained) { $delegationType = "Unconstrained" }
        elseif ($hasConstrained) { $delegationType = "Constrained" }

        $results += [pscustomobject]@{
          Account        = $acct
          Type           = "Computer"
          Enabled        = $comp.Enabled
          DelegationType = $delegationType
        }
        continue
      }

      $results += [pscustomobject]@{ Account=$acct; Type="Not Found"; Enabled=$null; DelegationType="N/A" }
    }
    catch {
      $results += [pscustomobject]@{ Account=$acct; Type="Error"; Enabled=$null; DelegationType="Error: $($_.Exception.Message)" }
    }
  }
}

# ------------------------------
# Output
# ------------------------------
if ($NoColor) {
  $results | Format-Table -AutoSize
} else {
  $header = "{0,-30} {1,-10} {2,-8} {3}" -f 'Account','Type','Enabled','DelegationType'
  Write-Host $header -ForegroundColor Cyan
  Write-Host ('-' * $header.Length)

  foreach ($r in $results) {
    $left = ("{0,-30} {1,-10} {2,-8} " -f $r.Account,$r.Type,$r.Enabled)
    switch ($r.DelegationType) {
      "Unconstrained" { Write-Host $left -NoNewline; Write-Host $r.DelegationType -ForegroundColor Red }
      "Constrained"   { Write-Host $left -NoNewline; Write-Host $r.DelegationType -ForegroundColor Yellow }
      "None"          { Write-Host $left -NoNewline; Write-Host $r.DelegationType -ForegroundColor Green }
      default         { Write-Host $left -NoNewline; Write-Host $r.DelegationType -ForegroundColor Gray }
    }
  }
}

# ------------------------------
# Export to CSV if requested
# ------------------------------
if ($OutFile) {
  try {
    # Ensure directory exists if a path was provided
    $dir = Split-Path -Path $OutFile -Parent
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $results | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8
    Write-Host "`nResults also saved to $OutFile" -ForegroundColor Cyan
  }
  catch {
    Write-Error ("Failed to write to {0}: {1}" -f $OutFile, $_.Exception.Message)
  }
}
