<#
.SYNOPSIS
    Powershell script for creating a new folder with the current date and executing commands in a phased manner to generate and save reports.

.DESCRIPTION
    This script automates the following tasks:
    - Removes folders older than 30 days.
    - Creates new folders with the current date for backup purposes.
    - Generates various reports for Active Directory users, computers, domain controllers, and GPOs.
    - Sends an email notification upon successful completion.

.NOTES
    Script Name    : Weekly_GPO_Backup.ps1
    Version        : 1.0
    Author         : [Your Name]
    Approved By    : [Approver's Name]
    Date           : [Date]
    Purpose        : Automate weekly Active Directory and GPO backup processes.

.PREREQUISITES
    - Active Directory and Group Policy PowerShell modules installed.
    - Access to the required network paths and SMTP server.
    - Appropriate permissions to execute AD and GPO commands.

.PARAMETERS
    None.

.EXAMPLE
    Run the script directly:
    .\Weekly_GPO_Backup.ps1

#>

# Start of Script

# Remove folders older than 30 days
Get-ChildItem -Path "\\ServerName\Weekly_GPO_Backup" -Directory -Recurse | 
    Where-Object {$_.LastWriteTime -le (Get-Date).AddDays(-30)} | 
    Remove-Item -Recurse -Force

# Import required modules
Import-Module ActiveDirectory
Import-Module GroupPolicy

# Create a new folder for HTML backups
$Path = "\\ServerName\Weekly_GPO_Backup\HTML_Backup_" + (Get-Date).ToString("dd-MM-yyyy")
New-Item -Path $Path -ItemType Directory -Force
Set-Location -Path $Path -PassThru

# Generate reports
Get-ADUser -Filter * -Properties * | Export-Csv -Path "AllUsers_$(Get-Date -Format dd-MM-yyyy).csv" -NoTypeInformation
Get-ADUser -Filter * -Properties Name,SamAccountName,Enabled,EmailAddress,DistinguishedName,Description,LastLogonTimestamp,LastLogonDate,Department,WhenCreated,Location | 
    Select-Object Name,SamAccountName,Enabled,EmailAddress,DistinguishedName,Description,LastLogonTimestamp,LastLogonDate,Department,WhenCreated,Location | 
    Sort-Object -Property Name | 
    Export-Csv -Path "AllUsers_$(Get-Date -Format dd-MM-yyyy).csv" -NoTypeInformation

Get-ADComputer -Filter * -Properties * | Export-Csv -Path "AllComputers_$(Get-Date -Format dd-MM-yyyy).csv" -NoTypeInformation
Get-ADComputer -Filter * -Properties Name,CanonicalName,DistinguishedName,Description,LastLogonDate,LastLogonTimestamp,ms-Mcs-AdmPwd,ms-Mcs-AdmPwdExpirationTime,Enabled,OperatingSystem,WhenCreated | 
    Select-Object Name,CanonicalName,DistinguishedName,Description,LastLogonDate,LastLogonTimestamp,ms-Mcs-AdmPwd,ms-Mcs-AdmPwdExpirationTime,Enabled,OperatingSystem,WhenCreated | 
    Sort-Object -Property Name | 
    Export-Csv -Path "AllComputers_$(Get-Date -Format dd-MM-yyyy).csv" -NoTypeInformation

Get-ADDomainController -Filter * | Export-Csv -Path "All_DCs_$(Get-Date -Format dd-MM-yyyy).csv" -NoTypeInformation
Get-GPO -All | Export-Csv -Path "GPO_Backup_$(Get-Date -Format dd-MM-yyyy).csv" -NoTypeInformation
Get-GPO -All | ForEach-Object { $_.GenerateReport('html') | Out-File -FilePath "$($_.DisplayName).html" }

# Backup GPOs
$Path1 = "\\ServerName\Weekly_GPO_Backup\GPO_Backup_" + (Get-Date).ToString("dd-MM-yyyy")
New-Item -Path $Path1 -ItemType Directory -Force
Backup-GPO -All -Path $Path1
$ErrorActionPreference = 'SilentlyContinue'

# Email notification
$HTMLFolder = Get-ChildItem -Path "\\ServerName\Weekly_GPO_Backup\" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$HTMLFolderCount = (Get-ChildItem -Path $HTMLFolder.FullName -Recurse | Measure-Object).Count

$FromAddress = "From-email-address"
$ToAddress = "to-email-address"
$MessageSubject = "WEEKLY HTML BACKUP"
$MessageBody = @"
Hi Team,

Good Day...

HTML Back-Up is Completed Successfully.

New Folder is created with today's date as $($HTMLFolder.FullName) & Total No of files within the new folder is $HTMLFolderCount.

Thanks & Regards,
Active Directory
"@

$SendingServer = "smtp-address"
$SMTPMessage = New-Object System.Net.Mail.MailMessage $FromAddress, $ToAddress, $MessageSubject, $MessageBody
$SMTPClient = New-Object System.Net.Mail.SmtpClient $SendingServer
$SMTPClient.Send($SMTPMessage)

# End of Script