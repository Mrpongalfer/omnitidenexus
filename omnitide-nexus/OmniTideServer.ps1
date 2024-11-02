# Step 1: Check for and Install Docker
Write-Output "Checking for Docker installation..."
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Output "Docker not found. Installing Docker..."
    Invoke-WebRequest -Uri "https://desktop.docker.com/win/stable/Docker Desktop Installer.exe" -OutFile "DockerInstaller.exe"
    Start-Process -FilePath ".\DockerInstaller.exe" -ArgumentList "/quiet /install" -Wait
    Remove-Item -Force ".\DockerInstaller.exe"
    Write-Output "Docker installed. Please restart your system if prompted, then re-run this script."
    Exit
} else {
    Write-Output "Docker is already installed."
}

# Step 2: Check for Docker Compose Installation
Write-Output "Checking for Docker Compose..."
if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Docker Compose..."
    Invoke-WebRequest -Uri "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Windows-x86_64.exe" -OutFile "$Env:ProgramFiles\Docker\docker-compose.exe"
    [Environment]::SetEnvironmentVariable("Path", $Env:Path + ";$Env:ProgramFiles\Docker", [System.EnvironmentVariableTarget]::Machine)
    Write-Output "Docker Compose installed."
} else {
    Write-Output "Docker Compose is already installed."
}

# Step 3: Set Up Project Directory Structure
Write-Output "Setting up project directory structure..."
$projectDir = "$PSScriptRoot\omnitide_server"
$h5aiDir = "$projectDir\h5ai"
$mediaDir = "$projectDir\media"

# Create necessary directories
New-Item -ItemType Directory -Path $projectDir -Force
New-Item -ItemType Directory -Path $h5aiDir -Force
New-Item -ItemType Directory -Path $mediaDir -Force

# Step 4: Download H5AI for File Browsing Interface
Write-Output "Downloading H5AI for file browsing interface..."
Invoke-WebRequest -Uri "https://release.larsjung.de/h5ai/h5ai-0.29.0.zip" -OutFile "$h5aiDir\h5ai.zip"
Expand-Archive -Path "$h5aiDir\h5ai.zip" -DestinationPath $h5aiDir -Force
Remove-Item -Force "$h5aiDir\h5ai.zip"

# Step 5: Create NGINX Configuration File
Write-Output "Creating NGINX configuration file..."
$nginxConfig = @"
worker_processes 1;
events { worker_connections 1024; }

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80;

        # Root directory for H5AI browsing
        location / {
            root /usr/share/nginx/html;
            index index.php index.html;
        }

        # PHP-FPM setup for H5AI
        location ~ \.php$ {
            root /usr/share/nginx/html;
            fastcgi_pass omnitide_php:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }

        # Adminer database management on /adminer path
        location /adminer {
            proxy_pass http://omnitide_adminer:8080;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
"@
Set-Content -Path "$projectDir\nginx.conf" -Value $nginxConfig

# Step 6: Create Docker Compose File
Write-Output "Creating Docker Compose file..."
$dockerComposeContent = @"
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: omnitide_nginx
    ports:
      - "80:80"   # Accessible on all devices on your network via port 80
    volumes:
      - ./h5ai:/usr/share/nginx/html/_h5ai  # H5AI directory listing
      - ./media:/usr/share/nginx/html/media # Media files directory
      - ./nginx.conf:/etc/nginx/nginx.conf:ro # Custom NGINX configuration
    networks:
      - omnitide_network

  php-fpm:
    image: php:7.4-fpm-alpine
    container_name: omnitide_php
    volumes:
      - ./h5ai:/usr/share/nginx/html/_h5ai
      - ./media:/usr/share/nginx/html/media
    networks:
      - omnitide_network

  adminer:
    image: adminer:latest
    container_name: omnitide_adminer
    ports:
      - "8080:8080"  # Access Adminer via http://<server-ip>:8080 for database management
    networks:
      - omnitide_network

networks:
  omnitide_network:
    driver: bridge
"@
Set-Content -Path "$projectDir\docker-compose.yml" -Value $dockerComposeContent

# Step 7: Start Docker Compose
Write-Output "Starting OmniTide Server with Docker Compose..."
Set-Location -Path $projectDir
docker-compose up -d

# Step 8: Fetch Local IP Address for Easy Access
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "Ethernet*" -or $_.InterfaceAlias -like "Wi-Fi*" }).IPAddress

Write-Output "OmniTide Server is now running."
Write-Output "Access the following URLs on your local network:"
Write-Output "  - H5AI File Browser: http://$localIP/"
Write-Output "  - Adminer Database GUI: http://$localIP:8080/adminer"
