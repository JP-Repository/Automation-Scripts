<#
.SYNOPSIS
This script checks the computer names for specific three-letter location keywords
and moves them to the corresponding Organizational Unit (OU). It also sends an email 
notification whenever a computer object is moved.

.DESCRIPTION
The script will loop through all computers in the "Computers" OU and check their names for 
specific location keywords (e.g., "BAR", "LON"). If a match is found, the computer will 
be moved to the corresponding OU based on the location keyword. An email will be sent with 
the computer's information whenever it is moved.

.NOTES
    Script Name    : Move-ComputersToOU.ps1
    Version        : 1.0
    Author         : [Your Name]
    Approved By    : [Approver's Name]
    Date           : [Date]
    Purpose        : To automate the movement of computer objects based on naming convention 
                     and send an email notification.

.PREREQUISITES
    - The script assumes that the computers are already present in the "Computers" OU.
    - The script requires the Active Directory PowerShell module to be installed.
    - SMTP server and email parameters must be configured for sending email.

.PARAMETERS
    None

.EXAMPLE
    Move-ComputersToOU.ps1
    This will move the computers based on the naming convention to their respective OUs 
    and send an email notification for each move.

#>

# Start of script

# Define the mapping of keywords to target OUs
$ouMapping = @{
    "BAR" = "OU=Barry,DC=domain,DC=com"
    "LON" = "OU=Loncin,DC=domain,DC=com"
    "NYC" = "OU=NewYork,DC=domain,DC=com"
}

# Email parameters
$EmailFrom = "admin@domain.com"
$EmailTo = "recipient@domain.com"
$SMTPServer = "smtp.domain.com"
$EmailSubject = "Computer Object Moved Notification"

# Get all computers in the "Computers" OU
$computers = Get-ADComputer -Filter * -SearchBase "OU=Computers,DC=domain,DC=com"

# Loop through each computer
foreach ($computer in $computers) {
    $computerName = $computer.Name

    # Check if the computer name contains any of the defined location keywords
    foreach ($key in $ouMapping.Keys) {
        if ($computerName.StartsWith($key)) {
            $targetOU = $ouMapping[$key]

            # Move the computer to the respective OU
            Move-ADObject -Identity $computer.DistinguishedName -TargetPath $targetOU
            Write-Host "Moved computer '$computerName' to OU: $targetOU"

            # Create the email body with the computer's information
            $EmailBody = @"
Computer Name: $computerName
Moved To: $targetOU
Date: $(Get-Date)

This email is to notify that the computer object '$computerName' has been moved to the OU '$targetOU'.
"@

            # Send email notification
            Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -Body $EmailBody -SmtpServer $SMTPServer
            break  # Exit the loop once the computer is moved
        }
    }
}

# End of script