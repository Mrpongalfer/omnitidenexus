# Define the paths
$ZipPath = "C:\Users\DrMrNicePenis\omnitidenexus\omnitidenexus-main (1).zip"
$WorkingDir = "C:\Users\DrMrNicePenis\omnitidenexus\extracted"
$ImageName = "omnitidenexus_image"
$ContainerName = "omnitidenexus_container"

# Remove any existing event subscribers to avoid duplicates
Get-EventSubscriber -SourceIdentifier "ContainerMonitor" | Unregister-Event -Force -ErrorAction SilentlyContinue
Get-EventSubscriber -SourceIdentifier "UpdateCheck" | Unregister-Event -Force -ErrorAction SilentlyContinue

# Unzip the contents if not already extracted
if (!(Test-Path $WorkingDir)) {
    Write-Host "Extracting files from the zip archive..."
    Expand-Archive -Path $ZipPath -DestinationPath $WorkingDir -Force
}

# Set the working directory to the extracted folder
Set-Location -Path $WorkingDir

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
    if (!(docker images $ImageName --format "{{.Repository}}" -ErrorAction SilentlyContinue)) {
        if (Test-Path "$WorkingDir\Dockerfile") {
            Write-Host "Dockerfile detected. Building image '$ImageName'..."
            docker build -t $ImageName "$WorkingDir" | Write-Host
            Write-Host "Docker image '$ImageName' built successfully."
        } else {
            Write-Host "No Dockerfile found in the extracted folder. Ensure the Dockerfile exists to proceed."
            exit
        }
    }
}

# Function to Manage Docker Container
function Manage-DockerContainer {
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
