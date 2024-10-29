# OmniTide Nexus Full Deployment Script
# This script handles the full integration and deployment of the OmniTide Nexus ecosystem.
# Ensure the script runs with administrator privileges.

If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Please run this script as Administrator."
    Exit
}

# Step 1: Update and install necessary tools
Write-Host "Installing necessary tools..."

# Update PowerShell modules
Install-Module -Name PowerShellGet -Force -AllowClobber
Update-Module -Name PowerShellGet
Update-Help

# Install necessary packages for networking, monitoring, and script execution
Write-Host "Installing required packages..."
Install-Package -Name git, curl, wget, nmap -Force

# Step 2: Clone or update OmniTide Nexus repository
$repoDir = "$env:USERPROFILE\omnitidenexus"

If (-Not (Test-Path $repoDir)) {
    Write-Host "Cloning OmniTide Nexus repository..."
    git clone https://github.com/Mrpongalfer/omnitidenexus.git $repoDir
} Else {
    Write-Host "Repository already exists, updating..."
    Set-Location $repoDir
    git pull
}

# Step 3: Make scripts executable (for Unix-like systems)
Write-Host "Making scripts executable..."
chmod +x *.sh

# Step 4: Execute core team deployment and configure the ecosystem
Write-Host "Setting up the core team and ecosystem..."
cd $repoDir
.\deploy_pppowerpong.ps1
.\sync_nexus.ps1

# Step 5: Enable advanced features
Write-Host "Enabling advanced system features..."

# Enabling aggressive evolution and autonomous system upgrades
.\omniverse_evolution_futureproof.ps1

# Deploy Mr. Meeseeks for hostile detection and sandboxing
Write-Host "Deploying Mr. Meeseeks for hostile detection..."
.\mr-meeseeks.ps1

# Step 6: Network monitoring and external-world interfacing
Write-Host "Setting up network monitoring and interfacing with external systems..."

# Run network scans and log results
nmap -sP 192.168.0.0/24 | Out-File -FilePath "$repoDir\network_scan_results.txt"
Write-Host "Network scan completed. Results saved to network_scan_results.txt."

# Step 7: Finalizing and deploying the system
Write-Host "Finalizing system setup and deploying everything..."
.\finalize.ps1

# Step 8: Autonomous backup system
Write-Host "Setting up autonomous backup and logging system..."
.\backup.ps1

# Enable kernel privileges
Write-Host "Enabling kernel privileges..."
.\enable_kernel_privileges.ps1

# Step 9: Visual dashboard setup for system monitoring
Write-Host "Setting up visual monitoring dashboard..."
.\setup_dashboard.ps1

Write-Host "OmniTide Nexus ecosystem fully deployed and operational!"
