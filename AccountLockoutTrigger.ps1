<#
.SYNOPSIS
    This script triggers an alert when an account lockout event occurs.

.DESCRIPTION
    This script is used to monitor and trigger an alert when an account lockout event (Event ID 4740) is logged in the Security log.
    The task has been scheduled under Task Scheduler to run this script automatically when the event occurs.
    No modifications are required except for updating the "emailTo" field for notifications.

.NOTES
    Script Name    : AccountLockoutTrigger.ps1
    Version        : 0.1
    Author         : 
    Approved By    : 
    Date           : 
    Purpose        : To send an email notification when an account lockout event is triggered.

.PREREQUISITES
    - The script must be scheduled to run via Task Scheduler.
    - The correct email address should be provided in the "emailTo" field.
    - The script requires permissions to read event logs and send emails via SMTP.

.PARAMETERS
    None.

.EXAMPLE
    This script runs as part of a scheduled task:
    AccountLockoutTrigger.ps1
#>

# Start of Script

# Storing EventID In A Variable
$EventId = 4740

# One Line Command For Fetching The Event Information
$A = Get-WinEvent -MaxEvents 1 -FilterHashTable @{Logname = "Security" ; ID = $EventId}
$Message = $A.Message
$EventID = $A.Id
$MachineName = $A.MachineName
$Source = $A.ProviderName

# Email Parameters
$PCName = $env:COMPUTERNAME
$EmailBody = "EventID: $EventID`nSource: $Source`nMachineName: $MachineName `nMessage: $Message"
$EmailFrom = "From-Address"

# Define multiple recipients
$EmailTo = @(
    "email1@example.com",
    "email2@example.com",
    "email3@example.com"
)  # Add as many email addresses as needed

$EmailSubject = "ALERT: Account Locked Out"
$SMTPServer = "SMTP-Address"

# Sending Email
Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -Body $EmailBody -SmtpServer $SMTPServer

# End of Script