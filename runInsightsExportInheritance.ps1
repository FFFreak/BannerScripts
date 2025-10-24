<# THE BELOW IS FROM MY CHROME SESSION OF THE INSIGHT PAGE REPORT -> F12 DEV TOOLS, CLICK A FOLDER, NETWORK TAB -> right click a page -> COPY AS POWERSHELL...
OPEN POWERSHELL AND PASTE
THIS ** COPIES** YOUR SESSION FROM BROWSER to the powershell session

#> 

<# PASTE YOUR BROWSER CODE AND RUN IT  BEFORE RUNNING THIS!! - see note above 
   ADJUST INSTANCE ENVIRONMENT BELOW
#>

# Environment is PROD, unless an option below is true -- CHANGE INSTANCE ENVIRONMENT HERE
$blnTestEnv = $true
$blnPProdEnv = $false
$blnDevlEnv = $false


<# Sleep for output #>
$intSleep = 2

$strProdEnv = "experiencesetup.elluciancloud.com"
$strNonProdEnv = "experiencesetup-test.elluciancloud.com"
$strProdShort = "PROD"
$strTestShort = "Test"
$strPProdShort = "PPRD"
$strDevlShort = "DEVL"


# Default is PROD
$strRunEnv = $strProdEnv
$strRunEnvShort = $strProdShort

if ($blnTestEnv) {
  $strRunEnvShort = $strTestShort
} elseif ($blnPProdEnv) {
  $strRunEnvShort = $strPProdShort
} elseif ($blnDevlEnv) {
  $strRunEnvShort = $strDevlShort
} else {
  # no action
}

$logicTestEnv = $false
$logicTestprod = ((-not $blnTestEnv) -and (-not $blnPProdEnv) -and (-not $blnDevlEnv)) # True when Non-prod is all false

if ($blnTestEnv -and ($blnTestEnv -xor $blnPProdEnv) -and ($blnTestEnv -xor $blnDevlEnv)) {
  # Test for Test ONLY
  $logicTestEnv = $true
} elseif ($blnPProdEnv -and ($blnTestEnv -xor $blnPProdEnv) -and ($blnDevlEnv -xor $blnPProdEnv)) { 
  # Test for PPRD ONLY
  $logicTestEnv = $true
} elseif ($blnDevlEnv -and ($blnDevlEnv -xor $blnPProdEnv) -and ($blnTestEnv -xor $blnDevlEnv)) {
  # Test for DEVL ONLY
  $logicTestEnv = $true
} elseif ($logicTestprod) {
  # PROD!
} else {}

if ((-not $logicTestEnv) -and (-not $logicTestprod)) {
  write-host "Please check your instance switches!" -foreground red
  write-host '`tSET ONLY (1) TRUE:' "`r`n`t" '$blnTestEnv - TEST' "`r`n`t" '$blnPProdEnv - PPRD' "`r`n`t" '$blnDevlEnv - DEVL' -foreground yellow
  write-host '`tOR SET NONE (0) TRUE: to run in PROD' -foreground yellow
  return
}

if ($strRunEnvShort -ne "PROD") {
  $strRunEnv = $strNonProdEnv
} else {}


# START MAIN LOGIC

write-host "RUNNING IN  $($strRunEnvShort) ENVIRONMENT" -foreground yellow
sleep $intSleep

$strDate = (get-date -Format "yyyyMMdd")
$fileOutput = ".\InsightsInheritencePermissions_$($strRunEnvShort)_$($strDate).csv"

# start-Transcript insights_output_$($strRunEnvShort)_$($strDate).txt  # full session record for debugging

<# Identify Tenet #>

