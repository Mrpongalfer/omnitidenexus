# PowerShell Script: Fully Automated Docker Setup, Container Management, and GitHub Auto-Update
# Ensure execution in PowerShell with admin privileges.

# Define the working directory
$WorkingDir = "C:\Windows\System32\omnitidenexus"
Set-Location -Path $WorkingDir

# Remove existing event subscribers to avoid duplicates
Get-EventSubscriber -SourceIdentifier "ContainerMonitor" | Unregister-Event -Force -ErrorAction SilentlyContinue
Get-EventSubscriber -SourceIdentifier "UpdateCheck" | Unregister-Event -Force -ErrorAction SilentlyContinue

# Function to Install Docker if Not Present
function Install-Docker {
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "Docker is not installed. Installing Docker Desktop..."
        
        # Download Docker Desktop Installer
        $DockerInstallerUrl = "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
        $InstallerPath = "$env:TEMP\DockerDesktopInstaller.exe"
        
        Invoke-WebRequest -Uri $DockerInstallerUrl -OutFile $InstallerPath
        Start-Process -FilePath $InstallerPath -ArgumentList "/install" -NoNewWindow -Wait
        Write-Host "Docker Desktop installed. Please restart your computer for the changes to take effect."
        exit
    }
}

# Function to Ensure Docker Service is Running
function Ensure-DockerServiceRunning {
    if ((Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue).Status -ne 'Running') {
        Start-Service -Name "com.docker.service"
        Write-Host "Docker service started."
    }
}

# Function to Build Docker Image if Not Present
function Build-DockerImage {
    if (!(docker images omnitidenexus_image --format "{{.Repository}}" -ErrorAction SilentlyContinue)) {
        if (Test-Path "$WorkingDir\Dockerfile") {
            Write-Host "Dockerfile detected. Building image 'omnitidenexus_image'..."
            docker build -t omnitidenexus_image "$WorkingDir" | Write-Host
            Write-Host "Docker image 'omnitidenexus_image' built successfully."
        } else {
            Write-Host "No Dockerfile found. Creating a default Dockerfile..."
            $DockerfileContent = @"
# Default Dockerfile
FROM mcr.microsoft.com/powershell:lts-alpine-3.13
WORKDIR /app
COPY . /app
ENTRYPOINT ["pwsh", "-NoExit"]
"@
            $DockerfileContent | Set-Content -Path "$WorkingDir\Dockerfile" -Force
            Write-Host "Dockerfile created. Building Docker image..."
            docker build -t omnitidenexus_image "$WorkingDir" | Write-Host
            Write-Host "Docker image 'omnitidenexus_image' built successfully."
        }
    }
}

# Function to Manage Docker Container
function Manage-DockerContainer {
    param (
        [string]$ImageName = "omnitidenexus_image",
        [string]$ContainerName = "omnitidenexus_container"
    )

    # Check if the container exists
    $ContainerExists = docker ps -a --format "{{.Names}}" | Select-String -Pattern "^$ContainerName$"

    if ($ContainerExists) {
        # Start the container if it's stopped
        $ContainerStatus = docker inspect -f "{{.State.Status}}" $ContainerName
        if ($ContainerStatus -ne "running") {
            Write-Host "Starting existing container $ContainerName..."
            docker start $ContainerName
        } else {
            Write-Host "Container $ContainerName is already running."
        }
    } else {
        # Create and start a new container
        Write-Host "Creating and starting new container $ContainerName..."
        docker run -d --name $ContainerName $ImageName
    }
}

# Function to Monitor and Auto-Restart Container
function Monitor-Container {
    Register-ObjectEvent -InputObject ([System.Timers.Timer]::new(30000)) -EventName Elapsed -SourceIdentifier "ContainerMonitor" -Action {
        $ContainerName = "omnitidenexus_container"
        $Status = docker inspect -f "{{.State.Status}}" $ContainerName 2>$null
        
        if ($Status -ne "running") {
            Write-Host "Container $ContainerName is not running. Restarting..."
            docker start $ContainerName
        }
    } | Out-Null
}

# Self-update function to update script from GitHub repository
function Update-Script {
    Write-Host "Checking for script updates..."
    $LatestScriptUrl = "https://raw.githubusercontent.com/Mrpongalfer/omnitidenexus/main/omnitidenexus.ps1"

    try {
        $ScriptContent = Invoke-WebRequest -Uri $LatestScriptUrl -UseBasicParsing -ErrorAction Stop
        if ($ScriptContent.StatusCode -eq 200) {
            Write-Host "Updating script from GitHub repository..."
            $ScriptContent.Content | Set-Content -Path "$WorkingDir\omnitidenexus.ps1" -Force
            Write-Host "Script updated. Reloading..."
            . "$WorkingDir\omnitidenexus.ps1"  # Reload script
        } else {
            Write-Host "No updates found or unable to access repository."
        }
    } catch {
        Write-Host "Error accessing GitHub repository for updates. Please check connectivity or URL."
    }
}

# Function to Schedule Daily Update Checks
function Schedule-UpdateCheck {
    Register-ObjectEvent -InputObject ([System.Timers.Timer]::new(86400000)) -EventName Elapsed -SourceIdentifier "UpdateCheck" -Action { Update-Script } | Out-Null
}

# Execution Workflow
Write-Host "Initializing Docker container management script..."

Install-Docker              # Ensure Docker is installed
Ensure-DockerServiceRunning # Ensure Docker service is running
Build-DockerImage           # Build Docker image if it does not exist
Manage-DockerContainer      # Create or start the Docker container
Monitor-Container           # Monitor the container and auto-restart if necessary
Update-Script               # Run initial script update check
Schedule-UpdateCheck        # Schedule daily update check

Write-Host "Script execution complete. Docker container management active."
