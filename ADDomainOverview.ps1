<#
.SYNOPSIS
    This script retrieves extensive information about the Active Directory domain, including user, group, and computer counts,
    group policies, domain controllers with their IP addresses, and domain functional information. It then sends the results
    in an HTML email with a structured report.

.DESCRIPTION
    The script fetches user, group, computer, group policy, domain controller, and domain functional level information,
    and sends it in an HTML email. The email provides a comprehensive overview of the domain for someone new to the project.

.NOTES
    Script Name    : ADDomainOverview.ps1
    Version        : 0.1
    Author         : [Your Name]
    Approved By    : [Approver's Name]
    Date           : [Date]
    Purpose        : To generate a comprehensive report about the domain, including users, groups, computers, GPOs,
                    domain controllers, and domain functional levels.

.PREREQUISITES
    - Active Directory module for PowerShell (RSAT) should be installed on the machine running the script.
    - The user running the script should have sufficient permissions to query Active Directory.

.PARAMETERS
    None.

.EXAMPLE
    This script generates a report and sends it via email:
    ADDomainOverview.ps1
#>

# Start of Script

# Import the Active Directory module (if not already loaded)
Import-Module ActiveDirectory

# Email parameters
$EmailFrom = "admin@yourdomain.com"
$EmailTo = "recipient@domain.com"
$EmailSubject = "Comprehensive AD Domain Overview"
$SMTPServer = "smtp.yourdomain.com"

# Get domain functional level and forest functional level
$domainInfo = Get-ADDomain
$forestInfo = Get-ADForest

# Get domain controllers with their IP addresses
$domainControllers = Get-ADDomainController -Filter * | Select-Object Name, IPv4Address

# Get counts of users (enabled and disabled)
$enabledUsers = Get-ADUser -Filter {Enabled -eq $true} | Measure-Object | Select-Object -ExpandProperty Count
$disabledUsers = Get-ADUser -Filter {Enabled -eq $false} | Measure-Object | Select-Object -ExpandProperty Count

# Get total groups and empty groups
$totalGroups = Get-ADGroup -Filter * | Measure-Object | Select-Object -ExpandProperty Count
$emptyGroups = Get-ADGroup -Filter * | Where-Object { (Get-ADGroupMember -Identity $_.DistinguishedName).Count -eq 0 } | Measure-Object | Select-Object -ExpandProperty Count

# Get computers and their operating systems
$computers = Get-ADComputer -Filter * | Select-Object Name, OperatingSystem
$computersCount = $computers.Count
$osTypes = $computers | Group-Object OperatingSystem | Select-Object Name, Count

# Get Group Policies
$gpos = Get-GPO -All | Select-Object DisplayName, GpoStatus, Id
$totalGPOs = $gpos.Count
$enabledGPOs = $gpos | Where-Object { $_.GpoStatus -eq 'Enabled' } | Measure-Object | Select-Object -ExpandProperty Count
$disabledGPOs = $gpos | Where-Object { $_.GpoStatus -eq 'Disabled' } | Measure-Object | Select-Object -ExpandProperty Count

# Prepare the email body in HTML format
$EmailBody = @"
<html>
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
        }
        .box {
            border: 1px solid #ccc;
            padding: 15px;
            margin: 20px 0;
            background-color: #f9f9f9;
        }
        .title {
            font-weight: bold;
            font-size: 16px;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <h2>Comprehensive AD Domain Overview</h2>

    <div class="box">
        <div class="title">Domain Information:</div>
        <p><strong>Domain Name:</strong> $($domainInfo.Name)</p>
        <p><strong>Domain Functional Level:</strong> $($domainInfo.DomainMode)</p>
        <p><strong>Forest Functional Level:</strong> $($forestInfo.ForestMode)</p>
    </div>

    <div class="box">
        <div class="title">Domain Controllers:</div>
        <ul>
            $($domainControllers | ForEach-Object { "<li><strong>$($_.Name):</strong> $($_.IPv4Address)</li>" })
        </ul>
    </div>

    <div class="box">
        <div class="title">Users Count:</div>
        <p><strong>Enabled Users:</strong> $enabledUsers</p>
        <p><strong>Disabled Users:</strong> $disabledUsers</p>
    </div>

    <div class="box">
        <div class="title">Groups Count:</div>
        <p><strong>Total Groups:</strong> $totalGroups</p>
        <p><strong>Empty Groups:</strong> $emptyGroups</p>
    </div>

    <div class="box">
        <div class="title">Computers Count:</div>
        <p><strong>Total Computers:</strong> $computersCount</p>
        <p><strong>Operating System Breakdown:</strong></p>
        <ul>
            $($osTypes | ForEach-Object { "<li><strong>$($_.Name):</strong> $($_.Count)</li>" }) 
        </ul>
    </div>

    <div class="box">
        <div class="title">Group Policies Count:</div>
        <p><strong>Total GPOs:</strong> $totalGPOs</p>
        <p><strong>Enabled GPOs:</strong> $enabledGPOs</p>
        <p><strong>Disabled GPOs:</strong> $disabledGPOs</p>
    </div>
</body>
</html>
"@

# Send the email
Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -Body $EmailBody -BodyAsHtml $true -SmtpServer $SMTPServer

# End of Script