$TenetContent = Invoke-WebRequest -UseBasicParsing -Uri "https://$($strRunEnv)/accountsAndTenants" `
     -WebSession $session `
     -Headers @{
     "authority"="$($strRunEnv)"
     "method"="GET"
     "path"="/accountsAndTenants"
     "scheme"="https"
     "accept"="*/*"
     "accept-encoding"="gzip, deflate, zstd"
     "accept-language"="en-US,en;q=0.9"
     "cache-control"="no-cache"
     "pragma"="no-cache"
     "priority"="u=1, i"
     "referer"="https://$($strRunEnv)/"
     "sec-ch-ua"="`"Not)A;Brand`";v=`"8`", `"Chromium`";v=`"138`", `"Microsoft Edge`";v=`"138`""
     "sec-ch-ua-mobile"="?0"
     "sec-ch-ua-platform"="`"Windows`""
     "sec-fetch-dest"="empty"
     "sec-fetch-mode"="cors"
     "sec-fetch-site"="same-origin"
}
if ($tenetContent.content -like "*<title>Ellucian SSO  - Sign In</title>*") {
  write-host "Session was not entered properly - please copy session again from browser session!" -foreground yellow
  return 
} else {}

$TENET_ID = ""
$TENET_NAME = ""
$TENET_LABEL = ""

if (@(($TenetContent.content | convertfrom-JSON).tenants).count -gt 1) {
  write-host "More than one tenet detected, uncomment the TENET_ID line and manually set your tenet ids from:"
  foreach ($tent in ($TenetContent.content | convertfrom-JSON).tenants) {
    write-host "$($tent.label) - $($tent.name) - $($tent.id)"
    if ($tent.label -eq "$strRunEnvShort") {
      $TENET_NAME = $($tent.name)
      $TENET_ID = $($tent.id)
      $TENET_LABEL = $($tent.label)
    } else {}
  }
} else {
  $TENET_NAME = ($TenetContent.content | convertfrom-JSON).tenants.name
  $TENET_ID = ($TenetContent.content | convertfrom-JSON).tenants.id
  $TENET_LABEL = ($TenetContent.content | convertfrom-JSON).tenants.label
}


write-host "Connected to -- ($($TENET_LABEL)) $TENET_NAME [$($TENET_ID)]" -foreground cyan
Write-host "Sleeping $intSleep seconds before continuing" -foreground darkcyan
sleep $intSleep

# $TENET_ID = "all lowercase tenet ID if above does not work goes here"

$Roles = Invoke-WebRequest -UseBasicParsing -Uri "https://$($strRunEnv)/tenantRoles/$($TENET_ID)" `
-WebSession $session `
-Headers @{
"authority"="$($strRunEnv)"
  "method"="GET"
  "path"="/tenantRoles/$($TENET_ID)"
  "scheme"="https"
  "accept"="*/*"
  "accept-encoding"="gzip, deflate, zstd"
  "accept-language"="en-US,en;q=0.9"
  "cache-control"="no-cache"
  "pragma"="no-cache"
  "priority"="u=1,i"
  "referer"="https://$($strRunEnv)/roles"
  "sec-ch-ua"="`"Not)A;Brand`";v=`"8`", `"Chromium`";v=`"138`", `"Microsoft Edge`";v=`"138`""
  "sec-ch-ua-mobile"="?0"
  "sec-ch-ua-platform"="`"Windows`""
  "sec-fetch-dest"="empty"
  "sec-fetch-mode"="cors"
  "sec-fetch-site"="same-origin"
}

# Now we convert GUID to a human readable form
$QueryDataEthos = $null
$QueryDataExp = $null
$QueryDataIDP = $null
# $QueryDataExpExtra = $null # Userid in Ethos
$QueryDataEthosCount = 0
$QueryDataExpCount = 0
$QueryDataIDPCount = 0
$QueryDataExpExtraCount = 0
$QueryEthosBody = ""
$QueryExpBody = ""
$QueryIDPBody = ""


$QueryDataEthos = (($Roles.content | ConvertFrom-Json).authzRoles | ?{$_.source -eq "ethos"}).id | Sort
$QueryDataExp = (($Roles.content | ConvertFrom-Json).authzRoles | ?{$_.source -eq "experience"}).name | ?{$_.length -eq "36"} | Sort # Use name, not ID!
$QueryDataExpExtra = (($Roles.content | ConvertFrom-Json).authzRoles | ?{$_.source -eq "experience"}) | ?{$_.name.length -ne "36"} | Sort # Use name, not ID! # User Id
# $QueryDataExp = (($Roles.content | ConvertFrom-Json).authzRoles | ?{$_.source -eq "experience"}).name
$QueryDataIDP = (($Roles.content | ConvertFrom-Json).authzRoles | ?{$_.source -eq "idp"}).id | Sort


