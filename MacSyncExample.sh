#!/bin/bash
# Function to handle the script exit gracefully
trap 'echo "Process interrupted. Exiting..."; exit 0' INT

# Configuration:
# Search & Replace username and remotehostname with your real username and remotehostname
# Requires you to pre-authenticate your access to the remotehostname using ssh to setup your stored ssh key
# Edit your list of folders to "sync" in the folder list below:

REMOTE_USER="username"
REMOTE_HOST="remotehostname"
LOG_FILE="/Applications/SyncLogs/sync_log_$(date +%Y%m%d%H%M%S).txt"
FOLDER_LIST=(
	"/Users/username/Album Artwork"
	"/Users/username/Desktop/"
	"/Users/username/Documents"
	"/Users/username/Downloads/"
	"/Users/username/Dropbox"
	"/Users/username/Gloria Read Books/"
	"/Users/username/Movies/"
	"/Users/username/Music"		
	"/Users/username/Music Purchases/"
	"/Users/username/Pictures/"
	"/Users/username/Public"
	"/Users/username/Sites"
	"/Users/username/Spanish Music"
	"/Users/username/VirtualBox/"
	"/Users/username/VirtualBox VMs/"
	)

# Ensure the log file is clean before starting
echo "Starting bi-directional sync at $(date)" 2>&1 | tee -a "$LOG_FILE"

# Function to run rsync with logging and exclusions
run_rsync() {
    local source="$1"
    local destination="$2"
    local direction="$3"
    
    # Decide whether to include --delete
    if [ "$direction" == "local -> remote" ]; then
        DELETE_FLAG="--delete"
    else
        DELETE_FLAG=""
    fi
        
    # Log the start of the sync process
    echo "Syncing $direction for directory: $source" 2>&1 | tee -a "$LOG_FILE"
    
    # Run rsync
    rsync -aud \
    	$DELETE_FLAG \
		--no-links \
		--itemize-changes \
		--exclude="._*" \
		--exclude="*.alias" \
		--exclude=".AppleDesktop" \
		--exclude=".AppleDouble" \
		--exclude=".DS_Store" \
		--exclude=".fseventsd" \
		--exclude=".Spotlight-V100" \
		--exclude=".symlink" \
		--exclude=".TemporaryItems" \
		--exclude=".Trashes" \
		--exclude="*.cache" \
		--exclude="*.log" \
		--exclude="*.musiclibrary" \
		--exclude="*.photoslibrary" \
		--exclude=".stfolder" \
		--exclude=".stignore" \
		--exclude="*.swp" \
		--exclude="*.temp" \
		--exclude="*.tmp" \
		--exclude="*/.*" \
		--exclude="*/**/*.alias" \
		--exclude="node_modules" \
		"$source/" "$destination/" 2>&1 | tee -a "$LOG_FILE"
		
		if [ $? -eq 0 ]; then
			echo "Rsync succeeded." 2>&1 | tee -a "$LOG_FILE"
		else
			echo "Rsync failed." 2>&1 | tee -a "$LOG_FILE"
		fi	
}
# Main Sync Process
# Read each directory from the list file and run rsync

for top_level_dir in "${FOLDER_LIST[@]}"; do

    # Trim leading/trailing spaces and print for debugging
    #top_level_dir=$(echo "$top_level_dir" | xargs)
    
    # Debugging: Print the directory being processed

    # Check if the directory exists
    if [ -d "$top_level_dir" ]; then
        echo "Directory '$top_level_dir' exists. Starting sync." 2>&1 | tee -a "$LOG_FILE"
        
        # Sync from local to remote
        run_rsync "$top_level_dir" "$REMOTE_USER@$REMOTE_HOST:$top_level_dir" "local -> remote"

        # Sync from remote to local
        run_rsync "$REMOTE_USER@$REMOTE_HOST:$top_level_dir" "$top_level_dir" "remote -> local"
    else
        echo "Directory '$top_level_dir' does not exist locally. Skipping." 2>&1 | tee -a "$LOG_FILE"
    fi
done

echo "Bi-directional sync completed at $(date)." 2>&1 | tee -a "$LOG_FILE"
