<#
.SYNOPSIS
    Adds users from all “Users” OUs under specific parent OUs to the Specific AD group 
    and emails a summary of newly added users.

.DESCRIPTION
    Optimized version for performance:
    - Loads existing group members once.
    - Checks membership in memory.
    - Adds users in bulk per OU.
    - Processes only the top-level "Users" OU (no sub-OUs).
    - Maintains the same output and email logic.

.NOTES
    Script Name    : Add-GroupToMembers.ps1
    Version        : 1.0
    Author         : Jonathan Preetham
    Approved By    : [Approver’s Name]
    Date           : [Date]
    Purpose        : To ensure all users under defined “Users” OUs are members of the group 
                     and generate an automated summary report of the additions.

.PREREQUISITES
    - ActiveDirectory PowerShell module must be installed.
    - The executing account must have permissions to read OUs and modify group membership.
    - SMTP server must allow relay from the executing host for email delivery.

.PARAMETERS
    -WhatIf
        Runs the script in simulation mode to show what changes would be made without modifying AD.

.EXAMPLE
    Example 1:
        PS C:\> .\Add-GroupToMembers.ps1
        → Executes the script in live mode and adds missing users to the group.

    Example 2:
        PS C:\> .\Add-GroupToMembers.ps1 -WhatIf
        → Simulates the process without making any changes in AD, but still generates and emails the report.
#>

param(
    [switch]$WhatIf
)

Import-Module ActiveDirectory

# ================== CONFIGURABLE SECTION ==================
    # You can add your domain name as well
    # If there are multiple Users OU, ensure to add the Parent OU which contains the Sub-OU's
$ParentOUs = @(
    "OU=NA,DC=contoso,DC=contoso,DC=com",
    "OU=NA,DC=contoso,DC=contoso,DC=com"
    #"OU=NA,DC=contoso,DC=contoso,DC=com",
    #"OU=NA,DC=contoso,DC=contoso,DC=com"
)

$GroupName   = "GroupName"
$SMTPServer  = "SMTP Address or IP"
$From        = "DL Recommended"
$To          = "User Email or DL"
$Cc          = "vUser Email or DL", "User Email or DL"
$Subject     = "Group - Newly Added Members Report"
# ===========================================================


$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$AddedUsersFile = "AddedUsers_$timestamp.csv"
$NewlyAddedUsers = @()

Write-Host "`nStarting optimized $GroupName group update..." -ForegroundColor Cyan

# Load current group members once
Write-Host "Loading existing '$GroupName' members..." -ForegroundColor Yellow
$currentGroupMembers = (Get-ADGroupMember -Identity $GroupName -Recursive | Select-Object -ExpandProperty DistinguishedName)
Write-Host "Total current members: $($currentGroupMembers.Count)" -ForegroundColor Gray

$TotalParentOUs = $ParentOUs.Count
$ParentOUIndex = 0

foreach ($ParentOU in $ParentOUs) {
    $ParentOUIndex++
    Write-Progress -Activity "Scanning Parent OUs" `
                   -Status "Processing $ParentOU ($ParentOUIndex of $TotalParentOUs)" `
                   -PercentComplete (($ParentOUIndex / $TotalParentOUs) * 100)

    # Find only OUs named "Users" under each parent OU
    $UserOUs = Get-ADOrganizationalUnit -SearchBase $ParentOU -Filter 'Name -eq "Users"'
    $OUCount = $UserOUs.Count
    $OUIndex = 0

    foreach ($OU in $UserOUs) {
        $OUIndex++
        Write-Progress -Activity "Processing OUs" `
                       -Status "Checking OU: $($OU.DistinguishedName) ($OUIndex of $OUCount)" `
                       -PercentComplete (($OUIndex / $OUCount) * 100)

        Write-Host "→ Checking OU: $($OU.DistinguishedName)" -ForegroundColor Yellow

        # Get all users directly in the OU (do NOT include sub-OUs)
        $Users = Get-ADUser -SearchBase $OU.DistinguishedName -SearchScope OneLevel -Filter * -Properties mail, DistinguishedName, SamAccountName

        if ($Users.Count -eq 0) {
            Write-Host "   No users found in $($OU.DistinguishedName)" -ForegroundColor DarkGray
            continue
        }

        # Filter users not already in group (using in-memory comparison)
        $UsersToAdd = $Users | Where-Object { $currentGroupMembers -notcontains $_.DistinguishedName }

        if ($UsersToAdd.Count -gt 0) {
            if ($WhatIf) {
                Write-Host "   [$($UsersToAdd.Count)] users would be added (simulation mode)." -ForegroundColor Cyan
                $UsersToAdd | ForEach-Object {
                    $NewlyAddedUsers += [PSCustomObject]@{
                        SamAccountName    = $_.SamAccountName
                        DistinguishedName = $_.DistinguishedName
                        EmailAddress      = $_.mail
                        OU                = $OU.DistinguishedName
                        Action            = "Would Add"
                    }
                }
            }
            else {
                Write-Host "   Adding $($UsersToAdd.Count) users to group..." -ForegroundColor Green
                try {
                    # Add all users in one go (bulk add)
                    Add-ADGroupMember -Identity $GroupName -Members $UsersToAdd.DistinguishedName -ErrorAction Stop

                    $UsersToAdd | ForEach-Object {
                        $NewlyAddedUsers += [PSCustomObject]@{
                            SamAccountName    = $_.SamAccountName
                            DistinguishedName = $_.DistinguishedName
                            EmailAddress      = $_.mail
                            OU                = $OU.DistinguishedName
                            Action            = "Added"
                        }
                    }

                    # Update in-memory list of group members
                    $currentGroupMembers += $UsersToAdd.DistinguishedName
                }
                catch {
                    Write-Warning "Failed to add some users in $($OU.DistinguishedName): $_"
                }
            }
        }
        else {
            Write-Host "   No new users to add in this OU." -ForegroundColor DarkGray
        }

        Write-Host "✓ Completed $($OU.DistinguishedName)`n" -ForegroundColor Green
    }
}

# ================== REPORT SECTION ==================
Write-Progress -Activity "Finalizing report" -Status "Compiling CSV and email..." -PercentComplete 100
Write-Host "`nGenerating report and sending email..." -ForegroundColor Cyan

if ($NewlyAddedUsers.Count -gt 0) {
    $NewlyAddedUsers | Export-Csv -Path $AddedUsersFile -NoTypeInformation -Encoding UTF8

    $AddedCount = ($NewlyAddedUsers | Where-Object { $_.Action -eq 'Added' }).Count
    $ActionWord = if ($WhatIf) { "simulated for addition" } else { "added" }

    $Body = @"
Hello,

The following report contains users from 'Users' OUs that were $ActionWord to the '$GroupName' group.

Total Users Processed: $($NewlyAddedUsers.Count)
Total Users Added: $AddedCount

Please find the attached CSV report for full details.

Regards,
Active Directory Automation

NOTE: SCRIPT RUNS ON 
"@

    #Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Attachments $AddedUsersFile
    Send-MailMessage -From $From -To $To -Cc $Cc -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Attachments $AddedUsersFile

}
else {
    $Body = "No new users were found for addition to the '$GroupName' group during this run."
    Send-MailMessage -From $From -To $To -Cc $Cc -Subject $Subject -Body $Body -SmtpServer $SMTPServer

}

Write-Progress -Activity "Completed" -Completed
Write-Host "`n✅ Script completed successfully!" -ForegroundColor Green
