<#
.SYNOPSIS
    Trigger an alert for a specific event related to Computer Object Deletion.

.DESCRIPTION
    This script monitors and triggers an alert when a computer object is deleted in Active Directory.
    It fetches the event details from the Security log of the local domain controller where the script runs.
    Note: This script triggers alerts only for events logged on the specific domain controller where it is executed. 
    Events from other domain controllers are not captured.

.NOTES
    Script Name    : ComputerObjectDeletionAlert.ps1
    Version        : 0.1
    Author         : [Your Name]
    Approved By    : Marty
    Date           : [Date]
    Purpose        : To monitor and alert on computer object deletion events on the local domain controller.

.PREREQUISITES
    - Scheduled Task configured to execute this script on the domain controller.
    - Proper SMTP configuration for email alerts.

.PARAMETERS
    None.

.EXAMPLE
    This script runs as part of a scheduled task:
    ComputerObjectDeletionAlert.ps1
#>

# Start of Script

# Storing EventID in a variable
$EventId = 4743

# Fetching the Event Information
# Note: This fetches events only from the local domain controller's Security log.
$A = Get-WinEvent -MaxEvents 1 -FilterHashTable @{Logname = "Security"; ID = $EventId}
$Message = $A.Message
$EventID = $A.Id
$MachineName = $A.MachineName
$Source = $A.ProviderName

# Email Parameters
$PCName = $env:COMPUTERNAME
$EmailBody = "EventID: $EventID`nSource: $Source`nMachineName: $MachineName`nMessage: $Message"
$EmailFrom = "cognizant-activedirectoryteam@cabotcorp.com"
$EmailTo = "v-Jonathan.Preetham@cabotcorp.com"
$EmailSubject = "ALERT: Computer Object Deleted"
$SMTPServer = "smtp-pp.cabot.cabot-corp.com"

# Sending Email
Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -Body $EmailBody -SmtpServer $SMTPServer

# End of Script