if ($QueryDataEthos -eq $null) {
  # Continue
} else {
  $QueryDataEthosCount = @($QueryDataEthos).count
  $QueryDataEthos = """" + $($($QueryDataEthos) -join """,""") + """"
  $QueryEthosBody = "{`"tenantId`":`"$($TENET_ID)`",`"personGUIDs`":[$($QueryDataEthos)]}"
}

if ($QueryDataExp -eq $null) {
  # Continue
} else {
  $QueryDataExpCount = @($QueryDataExp).count
  $QueryDataExp = """" + $($($QueryDataExp) -join """,""") + """"
  $QueryExpBody = "{`"tenantId`":`"$($TENET_ID)`",`"personGUIDs`":[$($QueryDataExp)]}"
}

if ($QueryDataExpExtra -eq $null) {
  # Continue
} else {
  $QueryDataExpExtraCount = @($QueryDataExpExtra).count
}

if ($QueryDataIDP -eq $null) {
  # Continue
} else {
  $QueryDataIDPCount = @($QueryDataIDP).count
  $QueryDataIDP = """" + $($($QueryDataIDP) -join """,""") + """"
}

Write-host "`t Found $QueryDataEthosCount Ethos Roles" -foreground Cyan
Write-host "`t Found $QueryDataExpCount Expirence Roles" -foreground Cyan
Write-host "`t Found $QueryDataIDPCount IDP Roles" -foreground Cyan
Write-host "`t Found $QueryDataExpExtraCount USERID Roles" -foreground Cyan
Write-host "Sleeping $intSleep seconds before continuing" -foreground darkcyan
sleep $intSleep

# The next query is ONLY for EXPIRENCE IDS!!

$KnownUsersData = Invoke-WebRequest -UseBasicParsing -Uri "https://$($strRunEnv)/preferredName" `
-Method "POST" `
-WebSession $session `
-Headers @{
"authority"="$($strRunEnv)"
  "method"="POST"
  "path"="/preferredName"
  "scheme"="https"
  "accept"="*/*"
  "accept-encoding"="gzip, deflate, zstd"
  "accept-language"="en-US,en;q=0.9"
  "cache-control"="no-cache"
  "origin"="https://$($strRunEnv)"
  "pragma"="no-cache"
  "priority"="u=1, i"
  "referer"="https://$($strRunEnv)/roles"
  "sec-ch-ua"="`"Not)A;Brand`";v=`"8`", `"Chromium`";v=`"138`", `"Microsoft Edge`";v=`"138`""
  "sec-ch-ua-mobile"="?0"
  "sec-ch-ua-platform"="`"Windows`""
  "sec-fetch-dest"="empty"
  "sec-fetch-mode"="cors"
  "sec-fetch-site"="same-origin"
} `
-ContentType "application/json" `
-Body "{`"tenantId`":`"$($TENET_ID)`",`"personGUIDs`":[$($QueryDataExp)]}"


# user holder object
$ethosLookup = @{}

# Load Known Users
$KnownUsers = ($KnownUsersData.content | convertfrom-JSON).data
foreach ($kUser in $KnownUsers) {$ethosLookUp.add($($kUser.personGUID),$($kUser.name))}
# $ethosUsers.Guid = Name

# user holder object
$ethosUsers = @{}

$AllRolesDats = ($roles.content | convertFrom-JSon).AuthzRoles
$EthUsers = $AllRolesDats | ?{$_.source -eq "ethos"}
$EthUsersExtra = $AllRolesDats | ?{$_.source -eq "ethos"}
foreach ($eUser in @($EthUsers)) {$ethosUsers.add($($eUser.id),$("[ETHOS ROLE] " + $($eUser.name)))}

$EthUsers = $AllRolesDats | ?{$_.source -eq "idp"}
foreach ($eUser in @($EthUsers)) {$ethosUsers.add($($eUser.id),$("[GROUP] " + $($eUser.name)))}

