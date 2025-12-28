# BVI Park & Ride - Hourly Auto-Commit Script (PowerShell)
#
# This script automatically commits changes to git every hour.
#
# SETUP (Windows Task Scheduler):
# 1. Open Task Scheduler (taskschd.msc)
# 2. Create Basic Task > Name: "BVI Park & Ride Hourly Commit"
# 3. Trigger: Daily, repeat every 1 hour
# 4. Action: Start a program
#    - Program: powershell.exe
#    - Arguments: -ExecutionPolicy Bypass -File "C:\Users\Deze_Tingz\AndroidStudioProjects\BVI_Park_and_Ride\scripts\hourly_commit.ps1"
# 5. Finish

$ErrorActionPreference = "Stop"

# Configuration
$projectPath = "C:\Users\Deze_Tingz\AndroidStudioProjects\BVI_Park_and_Ride"
$logFile = Join-Path $projectPath "scripts\commit_log.txt"

# Function to log messages
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

try {
    # Navigate to project directory
    Set-Location $projectPath
    Write-Log "Starting hourly commit check..."

    # Check if we're in a git repository
    if (-not (Test-Path ".git")) {
        Write-Log "ERROR: Not a git repository. Exiting."
        exit 1
    }

    # Stage all changes
    git add -A

    # Check for changes
    $status = git status --porcelain

    if ($status) {
        # There are changes to commit
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
        $commitMessage = "Auto-commit: $timestamp"

        # Create the commit
        git commit -m $commitMessage

        Write-Log "SUCCESS: Changes committed with message: $commitMessage"

        # Count files changed
        $fileCount = ($status -split "`n").Count
        Write-Log "Files affected: $fileCount"
    } else {
        Write-Log "No changes to commit."
    }

} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}

Write-Log "Hourly commit check complete."
