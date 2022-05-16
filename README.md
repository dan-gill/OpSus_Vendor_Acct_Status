# OpSus_Vendor_Acct_Status

Manages vendor accounts located in specified OUs by moving and/or disabling accounts if no logins occur for a specified period.

## Table of Contents

- [Requirements](#requirements)

## Requirements

Create `settings.json` file in script directory.

```json
{
  "OU": {
    "ShortTerm": "OU=Vendor Support,OU=Users,OU=Contoso,DC=FABRIKAM,DC=COM",
    "LongTerm": "OU=Vendor Project,OU=Users,OU=Contoso,DC=FABRIKAM,DC=COM"
  },
  "ValidPeriodHours": {
    "ShortTerm": 72,
    "LongTerm": 2160
  }
}
```