$EthUsers = $AllRolesDats | ?{$_.source -eq "experience"}
foreach ($eUser in @($EthUsers)) {
  if ($($KnownUsers.PersonGuid) -contains $($eUser.name)) {
    $val = ($KnownUsers | ?{$_.PersonGuid -eq $($eUser.name)}).Name
    $ethosUsers.add($($eUser.id),$("[EXP] " + $val))
  } else {$ethosUsers.add($($eUser.id),$("[EXP] " + $($eUser.name)))}
}

# foreach ($eUser in @($QueryDataExpExtra)) {$ethosUsers.add($($eUser.id),$("[user Id] " + $($eUser.name)))}

$knownInheritance = Invoke-WebRequest -UseBasicParsing -Uri "https://$($strRunEnv)/inheritance/1ce04dfd-0e15-4294-bfaa-361851e993f0" `
-WebSession $session `
-Headers @{
"authority"="$($strRunEnv)"
  "method"="GET"
  "path"="/inheritance/1ce04dfd-0e15-4294-bfaa-361851e993f0"
  "scheme"="https"
  "accept"="*/*"
  "accept-encoding"="gzip, deflate, zstd"
  "accept-language"="en-US,en;q=0.9"
  "cache-control"="no-cache"
  "correlation-id"="8ccb4b7b-f6f1-4610-97ab-b05ef2bc563a"
  "pragma"="no-cache"
  "priority"="u=1, i"
  "referer"="https://$($strRunEnv)/permissions/all-accounts/Ellucian/Insights/Insights/en+en-GB+en-AU+es+fr-CA/Insights"
  "sec-ch-ua"="`"Microsoft Edge`";v=`"141`", `"Not?A_Brand`";v=`"8`", `"Chromium`";v=`"141`""
  "sec-ch-ua-mobile"="?0"
  "sec-ch-ua-platform"="`"Windows`""
  "sec-fetch-dest"="empty"
  "sec-fetch-mode"="cors"
  "sec-fetch-site"="same-origin"
} `
-ContentType "application/json"


# $Content = get-content .\INHEREITANCE_TEST.json | convertFrom-JSOn
$Content = $knownInheritance | convertfrom-Json

# Handle as 2 steps DirtyPolicies ** AND ** InsightsEnablement

write-host "Starting Parsing and identification"
Write-host "Sleeping $intSleep seconds before continuing" -foreground darkcyan
sleep $intSleep

$output = [System.Collections.ArrayList]::new()

write-host "`t [1/2] Insights Enablements ..."
$Rows = $content.insightsEnablement.actions
foreach ($row in $rows) {
  $user = ""
  if ($ethosUsers."$($row.role.id)") {
    $user = $ethosUsers."$($row.role.id)"
  } else {
   $user = "[UNK] $($row.role.name) ($($row.role.id))"
  }
  
  foreach ($act in $row.policy.actions) {
    $Permission = ""
    $PermissionReason = ""

    $Permission = $act.name
    $PermissionReason = ($act.displayTitles | ?{$_.language -eq "en"}).information

    $PSOLine = [pscustomobject]@{
      Application = $row.resource.Interface
      Permission = $Permission
      User = $user    
      Path = ($row.resource.displayTitles | ?{$_.language -eq "en"}).title
      PathChange = $row.change.collectionPath
      PermissionAction = $row.change.actionToTake
      PermissionReason = $PermissionReason
      ChangeReason = $row.change.reason
    }
    $output += $PSOLine
  }
}


## DIRTY POLICIES
write-host "`r`n`t [2/2] Dirty Policies ..."
$Rows = $content.dirtyPolicies
foreach ($row in $rows) {
  $user = ""
  if ($ethosUsers."$($row.role.id)") {
    $user = $ethosUsers."$($row.role.id)"
  } else {
   $user = "[UNK] $($row.role.name) ($($row.role.id))"
  }

  foreach ($act in $row.policy.actions) {
    $PSOLine = [pscustomobject]@{
      Application = $row.resource.Interface
      Permission = $act.name
      User = $user    
      Path = ($row.resource.displayTitles | ?{$_.language -eq "en"}).title
      PathChange = ""
      PermissionAction = $row.change.actionToTake
      PermissionReason = ""
      ChangeReason = ""
    }
    $output += $PSOLine
  }
}

$output | export-csv -notypeinformation $fileOutput
write-host "Wrote - $($fileOutput)" -foreground cyan

# stop-transcript

# End of File