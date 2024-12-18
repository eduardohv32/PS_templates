# Define the domain name and output file
$DomainName = Read-Host "Enter the domain name to query"
$OutputFile = "$DomainName-DNS-Records.txt"

# List of DNS record types to query
$RecordTypes = @("A", "AAAA", "TXT", "MX", "CNAME")

# Create or clear the output file
Clear-Content -Path $OutputFile -ErrorAction SilentlyContinue
Add-Content -Path $OutputFile -Value "DNS Records for domain: $DomainName"
Add-Content -Path $OutputFile -Value "-------------------------------------------"

# Loop through each record type
foreach ($RecordType in $RecordTypes) {
    Add-Content -Path $OutputFile -Value "`n$RecordType Records:"
    try {
        # Query the DNS records
        $Records = Resolve-DnsName -Name $DomainName -Type $RecordType -ErrorAction Stop

        # Format and write records to the file
        foreach ($Record in $Records) {
            Add-Content -Path $OutputFile -Value ($Record | Format-List | Out-String)
        }
    } catch {
        # Handle errors for record types not found
        Add-Content -Path $OutputFile -Value "No $RecordType records found."
    }
}

# Notify user of completion
Write-Host "DNS records have been saved to $OutputFile"