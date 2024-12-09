# Temporarily disable the execution policy
$originalExecutionPolicy = Get-ExecutionPolicy
Set-ExecutionPolicy Bypass -Scope Process -Force

# Function to rename the machine
function Rename-Machine {
    param (
        [string]$newName
    )

    # Rename the computer
    Rename-Computer -NewName $newName -Force
    Write-Host "Machine renamed to $newName."
}

# Function to join the machine to a domain
function Join-Domain {
    param (
        [string]$domainName,
        [PSCredential]$credential
    )

    # Join the domain
    Add-Computer -DomainName $domainName -Credential $credential -Force
    Write-Host "Machine joined to domain $domainName."
}

# Function to check and install Windows updates
function Check-WindowsUpdates {
    Write-Host "Checking for Windows updates..."
    Install-Module PSWindowsUpdate -Force -Scope CurrentUser
    Import-Module PSWindowsUpdate
    Get-WindowsUpdate -Install -AcceptAll -AutoReboot
    Write-Host "Windows updates checked and installed."
}

# Function to enable BitLocker on C: drive and save the recovery key
function Enable-BitLocker {
    param (
        [string]$recoveryKeyPath
    )

    # Ensure the target directory exists
    if (-Not (Test-Path $recoveryKeyPath)) {
        New-Item -Path $recoveryKeyPath -ItemType Directory -Force
    }

    # Enable BitLocker on C: drive
    $bitLockerStatus = Get-BitLockerVolume -MountPoint "C:"
    if ($bitLockerStatus.ProtectionStatus -eq "Off") {
        Enable-BitLocker -MountPoint "C:" -RecoveryPasswordProtector -EncryptionMethod XtsAes256 -UsedSpaceOnly

        # Get the BitLocker recovery key and save it to a file
        $bitLockerInfo = Get-BitLockerVolume -MountPoint "C:"
        $recoveryKey = $bitLockerInfo.KeyProtector | Where-Object {$_.KeyProtectorType -eq "RecoveryPassword"} | Select-Object -ExpandProperty RecoveryPassword
        $recoveryKeyFile = "$recoveryKeyPath\BitLockerRecoveryKey.txt"
        $recoveryKey | Out-File -FilePath $recoveryKeyFile

        Write-Host "BitLocker enabled on C: drive and recovery key saved to $recoveryKeyFile."
    } else {
        Write-Host "BitLocker is already enabled on C: drive."
    }
}

# Function to install an MSI application
function Install-MSIApplication {
    param (
        [string]$msiPath,
        [string]$msiArgs
    )

    Write-Host "Installing application from $msiPath..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" $msiArgs" -Wait -NoNewWindow
    Write-Host "MSI application installation complete."
}

# Prompt for the new machine name
$newName = Read-Host "Enter the new machine name"

# Rename the machine
Rename-Machine -newName $newName

# Prompt for domain join details
$domainName = Read-Host "Enter the domain name to join"
$domainCred = Get-Credential -Message "Enter domain credentials (in DOMAIN\user format)"

# Join the machine to the domain
Join-Domain -domainName $domainName -credential $domainCred

# Check for Windows updates
Check-WindowsUpdates

# Enable BitLocker on C: drive and save the recovery key
$recoveryKeyPath = "C:\Ubiquity"
Enable-BitLocker -recoveryKeyPath $recoveryKeyPath

# Install an MSI application
$msiPath = ".\MyAppInstaller.msi"  # Path to the MSI file in the same directory as the script
$msiArgs = "/quiet"                # Arguments for silent installation
Install-MSIApplication -msiPath $msiPath -msiArgs $msiArgs

# Prompt to restart the machine
$restart = Read-Host "Do you want to restart the machine now? (Y/N)"
if ($restart -eq "Y") {
    Restart-Computer -Force
} else {
    Write-Host "Restart the machine manually later to complete the process."
}

# Restore the original execution policy
Set-ExecutionPolicy $originalExecutionPolicy -Force
