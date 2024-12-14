<#
.SYNOPSIS
This script checks for disabled computer accounts in the entire domain and moves them 
to the "Disabled Computers" OU. It also sends an email with the count of computers moved 
and their names.

.DESCRIPTION
The script will search for all disabled computer accounts in the domain and move them to 
the "Disabled Computers" OU. After moving the computers, an email will be sent containing 
the count of the computers moved and a list of their names.

.NOTES
    Script Name    : Move-DisabledComputers.ps1
    Version        : 1.0
    Author         : [Your Name]
    Approved By    : [Approver's Name]
    Date           : [Date]
    Purpose        : To automate the movement of disabled computer objects to the "Disabled Computers" OU
                     and send an email notification with the details.

.PREREQUISITES
    - The script requires the Active Directory PowerShell module to be installed.
    - SMTP server and email parameters must be configured for sending email.
    - The "Disabled Computers" OU must already exist in the domain.

.PARAMETERS
    None

.EXAMPLE
    Move-DisabledComputers.ps1
    This will move all disabled computers to the "Disabled Computers" OU and send an email with the results.

#>

# Start of script

# Define the target OU for disabled computers
$disabledComputersOU = "OU=Disabled Computers,DC=domain,DC=com"

# Email parameters
$EmailFrom = "admin@domain.com"
$EmailTo = "recipient@domain.com"
$SMTPServer = "smtp.domain.com"
$EmailSubject = "Disabled Computers Moved Notification"

# Get all disabled computers in the domain
$disabledComputers = Get-ADComputer -Filter {Enabled -eq $false} -Properties DistinguishedName

# Initialize a list to store moved computers
$movedComputers = @()

# Loop through each disabled computer and move it to the "Disabled Computers" OU
foreach ($computer in $disabledComputers) {
    # Move the computer to the Disabled Computers OU
    Move-ADObject -Identity $computer.DistinguishedName -TargetPath $disabledComputersOU

    # Add the computer name to the list of moved computers
    $movedComputers += $computer.Name
}

# Get the count of moved computers
$computersMovedCount = $movedComputers.Count

# Create the email body with the count and names of moved computers
$EmailBody = @"
$computersMovedCount computers were moved to the 'Disabled Computers' OU.

List of moved computers:
$($movedComputers -join "`n")

Date: $(Get-Date)

This email is to notify that the disabled computers have been successfully moved to the 'Disabled Computers' OU.
"@

# Send email notification
Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -Body $EmailBody -SmtpServer $SMTPServer

# End of script