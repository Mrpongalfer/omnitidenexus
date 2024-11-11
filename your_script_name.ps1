#!/bin/bash

# Detect if the script is running in Bash or PowerShell (Windows)
if [[ "$SHELL" == *"bash"* ]]; then
    platform="bash"
else
    platform="powershell"
fi

# Define common functions for error logging
log_error() {
    local errorMessage="$1"
    echo "Error occurred: $errorMessage" | tee -a "/tmp/omnitide_error_log.txt"  
    # Sherlock Holmes will analyze the log for root cause detection
    echo "Sherlock is investigating the error..."
}

# Function to call core team members for specific tasks
call_core_team() {
    local task="$1"
    echo "Calling core team for task: $task"

    case $task in
        "optimize")
            echo "Tony Stark is optimizing the system architecture for resource utilization."
            echo "Power from the core team will boost quantum and fractal computations."
            ;;
        "security")
            echo "Rick Sanchez and Yoda are working together to fortify the deepest core layers with chaotic but unbreakable security layers."
            echo "Chainsaw Man is shredding through potential external threats."
            ;;
        "deployment")
            echo "Mr. Meeseeks is handling rapid deployment, and will spawn tasks across all necessary platforms."
            ;;
        "debug")
            echo "Sherlock Holmes is analyzing the error logs and tracing the origin of any issues."
            ;;
        "user_interface")
            echo "Harley Quinn and Rocket Raccoon are making the user experience fun, streamlined, and customizable."
            ;;
        "adaptive_AI")
            echo "Rick and Tony Stark are fine-tuning the proactive and predictive AI to adapt to unforeseen conditions."
            ;;
        "deep_learning")
            echo "Yoda and Power are overseeing the AI learning algorithms, ensuring the system learns and evolves autonomously."
            ;;
        *)
            echo "No specific task assigned."
            ;;
    esac
}

# Define the script for PowerShell
run_powershell() {
    echo "Detected platform: PowerShell"
    
    powershell_script="param(
        [string]`$githubRepoUrl = 'https://github.com/Mrpongalfer/omnitidenexus.git',
        [string]`$githubToken = ''
    )
    
    try {
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] 'Administrator')) {
            throw 'You need to run this script as an Administrator!'
        }

        Write-Host 'Starting the setup...'
        Set-ExecutionPolicy Bypass -Scope Process -Force

        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Host 'Installing Chocolatey...'
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        } else {
            Write-Host 'Chocolatey already installed.'
        }

        # Install Docker
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            Write-Host 'Installing Docker...'
            choco install docker-desktop -y
        } else {
            Write-Host 'Docker already installed.'
        }
        
        # Cloning the GitHub repo
        Write-Host 'Cloning GitHub repository...'
        git clone \$githubRepoUrl
        Write-Host 'Deployment initiated.'

        # Call the core team to handle deployment
        Invoke-Expression 'call_core_team deployment'
    }
    catch {
        Write-Host 'Error: $errorMessage'
    }
    finally {
        Write-Host 'Cleanup initiated.'
    }"

    powershell -Command "$powershell_script"
}

# Define the script for Bash
run_bash() {
    echo "Detected platform: Bash"
    
    if [[ "$EUID" -ne 0 ]]; then
      echo "Please run as root"
      exit 1
    fi
    
    echo "Starting Bash setup..."
    
    # Install Docker if not installed
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt-get update
        sudo apt-get install -y docker.io
    fi
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker-Compose..."
        sudo apt-get install -y docker-compose
    fi

    # Clone GitHub repository and set up the environment
    if [ ! -d "omnitidenexus" ]; then
        echo "Cloning Omnitide Nexus repository..."
        git clone https://github.com/Mrpongalfer/omnitidenexus.git
    else
        echo "Updating Omnitide Nexus repository..."
        cd omnitidenexus && git pull origin main && cd ..
    fi

    # Build and start Docker containers
    cd omnitidenexus
    docker-compose down
    docker-compose up --build -d

    # Call the core team to handle deployment
    call_core_team "deployment"
}

# Platform Detection and Execution
if [[ "$platform" == "bash" ]]; then
    run_bash
else
    run_powershell
fi
