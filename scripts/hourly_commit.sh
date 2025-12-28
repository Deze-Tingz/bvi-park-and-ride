#!/bin/bash
# BVI Park & Ride - Hourly Auto-Commit Script (Unix/Linux/macOS)
#
# This script automatically commits changes to git every hour.
#
# SETUP (cron):
# 1. Open crontab: crontab -e
# 2. Add: 0 * * * * /path/to/BVI_Park_and_Ride/scripts/hourly_commit.sh
# 3. Save and exit
#
# Make executable: chmod +x hourly_commit.sh

set -e

# Configuration
PROJECT_PATH="/path/to/BVI_Park_and_Ride"
LOG_FILE="$PROJECT_PATH/scripts/commit_log.txt"

# Function to log messages
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Navigate to project directory
cd "$PROJECT_PATH" || {
    log "ERROR: Could not navigate to $PROJECT_PATH"
    exit 1
}

log "Starting hourly commit check..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    log "ERROR: Not a git repository. Exiting."
    exit 1
fi

# Stage all changes
git add -A

# Check for changes
if [ -n "$(git status --porcelain)" ]; then
    # There are changes to commit
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
    COMMIT_MESSAGE="Auto-commit: $TIMESTAMP"

    # Create the commit
    git commit -m "$COMMIT_MESSAGE"

    log "SUCCESS: Changes committed with message: $COMMIT_MESSAGE"

    # Count files changed
    FILE_COUNT=$(git status --porcelain | wc -l)
    log "Files affected: $FILE_COUNT"
else
    log "No changes to commit."
fi

log "Hourly commit check complete."
