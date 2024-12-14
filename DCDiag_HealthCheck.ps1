<#
.SYNOPSIS
Generates a health report for Active Directory Domain Controllers and sends it via email.

.DESCRIPTION
This script performs the following tasks:
1. Runs `dcdiag` on all domain controllers to check their health.
2. Retrieves information about critical Active Directory services (e.g., NTDS, NetLogon, DFSR).
3. Collects system information such as uptime, memory usage, CPU usage, and free space on the C: drive.
4. Compiles the results into an HTML report.
5. Sends the report via email using the specified SMTP server.

.NOTES
This script has been modified and customized to suit specific requirements.
I am not the original owner of this script, and it may have been sourced or inspired by existing templates.
All credits to the original author(s) for the foundational structure.

.VERSION
1.0

.AUTHOR
Modified by [Your Name]
#>

#==============================================================================================================
# Import Active Directory Module
Import-Module ActiveDirectory

#==============================================================================================================
# Define Variables
$DomainName = (Get-ADDomain).DNSRoot
$ServerNames = Get-ADDomainController -Filter * -Server $DomainName | Select-Object Name -ExpandProperty Name

# Email Parameters
$SubDate = (Get-Date).ToString('MMMM-dd')
$subject = "$DomainName DC Diag Health Check - $SubDate"
$priority = "Normal"
$smtpServer = "smtp.yourdomain.com"
$emailFrom = "admin@yourdomain.com"
$emailTo = "recipient@yourdomain.com"
$port = 25

#==============================================================================================================
# Functions

# Function to get system information
function Get-ADSystem {
    param ($Server)
    $Server = $Server.Trim()
    $Object = "" | Select-Object ServerName, BootUpTime, UpTime, "Physical RAM", "C: Free Space", "Memory Usage", "CPU usage"
    $Object.ServerName = $Server

    # OS details
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Server -ErrorAction SilentlyContinue
    if ($os) {
        $LastBootUpTime = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
        $LocalDateTime = [Management.ManagementDateTimeConverter]::ToDateTime($os.LocalDateTime)
        $uptime = ($LocalDateTime - $LastBootUpTime)
        $Object.BootUpTime = $LastBootUpTime
        $Object.UpTime = "$($uptime.Days) days, $($uptime.Hours)h, $($uptime.Minutes)mins"
    } else {
        $Object.BootUpTime = "(null)"
        $Object.UpTime = "(null)"
    }

    # Physical RAM
    $PhysicalRAM = (Get-CimInstance -ClassName Win32_PhysicalMemory -ComputerName $Server | 
                    Measure-Object -Property Capacity -Sum | 
                    ForEach-Object { [Math]::Round($_.Sum / 1GB, 2) })
    $Object."Physical RAM" = if ($PhysicalRAM) { "$PhysicalRAM GB" } else { "(null)" }

    # Memory Usage
    $MemUsage = (Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Server | 
                 ForEach-Object { "{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) * 100) / $_.TotalVisibleMemorySize) })
    $Object."Memory Usage" = if ($MemUsage) { "$MemUsage %" } else { "(null)" }

    # CPU Usage
    $CpuUsage = (Get-CimInstance -ClassName Win32_Processor -ComputerName $Server | 
                 Measure-Object -Property LoadPercentage -Average | 
                 ForEach-Object { $_.Average })
    $Object."CPU usage" = if ($CpuUsage) { "$CpuUsage %" } else { "(null)" }

    # Free Space on C:
    $FreeSpace = (Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $Server -Filter "DeviceID='C:'" | 
                  ForEach-Object { [Math]::Round($_.FreeSpace / 1GB, 2) })
    $Object."C: Free Space" = if ($FreeSpace) { "$FreeSpace GB" } else { "(null)" }

    return $Object
}

# Function to run DCDiag
function Get-DCDiag {
    param ($Computername)
    $Dcdiag = (Dcdiag.exe /s:$Computername) -split ('[\r\n]')
    $Results = New-Object PSObject -Property @{ ServerName = $Computername }
    foreach ($line in $Dcdiag) {
        if ($line -match "Starting test: (.+)") {
            $TestName = $matches[1].Trim()
        }
        if ($line -match "(passed|failed) test") {
            $TestStatus = if ($line -match "passed") { "Passed" } else { "Failed" }
            $Results | Add-Member -Name $TestName -Value $TestStatus -MemberType NoteProperty -Force
        }
    }
    return $Results
}

# Function to get AD Services status
function Get-ADServices {
    param ($Computername)
    $ServiceNames = "HealthService","NTDS","NetLogon","DFSR"
    $Services = Get-Service -ComputerName $Computername -Name $ServiceNames -ErrorAction SilentlyContinue
    if ($Services) {
        $Object = New-Object PSObject -Property @{ ServerName = $Computername }
        foreach ($Service in $Services) {
            $Object | Add-Member -Name $Service.Name -Value $Service.Status -MemberType NoteProperty -Force
        }
        return $Object
    }
}

#===============================================================================================================
# Generate Report
$output = @()
$output += '<html><head></head><body>'
$output += "<h2 style='color: #0B2161'>Domain Controllers DCDiag Report On $DomainName</h2>"

foreach ($Server in $ServerNames) {
    if (Test-Connection -ComputerName $Server -Count 1 -Quiet) {
        $DCDiag = Get-DCDiag -Computername $Server
        $ADServices = Get-ADServices -Computername $Server
        $ADSystem = Get-ADSystem -Server $Server

        $output += "<h4>Server: $Server</h4>"
        $output += "<h5>DCDiag:</h5>" + ($DCDiag | ConvertTo-Html -Fragment)
        $output += "<h5>AD Services:</h5>" + ($ADServices | ConvertTo-Html -Fragment)
        $output += "<h5>System Information:</h5>" + ($ADSystem | ConvertTo-Html -Fragment)
    } else {
        Write-Warning "Unable to reach $Server"
    }
}

$output += "<h5>Date and time: $(Get-Date)</h5>"
$output += '</body></html>'

#===============================================================================================================
# Send Email
Send-MailMessage -To $emailTo -From $emailFrom -Subject $subject -BodyAsHtml $output -SmtpServer $smtpServer -Port $port -Priority $priority