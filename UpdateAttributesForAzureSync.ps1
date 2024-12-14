<#
.SYNOPSIS
    This script updates attributes for accounts and groups in the Azure China Tenant.

.DESCRIPTION
    This script is specifically written for the Azure China Tenant to update attributes for both accounts and groups.
    The task has been scheduled in Task Scheduler to run this script periodically. 
    No modifications are required unless confirmed by Marty. 

.NOTES
    Script Name    : UpdateAttributesForAzureSync.ps1
    Version        : 0.1
    Author         : [Your Name]
    Approved By    : Marty
    Date           : [Date]
    Purpose        : To update a specified attribute for all accounts and groups in a defined Organizational Unit (OU).

.PREREQUISITES
    - The script is scheduled to run under Task Scheduler.
    - Proper permissions to update attributes in Active Directory.
    - Ensure the OU and attribute details are correctly defined before execution.

.PARAMETERS
    None.

.EXAMPLE
    This script runs as part of a scheduled task:
    UpdateAttributesForAzureChinaTenant.ps1
#>

# Start of Script

# Defined OU "Organizational Unit", Attribute Name, Attribute Value
$ouDN = ""  # Define the distinguished name (DN) of the OU
$attributeName = "adminDescription"  # The attribute to be updated
$attributeValue = "AZCN"  # The value to set for the attribute

# Storing AD Groups From Defined OU In A Variable
$groupsInOU = Get-ADGroup -SearchBase $ouDN -Filter *

# Using A Simple ForEach Command To Loop Through Those Groups
foreach ($group in $groupsInOU) {

    # Update The Attribute For AD Groups In Defined OU
    Set-ADGroup -Identity $group.SamAccountName -Replace @{ $attributeName = $attributeValue }

    # Fetch Group Members
    $groupMembers = Get-ADGroupMember -Identity $group -Recursive | Where-Object { $_.objectClass -eq 'user' }

    # Loop Through Each Member And Update The Attribute
    foreach ($member in $groupMembers) {
        # Update the attribute for the user
        Set-ADUser -Identity $member.SamAccountName -Replace @{ $attributeName = $attributeValue }
    }
}

# End of Script