<#
.SYNOPSIS
    A script to manage vendor accounts located in specified OUs by moving
    and/or disabling accounts if no logins occur for a specified period.
.DESCRIPTION
    This script automates migrating vendor accounts to specified OUs by
    moving and/or disabling accounts if no logins occur for a specified
    period. The script stores OUs and time periods in settings.json.
    This script is designed to run as a scheduled task.
.NOTES
    File Name  : Set-VendorAccountStatus.ps1
    Author     : Dan Gill - dgill@gocloudwave.com
    Requires   : settings.json
.LINK
    https://shellgeek.com/get-aduser-filter-examples/
.LINK
    https://shellgeek.com/powershell-get-aduser-last-logon/
.LINK
    https://shellgeek.com/move-ad-user-to-another-ou/
.EXAMPLE
    ./Set-VendorAccountStatus.ps1
.INPUTS
   None.
.OUTPUTS
   None.
.EXAMPLE
   PS> .\Set-VendorAccountStatus.ps1
#>

# Read settings.json
$Settings = Get-Content "$PSScriptRoot\settings.json" -Raw | ConvertFrom-Json

# Store settings in local variables
$VendorProjectOU = $Settings.OU.LongTerm
$VendorServiceOU = $Settings.OU.ShortTerm
$VendorProjectInactiveHours = $Settings.ValidPeriodHours.LongTerm
$VendorServiceInactiveHours = $Settings.ValidPeriodHours.ShortTerm

function Get-AgedADUsers {
  [CmdletBinding()]
  param (
    # Which OU are we searching?
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [string]
    $OU,

    # How long must the account be inactive in hours?
    [Parameter(Mandatory, ValueFromPipeline, Position = 1)]
    [int]
    $InactiveHours,

    # Do we want to process accounts that have never been used?
    [Parameter(ValueFromPipeline, Position = 2)]
    [bool]
    $ProcessUnusedAccounts
  )

  begin {
    # Calculate the most recent logon time to permit
    $FromDate = (Get-Date).AddHours( - ($InactiveHours))
  }
  process {
    if ($ProcessUnusedAccounts) {
      # Find accounts with a last logon older than $FromDate
      $users = Get-ADUser -Filter { Enabled -eq $true -and lastLogon -le $FromDate } -SearchBase $OU
    } else {
      # Find account with a last logon older than $FromDate that have logged in at least once
      $users = Get-ADUser -Filter { Enabled -eq $true -and lastLogon -le $FromDate -and lastLogon -ne 0 } -SearchBase $OU
    }
  }
  end {
    return $users
  }
}

# The script can only run on a DC and the OUs have to exist already.
if ( Get-WmiObject -Query "select * from Win32_OperatingSystem where ProductType='2'" ) {
  if ( [adsi]::Exists("LDAP://$VendorServiceOU") -and [adsi]::Exists("LDAP://$VendorProjectOU" ) ) {
    # Move aged project users to service OU
    Get-AgedADUsers -OU $VendorProjectOU -InactiveHours $VendorProjectInactiveHours -ProcessUnusedAccounts $false | Move-ADObject -TargetPath $VendorServiceOU

    # Disable aged users in service OU
    Get-AgedADUsers -OU $VendorServiceOU -InactiveHours $VendorServiceInactiveHours -ProcessUnusedAccounts $true | Disable-ADAccount
  } else {
    Write-Error -Message 'Unable to locate OU(s). Please verify OU paths.'
  }
} else {
  Write-Error -Message 'This script can only run on a domain controller.'
}