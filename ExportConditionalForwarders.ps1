<#
.SYNOPSIS
    This script exports the list of conditional forwarders from a DNS server.

.DESCRIPTION
    This script retrieves the conditional forwarders configured on a DNS server and exports the details to a CSV file.
    The script can be scheduled to run periodically or manually executed for auditing purposes.
    No modifications are required except for specifying the correct DNS server and output file path.

.NOTES
    Script Name    : ExportConditionalForwarders.ps1
    Version        : 0.1
    Author         : [Your Name]
    Approved By    : [Approver's Name]
    Date           : [Date]
    Purpose        : To export the list of conditional forwarders from a DNS server.

.PREREQUISITES
    - The script requires administrative privileges on the DNS server.
    - The DNS server must be accessible from the machine where the script is run.
    - The script requires the DNS Server module in PowerShell.

.PARAMETERS
    None.

.EXAMPLE
    This script exports the conditional forwarders to a CSV file:
    ExportConditionalForwarders.ps1
#>

# Start of Script

# DNS Server and Output File Path
$dnsServer = "YourDNSServerName"  # Replace with the DNS server name or IP address
$outputFile = "C:\Path\To\Output\conditional_forwarders.csv"  # Replace with desired output file path

# Get the list of conditional forwarders
$conditionalForwarders = Get-DnsServerConditionalForwarderZone -ComputerName $dnsServer

# Export the conditional forwarders to CSV
$conditionalForwarders | Select-Object Name, MasterServers, LastUpdated | Export-Csv -Path $outputFile -NoTypeInformation

# End of Script