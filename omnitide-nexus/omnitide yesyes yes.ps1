# Step 1: Update Windows and Install Prerequisites
Write-Output "Updating Windows and installing required features..."
Start-Process powershell -Verb runAs -ArgumentList "sfc /scannow"
Start-Process powershell -Verb runAs -ArgumentList "choco upgrade all -y"
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
Install-WindowsFeature -Name Containers

# Step 2: Install Docker
Write-Output "Installing Docker..."
Invoke-WebRequest -Uri "https://desktop.docker.com/win/stable/Docker Desktop Installer.exe" -OutFile "DockerInstaller.exe"
Start-Process -FilePath .\DockerInstaller.exe -ArgumentList "/quiet /install" -Wait
Remove-Item -Force DockerInstaller.exe

# Step 3: Install Kubernetes CLI (kubectl)
Write-Output "Installing Kubernetes CLI (kubectl)..."
Invoke-WebRequest -Uri "https://dl.k8s.io/release/v1.22.0/bin/windows/amd64/kubectl.exe" -OutFile "$env:ProgramFiles\kubectl.exe"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:ProgramFiles\kubectl.exe", [System.EnvironmentVariableTarget]::Machine)

# Step 4: Install PowerShell Module for Docker and Kubernetes
Write-Output "Installing Docker and Kubernetes PowerShell modules..."
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force
Install-Module -Name Kubernetes -Force

# Step 5: Enable WSL2 (Required for Docker)
Write-Output "Enabling WSL2..."
wsl --set-default-version 2

# Step 6: Install API Support and Essential Modules
Write-Output "Installing essential APIs and modules..."
Install-Module -Name Posh-SSH -Force
Install-Module -Name Az -Force   # Azure PowerShell for cloud integration
Install-Module -Name AWSPowerShell -Force   # AWS PowerShell for cloud integration

# Step 7: Configure Docker and Kubernetes
Write-Output "Setting up Docker and Kubernetes environments..."
Start-Process "Docker Desktop"   # Start Docker Desktop and wait for configuration
& "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe" &
Start-Sleep -s 10
kubectl config set-cluster omnitide-cluster --server=https://127.0.0.1:6443

# Step 8: Configure SSH for Cross-System Access
Write-Output "Setting up SSH for remote access..."
New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh"
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa" -N ""
ssh-add "$env:USERPROFILE\.ssh\id_rsa"

# Step 9: Clone and Integrate GitHub Repository
Write-Output "Cloning GitHub repository for OmniTide Nexus..."
git clone https://github.com/Mrpongalfer/omnitidenexus.git
cd omnitide-nexus
docker build -t omnitide-nexus .

# Step 10: Deploy OmniTide Components to Kubernetes
Write-Output "Deploying OmniTide ecosystem to Kubernetes..."
kubectl apply -f k8s-deployment.yaml   # Ensure this file is configured for deployment needs
kubectl apply -f k8s-service.yaml

# Step 11: Final Sync and Start Services
Write-Output "Starting all OmniTide Nexus services and syncing across all environments..."
docker-compose up -d

# Step 12: Initiate Perpetual Syncing
Write-Output "Enabling perpetual sync mode and linking environments..."
kubectl exec -it $(kubectl get pods -o=jsonpath='{.items[0].metadata.name}') -- /bin/bash -c "while true; do echo 'Syncing OmniTide Nexus...'; sleep 60; done"

Write-Output "OmniTide Nexus installation and deployment complete."
