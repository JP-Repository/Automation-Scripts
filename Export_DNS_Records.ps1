<#
.SYNOPSIS
    PowerShell script to export all records present in the Forward Lookup Zone.

.DESCRIPTION
    This script automates the following tasks:
    - Removes folders older than 15 days.
    - Imports the DNS Server module.
    - Creates a new folder with the current date.
    - Exports DNS records from the Forward Lookup Zone to the newly created folder.

.NOTES
    Script Name    : Export_DNS_Records.ps1
    Version        : 0.2
    Author         : [Your Name]
    Approved By    : Marty
    Date           : [Date]
    Purpose        : Automate daily DNS record backups for Forward Lookup Zones.

.PREREQUISITES
    - PowerShell DNS Server module must be installed.
    - Permissions to access and manage DNS Server and folder paths.
    - Ensure the script is executed on a machine with access to the DNS server.

.PARAMETERS
    None.

.EXAMPLE
    Run the script directly:
    .\Export_DNS_Records.ps1

#>

# Start of Script

# Remove folders older than 15 days
Get-ChildItem -Path "\\mdc-ntb01\c$\Temp\Daily_DNSReports_Backup" -Directory -Recurse | 
    Where-Object {$_.LastWriteTime -le (Get-Date).AddDays(-15)} | 
    Remove-Item -Recurse -Force

# Import the DNS Server module
Import-Module DnsServer

# Set the path and create a new folder for the backup
$Path = "\\ServerName\c$\Temp\Daily_DNSReports_Backup\Forward_Lookup_Zone_" + (Get-Date).ToString("dd-MM-yyyy")
New-Item -Path $Path -ItemType Directory -Force

# Define the DNS server
$DNSServer = $env:COMPUTERNAME

# Export DNS records from Forward Lookup Zones
$Zones = Get-DnsServerZone -ComputerName $DNSServer | 
    Where-Object { $_.IsReverseLookupZone -eq $False -and $_.ZoneType -eq "Primary" }

foreach ($Zone in $Zones) {
    $ZoneName = $Zone.ZoneName
    $Results = Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DNSServer | 
        Select-Object @{Name = 'ZoneName'; Expression = { $ZoneName }}, 
                      HostName, 
                      RecordType, 
                      @{Name = 'RecordData'; Expression = {
                          switch ($_.RecordType) {
                              'A'     { $_.RecordData.IPv4Address.IPAddressToString }
                              'AAAA'  { $_.RecordData.IPv6Address.IPAddressToString }
                              'CNAME' { $_.RecordData.HostNameAlias }
                              'NS'    { $_.RecordData.NameServer }
                              'SOA'   { 'SOA Record' }
                              'SRV'   { 'SRV Record' }
                              'TXT'   { 'TXT Record' }
                              Default { $_.RecordData.NameServer.ToUpper() }
                          }
                      }}

    # Save the exported data to a CSV file in the backup folder
    Set-Location -Path $Path -PassThru
    $Results | Export-Csv -Path "$Path\$ZoneName.csv" -NoTypeInformation
}

# End of Script